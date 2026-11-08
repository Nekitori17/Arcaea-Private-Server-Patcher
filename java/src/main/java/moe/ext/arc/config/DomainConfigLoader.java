package moe.ext.arc.config;

import android.content.Context;
import android.util.Log;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import moe.ext.arc.network.UrlAuthorityParser;
import moe.ext.arc.utils.FileUtils;

/**
 * Extracts, validates, and parses domain.cfg routing rules.
 */
public final class DomainConfigLoader {
    private static final String TAG = "ArcExt::Config";

    /**
     * Immutable representation of a single domain routing rule.
     */
    public static final class DomainRule {
        public final String originalHost;
        public final int originalPort;
        public final String replacementHost;
        public final int replacementPort;

        public DomainRule(String originalHost, int originalPort, String replacementHost, int replacementPort) {
            this.originalHost = originalHost;
            this.originalPort = originalPort;
            this.replacementHost = replacementHost;
            this.replacementPort = replacementPort;
        }
    }

    private DomainConfigLoader() {
    }

    public static void ensureConfigExtracted(Context context) {
        File filesDir = context.getFilesDir();
        if (filesDir != null && !filesDir.exists()) {
            filesDir.mkdirs();
        }
        File target = new File(filesDir, FileUtils.DOMAIN_CONFIG_NAME);
        if (target.exists() && target.length() > 0) {
            if (!loadRules(target).isEmpty()) {
                Log.i(TAG, "Keeping existing domain.cfg: " + target.getAbsolutePath());
                return;
            }
            Log.w(TAG, "Existing domain.cfg is malformed; re-extracting from assets");
        }
        extractAssetConfig(context, target);
    }

    public static List<DomainRule> loadActiveRules() {
        File cfg = FileUtils.resolveFilePath(FileUtils.DOMAIN_CONFIG_NAME);
        if (cfg == null) {
            return Collections.emptyList();
        }
        List<DomainRule> rules = loadRules(cfg);
        Log.i(TAG, "Loaded " + rules.size() + " URL rewrite rule(s) from " + cfg.getAbsolutePath());
        return rules;
    }

    public static List<DomainRule> loadRules(File file) {
        if (file == null || !file.isFile() || file.length() == 0) {
            return Collections.emptyList();
        }

        List<DomainRule> rules = new ArrayList<DomainRule>();
        int[] portHolder = new int[1];

        try (BufferedReader reader = new BufferedReader(new FileReader(file))) {
            String line;
            while ((line = reader.readLine()) != null) {
                String sanitized = UrlAuthorityParser.sanitize(line).trim();
                if (sanitized.isEmpty() || sanitized.startsWith("#")) {
                    continue;
                }
                int eq = sanitized.indexOf('=');
                if (eq <= 0 || eq == sanitized.length() - 1) {
                    continue;
                }
                String left = sanitized.substring(0, eq).trim();
                String right = sanitized.substring(eq + 1).trim();
                if (left.isEmpty() || right.isEmpty()) {
                    continue;
                }
                String origHost = UrlAuthorityParser.parseHostPort(left, portHolder);
                int origPort = portHolder[0];
                String replHost = UrlAuthorityParser.parseHostPort(right, portHolder);
                int replPort = portHolder[0];

                if (!origHost.isEmpty() && !replHost.isEmpty()) {
                    rules.add(new DomainRule(origHost, origPort, replHost, replPort));
                }
            }
        } catch (Exception e) {
            Log.w(TAG, "Failed to parse domain.cfg: " + e.getMessage());
            return Collections.emptyList();
        }

        return rules;
    }

    private static void extractAssetConfig(Context context, File target) {
        try (InputStream in = context.getAssets().open(FileUtils.DOMAIN_CONFIG_NAME);
             OutputStream out = new FileOutputStream(target)) {
            byte[] buffer = new byte[4096];
            int read;
            while ((read = in.read(buffer)) != -1) {
                out.write(buffer, 0, read);
            }
            out.flush();
            Log.i(TAG, "Extracted domain.cfg to: " + target.getAbsolutePath());
        } catch (Exception e) {
            Log.w(TAG, "No domain.cfg in assets or extraction failed: " + e.getMessage());
        }
    }
}
