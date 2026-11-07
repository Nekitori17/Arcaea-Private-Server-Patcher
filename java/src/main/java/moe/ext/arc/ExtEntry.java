package moe.ext.arc;

import android.content.Context;
import android.util.Log;
import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import moe.ext.arc.config.DomainConfigLoader;

/**
 * Primary Java bootstrap entry point invoked from the launcher Activity's onCreate().
 */
public final class ExtEntry {
    private static final String TAG = "ArcExt::Entry";
    private static final String LIBRARY_NAME = "ext";
    private static volatile boolean sInitialized = false;

    private ExtEntry() {
    }

    public static native void nativeInit();

    public static synchronized void init(Context context) {
        if (sInitialized) {
            Log.d(TAG, "ExtEntry already initialized, skipping");
            return;
        }
        if (context == null) {
            Log.w(TAG, "Context is null, cannot initialize ArcExt");
            return;
        }

        try {
            DomainConfigLoader.ensureConfigExtracted(context);
            if (!initializeNative()) {
                return;
            }
            sInitialized = true;
            Log.i(TAG, "ArcExt initialization completed successfully");
        } catch (Throwable t) {
            Log.e(TAG, "Fatal error during ArcExt initialization: " + t.getMessage(), t);
        }
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

    public static boolean initializeNative() {
        try {
            System.loadLibrary(LIBRARY_NAME);
            Log.i(TAG, "libext.so loaded successfully");
        } catch (Throwable t) {
            Log.e(TAG, "Failed to load libext.so", t);
            return false;
        }

        try {
            nativeInit();
            return true;
        } catch (Throwable t) {
            Log.e(TAG, "nativeInit() failed", t);
            return false;
        }
    }
}
