# Arcaea Private Server Patcher

A Python CLI tool to patch the Arcaea Android APK for private servers: disables SSL pinning/verification, redirects API traffic to a custom host, and rebuilds/signs the APK.

## Features

- **SSL Bypass**: Disables SSL/TLS certificate verification and public key pinning in both Native (`libcocos2dcpp.so`, `libcurl`, OpenSSL) and Java layers.
- **Traffic Redirection**: Hooks `curl_easy_setopt` at runtime and rewrites Java HTTP requests to route traffic to your custom domain/IP and port.
- **Network Security Config**: Injects network security config to trust user-installed certificates and allow cleartext HTTP.
- **Package & App Renaming**: Optionally updates package name and display label to allow side-by-side installation with the official game.
- **Storage Access (Optional)**: Injects a Storage Access Framework provider to browse `/data/data/<pkg>` without root.
- **Automated Build**: Automates decompilation, patching, rebuilding, alignment (`zipalign`), and signing (`apksigner`).

## Requirements

| Dependency | Needed for | Where to get it |
|---|---|---|
| Python 3.9+ with `pip install pyyaml` | patcher | [python.org](https://www.python.org/downloads/) |
| JDK 11+ (`java`, `keytool` on PATH) | apktool, signing | [Eclipse Temurin](https://adoptium.net/temurin/releases) |
| `apktool.jar` | decompile/rebuild | [apktool releases](https://github.com/ibotpeaches/apktool/releases) — drop into `lib/` or put on PATH |
| Android build-tools (`zipalign`, `apksigner`) | align + sign | [build-tools archives](https://androidsdkmanager.azurewebsites.net/build_tools.html) or Android SDK |
| Android NDK + CMake | **only** `scripts/build_templates.py` | SDK Manager (Android Studio / `sdkmanager`) |

Build-tools discovery order:
1. `build-tools/` in project root (e.g. `build-tools/34.0.0/`)
2. `$ANDROID_HOME` / `$ANDROID_SDK_ROOT` → `build-tools/`
3. Default OS SDK locations
4. System PATH

## Quick Start

1. Copy the configuration file:
   ```bash
   cp config.example.yml config.yml
   ```
2. Edit `config.yml` with your server hostnames (or specify them via CLI arguments).
3. Run the patcher:
   ```bash
   python -m arcaea_patcher arcaea.apk -o patched.apk
   ```

You can also override settings via CLI flags:
```bash
python -m arcaea_patcher input.apk -o patched.apk \
  --api-host arc-api.example.com \
  --auth-host auth.example.com \
  --package-name moe.ext.arc \
  --app-name "Arcaea Ext"
```

## Configuration (`config.yml`)

```yaml
server:
  api_host: "arc-api.example.com:custom_port"      # replaces arcapi-v4/v3.lowiro.com
  auth_host: "custom_domain:8080"                  # replaces auth-v2/auth/arcaea.lowiro.com
  custom_mappings:                                 # optional additional mappings
    "custom.host": "192.168.1.10"

package_name: "moe.ext.arc"                        # omit to keep original package
app_name: "Arcaea Ext"                             # omit to keep original name

features:
  expose_internal_data: false                      # SAF provider for internal data access

signing:
  keystore: "debug.keystore"
  alias: "androiddebugkey"
  keystore_password: "android"
  key_password: "android"
```

## How It Works

1. **Decompile**: Unpacks APK resources and Smali code using `apktool`.
2. **Inject Template**: Merges helper library (`libext.so`) and bootstrap Smali code.
3. **Identity & Security Config**: Updates package identity (if configured) and injects permissive Network Security Config.
4. **Routing Assets**: Writes `assets/domain.cfg` and hooks Activity lifecycle to initialize `libext.so`.
5. **Static Patching**:
   - Stubs OpenSSL verification functions in `libcocos2dcpp.so`.
   - Neutralizes SSL checks in `Cocos2dxHttpURLConnection` and `AsyncHttpClient`.
   - Injects URL rewrite calls into Java HTTP clients.
6. **Runtime Detour**: `libext.so` locates and inline-hooks `curl_easy_setopt` in `libcocos2dcpp.so` to redirect target URLs and bypass pinned keys.
7. **Build & Sign**: Rebuilds the APK with `apktool`, aligns with `zipalign`, and signs with `apksigner`.

## Development (Rebuilding Templates)

Pre-built templates (`libext.so` and compiled Smali) are committed under `arcaea_patcher/templates/`. If you modify `native/` or `java/`, rebuild them using:

```bash
python scripts/build_templates.py
```

*Requires Android NDK, CMake, and SDK command-line tools.*

## Server Certificate Generator (`gen_cert.py`)

To generate a self-signed TLS certificate (`server.pem` / `server.key`) with SANs covering `lowiro.com` and your configured hosts:

```bash
pip install cryptography
python gen_cert.py
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `apktool not found` | Place `apktool.jar` in `lib/` or add `apktool` to PATH |
| `zipalign not found` / `apksigner not found` | Set `ANDROID_HOME`, or put an extracted build-tools folder in `build-tools/`, or install them on PATH |
| `keytool` / Java not found | Install a JDK, ensure `java`/`keytool` are on PATH, restart the terminal |
| `No template files found` | `templates/` is missing — restore it from git or run `python scripts/build_templates.py` |
| `Android SDK not found` / `Android NDK not found` | Set `ANDROID_HOME` and install NDK + CMake via SDK Manager (only needed for `build_templates.py`) |
| `baksmali CLI not found` | Install SDK cmdline-tools, or drop baksmali jars into `lib/` (only needed for `build_templates.py`) |
| Game logs redirect rules but still says "Could not connect" | Delete `/data/user/0/<pkg>/files/domain.cfg` to force re-extraction, then check logcat for `ArcExt::*` errors |
| App connects but TLS still fails | The NSC trusts system + user CAs — install your server's CA/certificate on the device |

## License

[MIT](LICENSE)
