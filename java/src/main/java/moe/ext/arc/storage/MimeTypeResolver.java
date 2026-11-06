package moe.ext.arc.storage;

import android.provider.DocumentsContract;
import android.webkit.MimeTypeMap;
import java.io.File;
import java.util.Locale;

/**
 * Resolves MIME types for files and directories exposed via SAF.
 */
public final class MimeTypeResolver {

    private MimeTypeResolver() {
    }

    public static String resolveForFile(File file) {
        if (file.isDirectory()) {
            return DocumentsContract.Document.MIME_TYPE_DIR;
        }
        return resolveForName(file.getName());
    }

    public static String resolveForName(String name) {
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
}
