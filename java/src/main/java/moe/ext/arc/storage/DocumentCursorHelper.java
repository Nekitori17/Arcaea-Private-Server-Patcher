package moe.ext.arc.storage;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.database.MatrixCursor;
import android.os.ParcelFileDescriptor;
import android.provider.DocumentsContract;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;

/**
 * Helper for building SAF MatrixCursor rows and executing safe file mutations.
 */
public final class DocumentCursorHelper {

    public static final String[] DEFAULT_ROOT_PROJECTION = new String[] {
        DocumentsContract.Root.COLUMN_ROOT_ID,
        DocumentsContract.Root.COLUMN_MIME_TYPES,
        DocumentsContract.Root.COLUMN_FLAGS,
        DocumentsContract.Root.COLUMN_ICON,
        DocumentsContract.Root.COLUMN_TITLE,
        DocumentsContract.Root.COLUMN_DOCUMENT_ID,
        DocumentsContract.Root.COLUMN_AVAILABLE_BYTES
    };

    public static final String[] DEFAULT_DOCUMENT_PROJECTION = new String[] {
        DocumentsContract.Document.COLUMN_DOCUMENT_ID,
        DocumentsContract.Document.COLUMN_MIME_TYPE,
        DocumentsContract.Document.COLUMN_DISPLAY_NAME,
        DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        DocumentsContract.Document.COLUMN_FLAGS,
        DocumentsContract.Document.COLUMN_SIZE
    };

    private DocumentCursorHelper() {
    }

    public static void addRootRow(Context context, MatrixCursor result, File root) {
        String appName = "Arcaea";
        int appIcon = android.R.drawable.ic_dialog_info;
        if (context != null) {
            try {
                PackageManager pm = context.getPackageManager();
                ApplicationInfo info = context.getApplicationInfo();
                appName = pm.getApplicationLabel(info).toString();
                if (info.icon != 0) {
                    appIcon = info.icon;
                }
            } catch (Exception ignored) {
            }
        }

        MatrixCursor.RowBuilder row = result.newRow();
        row.add(DocumentsContract.Root.COLUMN_ROOT_ID, PathSecurityGuard.DEFAULT_ROOT_ID);
        row.add(DocumentsContract.Root.COLUMN_MIME_TYPES, "*/*");
        row.add(DocumentsContract.Root.COLUMN_DOCUMENT_ID, PathSecurityGuard.DEFAULT_ROOT_ID);
        row.add(DocumentsContract.Root.COLUMN_TITLE, appName);
        row.add(DocumentsContract.Root.COLUMN_FLAGS,
                DocumentsContract.Root.FLAG_SUPPORTS_CREATE
                        | DocumentsContract.Root.FLAG_SUPPORTS_IS_CHILD
                        | DocumentsContract.Root.FLAG_LOCAL_ONLY);
        row.add(DocumentsContract.Root.COLUMN_ICON, appIcon);
        row.add(DocumentsContract.Root.COLUMN_AVAILABLE_BYTES, root.getFreeSpace());
    }

    public static void addFileRow(Context context, MatrixCursor result, String docId, File file)
            throws FileNotFoundException {
        if (docId == null) {
            docId = PathSecurityGuard.toDocumentId(context, file);
        } else {
            file = PathSecurityGuard.resolveSafeFile(context, docId);
        }

        int flags = file.isDirectory()
                ? (DocumentsContract.Document.FLAG_DIR_SUPPORTS_CREATE
                        | DocumentsContract.Document.FLAG_SUPPORTS_DELETE)
                : (DocumentsContract.Document.FLAG_SUPPORTS_WRITE
                        | DocumentsContract.Document.FLAG_SUPPORTS_DELETE);

        MatrixCursor.RowBuilder row = result.newRow();
        row.add(DocumentsContract.Document.COLUMN_DOCUMENT_ID, docId);
        row.add(DocumentsContract.Document.COLUMN_DISPLAY_NAME, file.getName());
        row.add(DocumentsContract.Document.COLUMN_SIZE, file.length());
        row.add(DocumentsContract.Document.COLUMN_MIME_TYPE, MimeTypeResolver.resolveForFile(file));
        row.add(DocumentsContract.Document.COLUMN_LAST_MODIFIED, file.lastModified());
        row.add(DocumentsContract.Document.COLUMN_FLAGS, flags);
    }

    public static int parseOpenMode(String mode) {
        if ("r".equals(mode)) {
            return ParcelFileDescriptor.MODE_READ_ONLY;
        }
        if ("w".equals(mode) || "wt".equals(mode)) {
            return ParcelFileDescriptor.MODE_WRITE_ONLY | ParcelFileDescriptor.MODE_CREATE
                    | ParcelFileDescriptor.MODE_TRUNCATE;
        }
        if ("wa".equals(mode)) {
            return ParcelFileDescriptor.MODE_WRITE_ONLY | ParcelFileDescriptor.MODE_CREATE
                    | ParcelFileDescriptor.MODE_APPEND;
        }
        if ("rw".equals(mode)) {
            return ParcelFileDescriptor.MODE_READ_WRITE | ParcelFileDescriptor.MODE_CREATE;
        }
        if ("rwt".equals(mode)) {
            return ParcelFileDescriptor.MODE_READ_WRITE | ParcelFileDescriptor.MODE_CREATE
                    | ParcelFileDescriptor.MODE_TRUNCATE;
        }
        throw new IllegalArgumentException("Invalid mode: " + mode);
    }

    public static File createSafeDocument(File root, File parent, String mimeType, String displayName)
            throws FileNotFoundException {
        if (displayName == null || displayName.trim().isEmpty()) {
            throw new FileNotFoundException("Display name cannot be empty.");
        }

        String safeName = PathSecurityGuard.sanitizeDisplayName(displayName);
        File file = new File(parent, safeName);

        if (file.exists()) {
            String baseName = safeName;
            String ext = "";
            int dotIndex = safeName.lastIndexOf('.');
            if (!DocumentsContract.Document.MIME_TYPE_DIR.equals(mimeType) && dotIndex > 0) {
                baseName = safeName.substring(0, dotIndex);
                ext = safeName.substring(dotIndex);
            }
            int count = 1;
            while (file.exists()) {
                file = new File(parent, baseName + " (" + count + ")" + ext);
                count++;
            }
        }

        if (!PathSecurityGuard.isPathSafe(root, file)) {
            throw new FileNotFoundException("Invalid document destination.");
        }

        try {
            boolean ok = DocumentsContract.Document.MIME_TYPE_DIR.equals(mimeType)
                    ? file.mkdirs()
                    : file.createNewFile();
            if (!ok) {
                throw new IOException("Failed to create: " + file.getAbsolutePath());
            }
            return file;
        } catch (Exception e) {
            throw new FileNotFoundException("Failed to create document: " + e.getMessage());
        }
    }

    public static boolean deleteRecursively(File file) {
        if (file.isDirectory()) {
            File[] children = file.listFiles();
            if (children != null) {
                for (int i = 0; i < children.length; i++) {
                    if (!deleteRecursively(children[i])) {
                        return false;
                    }
                }
            }
        }
        return file.delete();
    }
}

