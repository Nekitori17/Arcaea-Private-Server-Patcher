package moe.ext.arc.storage;

import android.content.Context;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.os.CancellationSignal;
import android.os.ParcelFileDescriptor;
import android.provider.DocumentsProvider;
import android.util.Log;
import java.io.File;
import java.io.FileNotFoundException;

/**
 * Storage Access Framework (SAF) DocumentsProvider exposing the app's internal data directory.
 */
public class InternalStorageProvider extends DocumentsProvider {
    private static final String TAG = "ArcExt::SAF";

    @Override
    public boolean onCreate() {
        return true;
    }

    @Override
    public Cursor queryRoots(String[] projection) throws FileNotFoundException {
        String[] cols = projection != null ? projection : DocumentCursorHelper.DEFAULT_ROOT_PROJECTION;
        MatrixCursor result = new MatrixCursor(cols);
        Context context = getContext();
        File root = PathSecurityGuard.getAppRootDir(context);
        DocumentCursorHelper.addRootRow(context, result, root);
        return result;
    }

    @Override
    public boolean isChildDocument(String parentDocumentId, String documentId) {
        try {
            Context context = getContext();
            File parent = PathSecurityGuard.resolveSafeFile(context, parentDocumentId);
            File child = PathSecurityGuard.resolveSafeFile(context, documentId);
            String parentPath = parent.getCanonicalPath();
            String childPath = child.getCanonicalPath();
            return parentPath.equals(childPath) || childPath.startsWith(parentPath + File.separator);
        } catch (Exception e) {
            return false;
        }
    }

    @Override
    public Cursor queryDocument(String documentId, String[] projection) throws FileNotFoundException {
        String[] cols = projection != null ? projection : DocumentCursorHelper.DEFAULT_DOCUMENT_PROJECTION;
        MatrixCursor result = new MatrixCursor(cols);
        DocumentCursorHelper.addFileRow(getContext(), result, documentId, null);
        return result;
    }

    @Override
    public Cursor queryChildDocuments(String parentDocumentId, String[] projection, String sortOrder)
            throws FileNotFoundException {
        String[] cols = projection != null ? projection : DocumentCursorHelper.DEFAULT_DOCUMENT_PROJECTION;
        MatrixCursor result = new MatrixCursor(cols);
        Context context = getContext();
        File root = PathSecurityGuard.getAppRootDir(context);
        File parent = PathSecurityGuard.resolveSafeFile(context, parentDocumentId);
        File[] children = parent.listFiles();
        if (children != null) {
            for (int i = 0; i < children.length; i++) {
                File file = children[i];
                if (!PathSecurityGuard.isPathSafe(root, file)) {
                    Log.d(TAG, "Skipping out-of-root entry: " + file.getAbsolutePath());
                    continue;
                }
                DocumentCursorHelper.addFileRow(context, result, null, file);
            }
        }
        return result;
    }

    @Override
    public ParcelFileDescriptor openDocument(String documentId, String mode, CancellationSignal signal)
            throws FileNotFoundException {
        File file = PathSecurityGuard.resolveSafeFile(getContext(), documentId);
        if (file.isDirectory()) {
            throw new FileNotFoundException("Cannot open a directory: " + documentId);
        }
        return ParcelFileDescriptor.open(file, DocumentCursorHelper.parseOpenMode(mode));
    }

    @Override
    public String createDocument(String documentId, String mimeType, String displayName)
            throws FileNotFoundException {
        Context context = getContext();
        File root = PathSecurityGuard.getAppRootDir(context);
        File parent = PathSecurityGuard.resolveSafeFile(context, documentId);
        File created = DocumentCursorHelper.createSafeDocument(root, parent, mimeType, displayName);
        return PathSecurityGuard.toDocumentId(context, created);
    }

    @Override
    public void deleteDocument(String documentId) throws FileNotFoundException {
        File file = PathSecurityGuard.resolveSafeFile(getContext(), documentId);
        if (!DocumentCursorHelper.deleteRecursively(file)) {
            throw new FileNotFoundException("Failed to delete document: " + documentId);
        }
    }

    @Override
    public String getDocumentType(String documentId) throws FileNotFoundException {
        File file = PathSecurityGuard.resolveSafeFile(getContext(), documentId);
        return MimeTypeResolver.resolveForFile(file);
    }
}
