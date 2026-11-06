#include "ElfPltHook.h"

#include <cstdint>
#include <cstring>
#include <dlfcn.h>
#include <elf.h>
#include <link.h>

#include "MemoryUtils.h"

#define LOG_MODULE_TAG "ElfPlt"
#include "Logger.h"

namespace Ext::Core {

namespace {

uint8_t *dyn_resolve(void *base, uintptr_t load_bias, ElfW(Addr) v) {
  auto uv = static_cast<uintptr_t>(v);
  auto b = reinterpret_cast<uintptr_t>(base);
  if (uv >= b && uv < b + 256u * 1024u * 1024u)
    return reinterpret_cast<uint8_t *>(uv);
  return reinterpret_cast<uint8_t *>(uv + load_bias);
}

void *pick_original_addr(const char *symbol, void *slot_value, uintptr_t mod_lo,
                         uintptr_t mod_hi) {
  auto cand = reinterpret_cast<uintptr_t>(slot_value);
  if (cand >= mod_lo && cand < mod_hi) {
    void *resolved = dlsym(RTLD_DEFAULT, symbol);
    auto res = reinterpret_cast<uintptr_t>(resolved);
    if (resolved && (res < mod_lo || res >= mod_hi)) {
      LOGW("GOT slot for '%s' at %p unresolved; using dlsym %p", symbol,
           slot_value, resolved);
      return resolved;
    }
  }
  return slot_value;
}

template <typename RelT>
int apply_reloc_table(void *base, uintptr_t bias, void *rel_table,
                      size_t table_sz, const char *want, ElfW(Sym) *sym,
                      const char *str, size_t strsz, void *fn, void **orig,
                      uintptr_t mod_lo, uintptr_t mod_hi) {
  auto *entries = static_cast<RelT *>(rel_table);
  size_t count = table_sz / sizeof(RelT);
  if (count > 100000)
    return -2;

  for (size_t k = 0; k < count; k++) {
#if defined(__LP64__)
    auto sym_idx = static_cast<uint32_t>(ELF64_R_SYM(entries[k].r_info));
#else
    auto sym_idx = static_cast<uint32_t>(ELF32_R_SYM(entries[k].r_info));
#endif
    if (sym[sym_idx].st_name >= strsz)
      continue;
    if (strcmp(str + sym[sym_idx].st_name, want) != 0)
      continue;

    auto **slot = reinterpret_cast<void **>(
        dyn_resolve(base, bias, static_cast<ElfW(Addr)>(entries[k].r_offset)));
    if (!Ext::Utils::make_pages_writable(slot, sizeof(void *)))
      return -1;
    if (orig && *orig == nullptr)
      *orig = pick_original_addr(want, *slot, mod_lo, mod_hi);
    *slot = fn;
    Ext::Utils::flush_instruction_cache(slot, sizeof(void *));
    return 1;
  }
  return 0;
}

} // namespace

int plt_hook_symbol(void *module_base, const char *symbol_name, void *hook_func,
                    void **orig_func) {
  if (!module_base || !symbol_name || !hook_func)
    return -1;

  auto *ehdr = static_cast<ElfW(Ehdr) *>(module_base);
  if (ehdr->e_ident[0] != 0x7f || ehdr->e_ident[1] != 'E' ||
      ehdr->e_ident[2] != 'L' || ehdr->e_ident[3] != 'F')
    return -1;
  if (ehdr->e_phoff == 0 || ehdr->e_phnum == 0 || ehdr->e_phnum > 64)
    return -1;

  auto *phdr = reinterpret_cast<ElfW(Phdr) *>(
      static_cast<uint8_t *>(module_base) + ehdr->e_phoff);
  ElfW(Dyn) *dyn = nullptr;
  uintptr_t min_vaddr = static_cast<uintptr_t>(-1);

  for (int i = 0; i < ehdr->e_phnum; i++) {
    if (phdr[i].p_type == PT_LOAD && phdr[i].p_vaddr < min_vaddr)
      min_vaddr = static_cast<uintptr_t>(phdr[i].p_vaddr);
    if (phdr[i].p_type == PT_DYNAMIC)
      dyn = reinterpret_cast<ElfW(Dyn) *>(static_cast<uint8_t *>(module_base) +
                                          phdr[i].p_vaddr);
  }
  if (min_vaddr == static_cast<uintptr_t>(-1) || !dyn)
    return -1;

  uintptr_t bias = reinterpret_cast<uintptr_t>(module_base) - min_vaddr;
  uintptr_t mod_lo = reinterpret_cast<uintptr_t>(module_base);
  uintptr_t mod_hi = mod_lo;

  for (int i = 0; i < ehdr->e_phnum; i++) {
    if (phdr[i].p_type != PT_LOAD)
      continue;
    uintptr_t seg_lo = static_cast<uintptr_t>(phdr[i].p_vaddr + bias);
    uintptr_t seg_hi = seg_lo + static_cast<uintptr_t>(phdr[i].p_memsz);
    if (seg_lo < mod_lo)
      mod_lo = seg_lo;
    if (seg_hi > mod_hi)
      mod_hi = seg_hi;
  }

  if (reinterpret_cast<uintptr_t>(dyn) <
          reinterpret_cast<uintptr_t>(module_base) ||
      reinterpret_cast<uintptr_t>(dyn) >
          reinterpret_cast<uintptr_t>(module_base) + 256u * 1024u * 1024u) {
    for (int i = 0; i < ehdr->e_phnum; i++) {
      if (phdr[i].p_type == PT_DYNAMIC) {
        dyn = reinterpret_cast<ElfW(Dyn) *>(
            static_cast<uintptr_t>(phdr[i].p_vaddr) + bias);
        break;
      }
    }
  }

  ElfW(Sym) *dynsym = nullptr;
  const char *dynstr = nullptr;
  size_t strsz = 0;
  void *plt_rel = nullptr;
  size_t plt_sz = 0;
  int rel_type = DT_RELA;

  for (ElfW(Dyn) *d = dyn; d->d_tag != DT_NULL; d++) {
    switch (d->d_tag) {
    case DT_SYMTAB:
      dynsym = reinterpret_cast<ElfW(Sym) *>(
          dyn_resolve(module_base, bias, d->d_un.d_ptr));
      break;
    case DT_STRTAB:
      dynstr = reinterpret_cast<const char *>(
          dyn_resolve(module_base, bias, d->d_un.d_ptr));
      break;
    case DT_STRSZ:
      strsz = static_cast<size_t>(d->d_un.d_val);
      break;
    case DT_JMPREL:
      plt_rel = dyn_resolve(module_base, bias, d->d_un.d_ptr);
      break;
    case DT_PLTRELSZ:
      plt_sz = static_cast<size_t>(d->d_un.d_val);
      break;
    case DT_PLTREL:
      rel_type = static_cast<int>(d->d_un.d_val);
      break;
    default:
      break;
    }
  }

  if (!dynsym || !dynstr || !plt_rel || !plt_sz || !strsz)
    return -1;

  int rc = (rel_type == DT_RELA)
               ? apply_reloc_table<ElfW(Rela)>(module_base, bias, plt_rel,
                                               plt_sz, symbol_name, dynsym,
                                               dynstr, strsz, hook_func,
                                               orig_func, mod_lo, mod_hi)
               : apply_reloc_table<ElfW(Rel)>(module_base, bias, plt_rel,
                                              plt_sz, symbol_name, dynsym,
                                              dynstr, strsz, hook_func,
                                              orig_func, mod_lo, mod_hi);

  return (rc == 1) ? 0 : -1;
}

} // namespace Ext::Core
