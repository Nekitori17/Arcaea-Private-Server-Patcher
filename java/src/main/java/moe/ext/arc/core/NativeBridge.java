package moe.ext.arc.core;

import android.util.Log;

/**
 * Loads libext.so and bridges Java lifecycle calls to native C++ hooks.
 */
public final class NativeBridge {
    private static final String TAG = "ArcExt::Bridge";
    private static final String LIBRARY_NAME = "ext";

    private NativeBridge() {
    }

    public static native void nativeInit();

    public static boolean initialize() {
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
