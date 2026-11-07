package moe.ext.arc.core;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import moe.ext.arc.ExtEntry;

/**
 * Generic file and path resolution utilities.
 */
public final class FileUtils {
    public static final String DOMAIN_CONFIG_NAME = "domain.cfg";

    private static final String[] FALLBACK_PACKAGES = new String[] {
        "moe.ext.arc",
        "moe.low.arc"
    };

    private FileUtils() {
    }

    public static File resolveFilePath(String filename) {
        List<String> candidates = new ArrayList<String>();
        String selfPkg = ExtEntry.getCurrentPackageName();
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

