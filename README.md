# Arcaea Private Server Patcher - v7.1.0c

Python CLI that takes an Arcaea APK, disables SSL certificate/pinning checks (native + Java), redirects API/Auth traffic to your own server at runtime, then rebuilds, aligns and signs the APK.

## What it does

- **SSL bypass (static + runtime)**:
  - **Static ELF patching** — declarative patch specs (`SymbolPatchSpec`) patch `libcocos2dcpp.so` (ARM32/ARM64, Thumb-aware, idempotent) to neutralize exported symbols: `SSL_CTX_set_verify`, `SSL_set_verify`, `SSL_CTX_set_custom_verify`, `SSL_CTX_set_cert_verify_callback`, `X509_verify_cert`, `SSL_set1_host`, `SSL_get_verify_result`, and `X509_check_host`.
  - **Runtime detour & PLT hooks (`libext.so`)** — inline detour hook intercepts `curl_easy_setopt` to suppress `CURLOPT_PINNEDPUBLICKEY` (returns `CURLE_OK`) and force `CURLOPT_SSL_VERIFYPEER` / `CURLOPT_SSL_VERIFYHOST` to `0`. Secondary PLT hooks provide runtime defense-in-depth on OpenSSL/BoringSSL verification calls.
  - **Java Smali hooks** — neutralizes `setVerifySSL` and `verifySSLPins` in `Cocos2dxHttpURLConnection.smali` and `AsyncHttpClient.smali`.
- **Domain & URL redirection (curl inline detour + Java rewriter)**:
  - Injects `assets/domain.cfg` (`original=replacement` rules with port support and `.lowiro.com` wildcards) and merges `moe.ext.arc.**` classes + `libext.so`.
  - **Native inline detour (`curl_easy_setopt`)** — uses multi-architecture runtime pattern scanning (`scan_module_pattern` + `inline_hook` with an executable trampoline) in `libcocos2dcpp.so`. Intercepts `CURLOPT_URL` directly at the curl boundary to rewrite endpoint URLs before dispatch. Features 100% unique 1-hit byte patterns across ARM64 (`LDR X16, #8; BR X16`) and ARM32 (`LDR PC, [PC, #-4]`).
  - **Java URL rewriter** — `DomainUrlRewriter` rewrites URLs for Java-level network calls (e.g. `Cocos2dxHttpURLConnection`).
  - Seamlessly supports SNI routing (reverse proxies, Tailscale Funnel), custom ports, IPv4, and IPv6 with zero URL/domain length restrictions.
- **Network Security Config** — injected via XML ElementTree so the app trusts system + user CAs and allows cleartext (required for MITM / self-signed private servers).
- **Optional features** — package rename (install side-by-side with the original app), Storage Access Framework provider (`moe.ext.arc.InternalStorageProvider` — browse `/data/data/<pkg>` from a file manager, no root).
- **Automated build** — apktool rebuild → `zipalign` → `apksigner`, with automatic tool discovery and direct status logging.

## Requirements

| Dependency | Needed for | Where to get it |
|---|---|---|
| Python 3.9+ with `pip install pyyaml` | patcher | [python.org](https://www.python.org/downloads/) |
| JDK 11/17/21 (`java`, `javac`, `keytool` on PATH) | apktool, signing, `scripts/build_templates.py` | [Eclipse Temurin](https://adoptium.net/temurin/releases) |
| `apktool.jar` | decompile/rebuild | [apktool releases](https://github.com/ibotpeaches/apktool/releases) — rename to `apktool.jar`, drop into `lib/` (or put `apktool` on PATH) |
| Android build-tools (`zipalign`, `apksigner`) | align + sign | [build-tools archives](https://androidsdkmanager.azurewebsites.net/build_tools.html) — see discovery order below |
| Android NDK + CMake + cmdline-tools | **only** `scripts/build_templates.py` | SDK Manager (Android Studio / `sdkmanager`) |

Build-tools are resolved in this order:

1. `build-tools/` in the project root (extracted version folder, e.g. `build-tools/34.0.0/`)
2. `$ANDROID_HOME` / `$ANDROID_SDK_ROOT` → `build-tools/` (newest version wins)
3. OS default SDK locations (`%LOCALAPPDATA%\Android\Sdk`, `~/Android/Sdk`, …)
4. `zipalign` / `apksigner` on system PATH

## Quick start

```bash
pip install pyyaml

# 1. put apktool.jar in lib/
# 2. provide build-tools (folder above or ANDROID_HOME)

# 3. configure your server (or skip and use CLI flags / default SSL-bypass-only mode)
cp config.example.yml config.yml

# 4. patch
python -m arcaea_patcher arcaea_7.1.0c.apk -o patched.apk
```

CLI flags override `config.yml`. `config.yml` / `config.yaml` in the project root is picked up automatically.

```bash
python -m arcaea_patcher input.apk -o patched.apk \
  --api-host arc-api.example.com \
  --auth-host auth.example.com \
  --package-name moe.ext.arc \
  --app-name "Arcaea Ext"
```

The APK is signed with `debug.keystore` (auto-generated on first run) unless you change the `signing:` section. The original signature will not be preserved — uninstall the original app if the package name is unchanged.

## Configuration (`config.yml`)

```yaml
server:
  api_host: "arc-api.example.com:custom_port"      # replaces arcapi-v4/v3.lowiro.com
  auth_host: "custom_domain:8080"                  # replaces auth-v2/auth/arcaea.lowiro.com
  custom_mappings:                                 # optional extra rules, one per entry
    "some.other.host": "192.168.1.10"

package_name: "moe.ext.arc"                        # omit to keep the original package
app_name: "Arcaea Ext"                             # omit to keep the original display name

features:
  expose_internal_data: false                      # SAF provider for internal storage access

signing:
  keystore: "debug.keystore"
  alias: "androiddebugkey"
  keystore_password: "android"
  key_password: "android"
```

If no `server:` host is set, the tool runs in SSL-bypass-only mode (no redirection).

## Pipeline

`python -m arcaea_patcher` executes (`arcaea_patcher/core/engine.py`):

1. **[1/9]** Decompile with apktool
2. **[2/9]** Merge pre-built `templates/` (`libext.so` for ARM64/ARM32 + compiled smali)
3. **[3/9]** Rename package and app label (when configured) — including app-owned permissions & authorities
4. **[4/9]** Inject Network Security Config (`network_security_config.xml`)
5. **[5/9]** Inject Storage Access Framework provider (`moe.ext.arc.InternalStorageProvider`, when enabled)
6. **[6/9]** Write `assets/domain.cfg` + inject `ExtEntry.init()` and `DomainUrlRewriter.rewriteUrl()`
7. **[7/9]** Patch `libcocos2dcpp.so` (declarative ELF symbol patching for OpenSSL/BoringSSL, both ABIs)
8. **[8/9]** Patch Java-level SSL pinning in smali (`Cocos2dxHttpURLConnection`, `AsyncHttpClient`)
9. **[9/9]** Rebuild → `zipalign` → `apksigner`

## On-device behavior

- `ExtEntry` runs in the launcher Activity's `onCreate`. It copies `assets/domain.cfg` to `/data/user/0/<pkg>/files/domain.cfg` **only when missing or malformed**, then loads `libext.so` and triggers native initialization.
- In `libext.so`, `HookManager` watches for `libcocos2dcpp.so`, scans for `curl_easy_setopt` using architecture-specific byte signatures, and hooks it with an executable trampoline.
- Edit `files/domain.cfg` on device to change routing without re-patching (needs `expose_internal_data: true` or root). Delete the file to restore the APK's default.
- Redirect and hook logs appear in logcat under `ArcExt::*` (`ArcExt::Init`, `ArcExt::NetRedirect`, `ArcExt::SslBypass`, `ArcExt::ElfPlt`, `ArcExt::InlineHook`, `ArcExt::PatternScan`, `ArcExt::Config`, `ArcExt::Memory`).

## Rebuilding the injected artifacts (`scripts/build_templates.py`)

`arcaea_patcher/templates/` (`libext.so` for both ABIs + compiled smali) is **committed to the repo**, so you only need this when you modify `native/` or `java/`:

```bash
python scripts/build_templates.py
```

This compiles:
- `native/` via CMake + Ninja (Android NDK) for `arm64-v8a` and `armeabi-v7a`.
- `java/` via `javac` → `d8` → `baksmali` into `smali_classes3/`.
- Also generates `native/build/arm64-v8a/compile_commands.json` configured via `.clangd` for full C++17 / Android NDK IntelliSense.

## Optional: server certificate (`gen_cert.py`)

Generates `server.pem` + `server.key` (RSA-2048, 10 years) with SANs covering the `lowiro.com` domains, `localhost` and any hosts/IPs listed in `config.yml` — for running your private server behind TLS.

```bash
pip install cryptography
python gen_cert.py
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `apktool not found` | Place `apktool.jar` in `lib/` or add `apktool` to PATH |
| `zipalign not found` / `apksigner not found` | Set `ANDROID_HOME`, or put an extracted build-tools folder in `build-tools/`, or install them on PATH |
| `keytool` / Java not found | Install a JDK, ensure `java`/`javac`/`keytool` are on PATH, restart the terminal |
| `No template files found` | `templates/` is missing — restore it from git or run `python scripts/build_templates.py` |
| `Android SDK not found` / `Android NDK not found` | Set `ANDROID_HOME` (or `ANDROID_SDK_ROOT`) and install NDK + CMake via SDK Manager |
| `baksmali CLI not found` | Install SDK cmdline-tools, or drop the baksmali jars into `lib/` |
| Game logs redirect rules but still says "Could not connect" | Delete `/data/user/0/<pkg>/files/domain.cfg` to force re-extraction, then check logcat for `ArcExt::*` errors |
| App connects but TLS still fails | The NSC trusts system + user CAs — install your server's CA/certificate on the device |

## Project structure

```text
├── native/                                  # C++17 NDK shared library (libext.so, CMake)
│   ├── CMakeLists.txt
│   └── src/
│       ├── Main.cpp / HookEntry.cpp         # JNI lifecycle & hook orchestration
│       ├── core/                            # ElfPltHook, HookManager, InlineHook
│       ├── config/                          # DomainRuleTable
│       ├── hooks/                           # NetworkRedirectHook (curl hook & URL rewrite), SslVerifyBypassHook
│       ├── patterns/                        # CurlPattern, PatternDefine
│       └── utils/                           # FileUtils, MemoryUtils, NetStringUtils, PatternScan, Logger
├── java/src/main/java/moe/ext/arc/          # Java sources
│   ├── ExtEntry.java                        # Bootstrap entry & native library loader
│   ├── InternalStorageProvider.java         # Storage Access Framework DocumentsProvider
│   ├── config/                              # DomainConfigLoader, DomainRuleMatcher
│   ├── network/                             # UrlAuthorityParser, DomainUrlRewriter
│   └── utils/FileUtils.java                 # File path resolver utility
├── arcaea_patcher/                          # Python APK Patcher
│   ├── cli.py / config.py                   # CLI & YAML config loader
│   ├── manifest.py                          # Unified XML, package & identity editor
│   ├── resources.py                         # domain.cfg writer & template merger
│   ├── binary/                              # elf.py (parser), patcher.py (engine), specs.py (patch specs)
│   ├── core/                                # engine.py (PatchEngine) & toolchain.py (ApkToolchain)
│   ├── smali/                               # transformer.py (base) & specs.py (bytecode hooks)
│   ├── templates/                           # Pre-built libext.so & smali merged into APK
│   └── utils/logger.py                      # Logging utilities
├── scripts/
│   └── build_templates.py                   # CMake+Ninja & javac+d8+baksmali builder
├── config.example.yml                       # Copy to config.yml
├── gen_cert.py                              # TLS SAN certificate generator
└── README.md
```

## License

[MIT](LICENSE)
