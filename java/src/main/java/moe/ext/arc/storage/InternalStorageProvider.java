package moe.ext.arc.storage;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.os.CancellationSignal;
import android.os.ParcelFileDescriptor;
import android.provider.DocumentsContract;
import android.provider.DocumentsProvider;
import android.util.Log;
import android.webkit.MimeTypeMap;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Locale;

/**
 * Storage Access Framework (SAF) DocumentsProvider exposing the app's internal data directory.
 */
public class InternalStorageProvider extends DocumentsProvider {
    private static final String TAG = "ArcExt::SAF";
    private static final String DEFAULT_ROOT_ID = "root";

    private static final String[] DEFAULT_ROOT_PROJECTION = new String[] {
        DocumentsContract.Root.COLUMN_ROOT_ID,
        DocumentsContract.Root.COLUMN_MIME_TYPES,
        DocumentsContract.Root.COLUMN_FLAGS,
        DocumentsContract.Root.COLUMN_ICON,
        DocumentsContract.Root.COLUMN_TITLE,
        DocumentsContract.Root.COLUMN_DOCUMENT_ID,
        DocumentsContract.Root.COLUMN_AVAILABLE_BYTES
    };

    private static final String[] DEFAULT_DOCUMENT_PROJECTION = new String[] {
        DocumentsContract.Document.COLUMN_DOCUMENT_ID,
        DocumentsContract.Document.COLUMN_MIME_TYPE,
        DocumentsContract.Document.COLUMN_DISPLAY_NAME,
        DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        DocumentsContract.Document.COLUMN_FLAGS,
        DocumentsContract.Document.COLUMN_SIZE
    };

    @Override
    public boolean onCreate() {
        return true;
    }

    @Override
    public Cursor queryRoots(String[] projection) throws FileNotFoundException {
        String[] cols = projection != null ? projection : DEFAULT_ROOT_PROJECTION;
        MatrixCursor result = new MatrixCursor(cols);
        Context context = getContext();
        File root = getAppRootDir(context);
        addRootRow(context, result, root);
        return result;
    }

    @Override
    public boolean isChildDocument(String parentDocumentId, String documentId) {
        try {
            Context context = getContext();
            File parent = resolveSafeFile(context, parentDocumentId);
            File child = resolveSafeFile(context, documentId);
            String parentPath = parent.getCanonicalPath();
            String childPath = child.getCanonicalPath();
            return parentPath.equals(childPath) || childPath.startsWith(parentPath + File.separator);
        } catch (Exception e) {
            return false;
        }
    }

    @Override
    public Cursor queryDocument(String documentId, String[] projection) throws FileNotFoundException {
        String[] cols = projection != null ? projection : DEFAULT_DOCUMENT_PROJECTION;
        MatrixCursor result = new MatrixCursor(cols);
        addFileRow(getContext(), result, documentId, null);
        return result;
    }

    @Override
    public Cursor queryChildDocuments(String parentDocumentId, String[] projection, String sortOrder)
            throws FileNotFoundException {
        String[] cols = projection != null ? projection : DEFAULT_DOCUMENT_PROJECTION;
        MatrixCursor result = new MatrixCursor(cols);
        Context context = getContext();
        File root = getAppRootDir(context);
        File parent = resolveSafeFile(context, parentDocumentId);
        File[] children = parent.listFiles();
        if (children != null) {
            for (int i = 0; i < children.length; i++) {
                File file = children[i];
                if (!isPathSafe(root, file)) {
                    Log.d(TAG, "Skipping out-of-root entry: " + file.getAbsolutePath());
                    continue;
                }
                addFileRow(context, result, null, file);
            }
        }
        return result;
    }

    @Override
    public ParcelFileDescriptor openDocument(String documentId, String mode, CancellationSignal signal)
            throws FileNotFoundException {
        File file = resolveSafeFile(getContext(), documentId);
        if (file.isDirectory()) {
            throw new FileNotFoundException("Cannot open a directory: " + documentId);
        }
        return ParcelFileDescriptor.open(file, parseOpenMode(mode));
    }

    @Override
    public String createDocument(String documentId, String mimeType, String displayName)
            throws FileNotFoundException {
        Context context = getContext();
        File root = getAppRootDir(context);
        File parent = resolveSafeFile(context, documentId);
        File created = createSafeDocument(root, parent, mimeType, displayName);
        return toDocumentId(context, created);
    }

    @Override
    public void deleteDocument(String documentId) throws FileNotFoundException {
        File file = resolveSafeFile(getContext(), documentId);
        if (!deleteRecursively(file)) {
            throw new FileNotFoundException("Failed to delete document: " + documentId);
        }
    }

    @Override
    public String getDocumentType(String documentId) throws FileNotFoundException {
        File file = resolveSafeFile(getContext(), documentId);
        return resolveMimeType(file);
    }

    // --- Path and Security Helpers ---

    private static File getAppRootDir(Context context) throws FileNotFoundException {
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

    private static File resolveSafeFile(Context context, String documentId) throws FileNotFoundException {
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

    private static boolean isPathSafe(File root, File target) {
        try {
            String rootPath = root.getCanonicalPath();
            String targetPath = target.getCanonicalPath();
            return targetPath.equals(rootPath) || targetPath.startsWith(rootPath + File.separator);
        } catch (IOException e) {
            return false;
        }
    }

    private static String toDocumentId(Context context, File file) {
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

    private static String sanitizeDisplayName(String displayName) {
        String safe = displayName.replaceAll("[/\\\\:*?\"<>|]", "_").trim();
        if (safe.equals(".") || safe.equals("..") || safe.isEmpty()) {
            return "unnamed_file";
        }
        return safe;
    }

    // --- MIME Type Helpers ---

    private static String resolveMimeType(File file) {
        if (file.isDirectory()) {
            return DocumentsContract.Document.MIME_TYPE_DIR;
        }
        String name = file.getName();
        int lastDot = name.lastIndexOf('.');
        if (lastDot >= 0) {
            String ext = name.substring(lastDot + 1).toLowerCase(Locale.ROOT);
            String mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext);
            if (mime != null) {
                return mime;
            }
        }
        return "application/octet-stream";
    }

    // --- Cursor & File Operation Helpers ---

    private static void addRootRow(Context context, MatrixCursor result, File root) {
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
        row.add(DocumentsContract.Root.COLUMN_ROOT_ID, DEFAULT_ROOT_ID);
        row.add(DocumentsContract.Root.COLUMN_MIME_TYPES, "*/*");
        row.add(DocumentsContract.Root.COLUMN_DOCUMENT_ID, DEFAULT_ROOT_ID);
        row.add(DocumentsContract.Root.COLUMN_TITLE, appName);
        row.add(DocumentsContract.Root.COLUMN_FLAGS,
                DocumentsContract.Root.FLAG_SUPPORTS_CREATE
                        | DocumentsContract.Root.FLAG_SUPPORTS_IS_CHILD
                        | DocumentsContract.Root.FLAG_LOCAL_ONLY);
        row.add(DocumentsContract.Root.COLUMN_ICON, appIcon);
        row.add(DocumentsContract.Root.COLUMN_AVAILABLE_BYTES, root.getFreeSpace());
    }

    private static void addFileRow(Context context, MatrixCursor result, String docId, File file)
            throws FileNotFoundException {
        if (docId == null) {
            docId = toDocumentId(context, file);
        } else {
            file = resolveSafeFile(context, docId);
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
        row.add(DocumentsContract.Document.COLUMN_MIME_TYPE, resolveMimeType(file));
        row.add(DocumentsContract.Document.COLUMN_LAST_MODIFIED, file.lastModified());
        row.add(DocumentsContract.Document.COLUMN_FLAGS, flags);
    }

    private static int parseOpenMode(String mode) {
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

    private static File createSafeDocument(File root, File parent, String mimeType, String displayName)
            throws FileNotFoundException {
        if (displayName == null || displayName.trim().isEmpty()) {
            throw new FileNotFoundException("Display name cannot be empty.");
        }

        String safeName = sanitizeDisplayName(displayName);
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

        if (!isPathSafe(root, file)) {
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

    private static boolean deleteRecursively(File file) {
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
