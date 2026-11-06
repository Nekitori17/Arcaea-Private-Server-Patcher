package moe.ext.arc.storage;

import android.content.Context;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;

/**
 * Enforces canonical path containment and sanitizes display names for SAF operations.
 */
public final class PathSecurityGuard {
    public static final String DEFAULT_ROOT_ID = "root";

    private PathSecurityGuard() {
    }

    public static File getAppRootDir(Context context) throws FileNotFoundException {
        if (context == null) {
            throw new FileNotFoundException("Context is not available");
        }

        File root = null;
        if (context.getApplicationInfo() != null && context.getApplicationInfo().dataDir != null) {
            root = new File(context.getApplicationInfo().dataDir);
        } else if (context.getFilesDir() != null) {
            root = context.getFilesDir().getParentFile();
        }

        if (root == null || !root.exists()) {
            throw new FileNotFoundException("App root directory is not accessible");
        }
        return root;
    }

    public static File resolveSafeFile(Context context, String documentId) throws FileNotFoundException {
        File root = getAppRootDir(context);
        File target = root;

        if (documentId != null && !documentId.isEmpty() && !DEFAULT_ROOT_ID.equals(documentId)) {
            target = new File(root, documentId);
        }

        if (!target.exists() || !isPathSafe(root, target)) {
            throw new FileNotFoundException("Missing or unauthorized file for: " + documentId);
        }
        return target;
    }

    public static boolean isPathSafe(File root, File target) {
        try {
            String rootPath = root.getCanonicalPath();
            String targetPath = target.getCanonicalPath();
            return targetPath.equals(rootPath) || targetPath.startsWith(rootPath + File.separator);
        } catch (IOException e) {
            return false;
        }
    }

    public static String toDocumentId(Context context, File file) {
        try {
            File root = getAppRootDir(context);
            String canonicalFile = file.getCanonicalPath();
            String canonicalRoot = root.getCanonicalPath();

            if (canonicalRoot.equals(canonicalFile)) {
                return DEFAULT_ROOT_ID;
            }

            String prefix = canonicalRoot.endsWith(File.separator)
                    ? canonicalRoot
                    : canonicalRoot + File.separator;
            if (canonicalFile.startsWith(prefix)) {
                return canonicalFile.substring(prefix.length());
            }
            return canonicalFile;
        } catch (Exception e) {
            return file.getAbsolutePath();
        }
    }

    public static String sanitizeDisplayName(String displayName) {
        String safe = displayName.replaceAll("[/\\\\:*?\"<>|]", "_").trim();
        if (safe.equals(".") || safe.equals("..") || safe.isEmpty()) {
            return "unnamed_file";
        }
        return safe;
    }
}
