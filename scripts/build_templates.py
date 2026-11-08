#!/usr/bin/env python3
"""Compile Native (CMake + Ninja) and Java sources into ``arcaea_patcher/templates``.

Also exports ``native/build/arm64-v8a/compile_commands.json`` for clangd IntelliSense.
"""

from __future__ import annotations

import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT_DIR = Path(__file__).resolve().parent.parent
NATIVE_DIR = ROOT_DIR / "native"
JAVA_DIR = ROOT_DIR / "java" / "src" / "main" / "java"
TEMPLATES_DIR = ROOT_DIR / "arcaea_patcher" / "templates"
LOCAL_LIB_DIR = ROOT_DIR / "lib"
LOCAL_BUILD_TOOLS_DIR = ROOT_DIR / "build-tools"

TARGET_ABIS = ("arm64-v8a", "armeabi-v7a")
MIN_API = 21
JAVA_SOURCE_LEVEL = "8"
BAKSMALI_MAIN_CLASS = "com.android.tools.smali.baksmali.Main"

BAKSMALI_ARTIFACTS = (
    "smali-baksmali",
    "baksmali",
    "smali-dexlib2",
    "smali-util",
    "guava",
    "jcommander",
    "failureaccess",
    "jsr305",
    "listenablefuture",
)


def info(msg: str) -> None:
    print(f"[*] {msg}")


def success(msg: str) -> None:
    print(f"[+] {msg}")


def die(msg: str) -> None:
    print(f"[-] {msg}")
    sys.exit(1)


def version_key(path: Path) -> tuple[int, ...]:
    nums = re.findall(r"\d+", path.name)
    return tuple(int(n) for n in nums) if nums else (0,)


def artifact_version(name: str, prefix: str) -> tuple[int, ...]:
    nums = re.findall(r"\d+", name[len(prefix):])
    return tuple(int(n) for n in nums) if nums else (0,)


def as_command(path: Path) -> list[str]:
    if os.name == "nt" and path.suffix.lower() in (".bat", ".cmd"):
        return ["cmd.exe", "/c", str(path)]
    return [str(path)]


def run(argv: list[str], cwd: Path | None = None, label: str | None = None) -> None:
    display = " ".join(argv)
    if len(display) > 280:
        display = display[:280] + " ..."
    info(f"{label or 'run'}: {display}")
    res = subprocess.run(argv, cwd=str(cwd) if cwd else None)
    if res.returncode != 0:
        die(f"{label or argv[0]} failed with exit code {res.returncode}")


def find_android_sdk() -> Path:
    candidates: list[Path] = []
    for var in ("ANDROID_HOME", "ANDROID_SDK_ROOT"):
        val = os.getenv(var)
        if val:
            candidates.append(Path(val))

    home = Path.home()
    if os.name == "nt":
        local_appdata = os.getenv("LOCALAPPDATA")
        if local_appdata:
            candidates.append(Path(local_appdata) / "Android" / "Sdk")
    elif sys.platform == "darwin":
        candidates.append(home / "Library" / "Android" / "sdk")
    else:
        candidates.append(home / "Android" / "Sdk")
        candidates.append(Path("/usr/lib/android-sdk"))

    for cand in candidates:
        if cand.is_dir():
            info(f"Android SDK : {cand}")
            return cand

    die("Android SDK not found. Set ANDROID_HOME or ANDROID_SDK_ROOT.")
    return Path("")


def find_ndk(sdk: Path) -> Path:
    roots: list[Path] = []
    for var in ("ANDROID_NDK_HOME", "ANDROID_NDK_ROOT"):
        val = os.getenv(var)
        if val:
            roots.append(Path(val))

    ndk_dir = sdk / "ndk"
    if ndk_dir.is_dir():
        roots.extend(sorted((p for p in ndk_dir.iterdir() if p.is_dir()), key=version_key, reverse=True))

    legacy = sdk / "ndk-bundle"
    if legacy.is_dir():
        roots.append(legacy)

    for root in roots:
        toolchain = root / "build" / "cmake" / "android.toolchain.cmake"
        if toolchain.is_file():
            info(f"Android NDK : {root}")
            return root
    
    return Path("")



def find_cmake_and_ninja(sdk: Path) -> tuple[Path, Path]:
    exe_sfx = ".exe" if os.name == "nt" else ""
    cmake_dir = sdk / "cmake"
    if cmake_dir.is_dir():
        for ver_dir in sorted((p for p in cmake_dir.iterdir() if p.is_dir()), key=version_key, reverse=True):
            cmake_bin = ver_dir / "bin" / f"cmake{exe_sfx}"
            ninja_bin = ver_dir / "bin" / f"ninja{exe_sfx}"
            if cmake_bin.is_file() and ninja_bin.is_file():
                info(f"CMake       : {cmake_bin}")
                return cmake_bin, ninja_bin

    cmake_which = shutil.which("cmake")
    ninja_which = shutil.which("ninja")
    if cmake_which and ninja_which:
        return Path(cmake_which), Path(ninja_which)

    die("CMake and Ninja not found in Android SDK or system PATH.")
    return Path(""), Path("")


def find_host_tool(sdk: Path, tool: str) -> Path:
    names = [f"{tool}.exe", f"{tool}.bat", f"{tool}.cmd", tool] if os.name == "nt" else [tool]
    parents: list[Path] = []

    for base in (sdk / "build-tools", LOCAL_BUILD_TOOLS_DIR):
        if base.is_dir():
            parents.extend(sorted((p for p in base.iterdir() if p.is_dir()), key=version_key, reverse=True))
            parents.append(base)

    for parent in parents:
        for name in names:
            cand = parent / name
            if cand.is_file():
                info(f"{tool:<12}: {cand}")
                return cand

    die(f"Could not find '{tool}' in SDK build-tools or '{LOCAL_BUILD_TOOLS_DIR}'.")
    return Path("")


def find_android_jar(sdk: Path) -> Path:
    platforms = sdk / "platforms"
    if platforms.is_dir():
        for plat in sorted((p for p in platforms.iterdir() if p.is_dir()), key=version_key, reverse=True):
            cand = plat / "android.jar"
            if cand.is_file():
                info(f"android.jar : {cand}")
                local_jar = LOCAL_LIB_DIR / "android.jar"
                if not local_jar.exists():
                    try:
                        if hasattr(os, "link"):
                            os.link(cand, local_jar)
                        else:
                            shutil.copyfile(cand, local_jar)
                    except Exception:
                        shutil.copyfile(cand, local_jar)
                return cand

    die("android.jar not found in '<sdk>/platforms'.")
    return Path("")


def find_java_tool(name: str) -> str:
    sfx = ".exe" if os.name == "nt" else ""
    java_home = os.getenv("JAVA_HOME")
    if java_home:
        cand = Path(java_home) / "bin" / f"{name}{sfx}"
        if cand.is_file():
            return str(cand)
    found = shutil.which(name)
    if found:
        return found
    die(f"Could not find '{name}'. Install a JDK or set JAVA_HOME.")
    return ""


def find_baksmali_classpath(sdk: Path) -> list[str]:
    search_roots = (sdk / "cmdline-tools", LOCAL_LIB_DIR)
    candidates: dict[str, list[Path]] = {a: [] for a in BAKSMALI_ARTIFACTS}

    for root in search_roots:
        if not root.is_dir():
            continue
        for jar in root.rglob("*.jar"):
            stem = jar.stem.lower()
            for artifact in BAKSMALI_ARTIFACTS:
                if stem.startswith(artifact):
                    candidates[artifact].append(jar)

    classpath: list[str] = []
    for artifact in BAKSMALI_ARTIFACTS:
        found = candidates[artifact]
        if found:
            newest = max(found, key=lambda j: artifact_version(j.stem.lower(), artifact))
            classpath.append(str(newest))

    if not any(Path(e).stem.lower().startswith(("smali-baksmali", "baksmali")) for e in classpath):
        die("baksmali CLI not found in SDK cmdline-tools or lib/.")

    return classpath


def build_native(cmake: Path, ninja: Path, ndk: Path) -> None:
    toolchain = ndk / "build" / "cmake" / "android.toolchain.cmake"
    lib_template_dir = TEMPLATES_DIR / "lib"
    if lib_template_dir.exists():
        shutil.rmtree(lib_template_dir)

    for abi in TARGET_ABIS:
        build_dir = NATIVE_DIR / "build" / abi
        build_dir.mkdir(parents=True, exist_ok=True)

        cfg_cmd = [
            str(cmake),
            "-S", str(NATIVE_DIR),
            "-B", str(build_dir),
            "-GNinja",
            f"-DCMAKE_MAKE_PROGRAM={ninja}",
            f"-DCMAKE_TOOLCHAIN_FILE={toolchain}",
            f"-DANDROID_ABI={abi}",
            f"-DANDROID_PLATFORM=android-{MIN_API}",
            "-DANDROID_STL=c++_static",
            "-DCMAKE_BUILD_TYPE=Release",
            "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
        ]
        run(cfg_cmd, cwd=NATIVE_DIR, label=f"cmake-configure [{abi}]")
        run([str(cmake), "--build", str(build_dir)], cwd=NATIVE_DIR, label=f"cmake-build [{abi}]")

        built_so = build_dir / "libext.so"
        if not built_so.is_file():
            die(f"CMake did not produce '{built_so}'")

        target_so = lib_template_dir / abi / "libext.so"
        target_so.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(built_so, target_so)
        success(f"{target_so.relative_to(ROOT_DIR)} ({target_so.stat().st_size:,} B)")


def build_java(javac: str, java: str, android_jar: Path, d8: Path, baksmali_cp: list[str]) -> None:
    sources = sorted(JAVA_DIR.rglob("*.java"))
    if not sources:
        die(f"No Java sources found in '{JAVA_DIR}'")

    output_dir = TEMPLATES_DIR / "smali_classes3"
    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    info(f"Compiling {len(sources)} Java source file(s) into Smali...")
    with tempfile.TemporaryDirectory(prefix="ext-bake-") as tmp:
        tmp_dir = Path(tmp)
        classes_dir = tmp_dir / "classes"
        dex_dir = tmp_dir / "dex"
        classes_dir.mkdir()
        dex_dir.mkdir()

        run(
            [javac, "-source", JAVA_SOURCE_LEVEL, "-target", JAVA_SOURCE_LEVEL, "-Xlint:-options",
             "-encoding", "UTF-8", "-classpath", str(android_jar), "-d", str(classes_dir)]
            + [str(s) for s in sources],
            label="javac",
        )

        class_files = sorted(classes_dir.rglob("*.class"))
        run(
            as_command(d8) + ["--min-api", str(MIN_API), "--lib", str(android_jar), "--output", str(dex_dir)]
            + [str(cf) for cf in class_files],
            label="d8",
        )

        dex_file = dex_dir / "classes.dex"
        run(
            [java, "-cp", os.pathsep.join(baksmali_cp), BAKSMALI_MAIN_CLASS, "disassemble",
             "--api", str(MIN_API), "--use-locals", "--output", str(output_dir), str(dex_file)],
            label="baksmali",
        )

    for smali in sorted(output_dir.rglob("*.smali")):
        success(f"{smali.relative_to(ROOT_DIR)} ({smali.stat().st_size:,} B)")


def main() -> None:
    sdk = find_android_sdk()
    ndk = find_ndk(sdk)
    cmake, ninja = find_cmake_and_ninja(sdk)
    d8 = find_host_tool(sdk, "d8")
    android_jar = find_android_jar(sdk)
    javac = find_java_tool("javac")
    java = find_java_tool("java")
    baksmali_cp = find_baksmali_classpath(sdk)

    build_native(cmake, ninja, ndk)
    build_java(javac, java, android_jar, d8, baksmali_cp)

    print()
    success(f"Templates baked into: {TEMPLATES_DIR}")
    success(f"clangd compile_commands.json ready at: {NATIVE_DIR / 'build' / 'arm64-v8a' / 'compile_commands.json'}")


if __name__ == "__main__":
    main()
