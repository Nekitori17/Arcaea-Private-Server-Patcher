package moe.ext.arc.core;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/**
 * Resolves package identity and internal storage file paths.
 */
public final class AppEnvironment {
    public static final String DOMAIN_CONFIG_NAME = "domain.cfg";

    private static final String[] FALLBACK_PACKAGES = new String[] {
        "moe.ext.arc",
        "moe.low.arc"
    };

    private AppEnvironment() {
    }

    public static String getCurrentPackageName() {
        try (FileInputStream in = new FileInputStream("/proc/self/cmdline");
             InputStreamReader isr = new InputStreamReader(in, StandardCharsets.UTF_8);
             BufferedReader reader = new BufferedReader(isr)) {
            StringBuilder sb = new StringBuilder();
            int ch;
            while ((ch = reader.read()) > 0) {
                sb.append((char) ch);
            }
            return sb.toString().trim();
        } catch (Exception e) {
            return null;
        }
    }

    public static File resolveConfigFile(String filename) {
        List<String> candidates = new ArrayList<String>();
        String selfPkg = getCurrentPackageName();
        if (selfPkg != null && !selfPkg.isEmpty()) {
            candidates.add(selfPkg);
        }
        for (int i = 0; i < FALLBACK_PACKAGES.length; i++) {
            String defPkg = FALLBACK_PACKAGES[i];
            if (!candidates.contains(defPkg)) {
                candidates.add(defPkg);
            }
        }

        for (int i = 0; i < candidates.size(); i++) {
            String pkg = candidates.get(i);
            File userZero = new File("/data/user/0/" + pkg + "/files/" + filename);
            if (userZero.isFile() && userZero.canRead()) {
                return userZero;
            }
            File legacyData = new File("/data/data/" + pkg + "/files/" + filename);
            if (legacyData.isFile() && legacyData.canRead()) {
                return legacyData;
            }
        }
        return null;
    }
}
