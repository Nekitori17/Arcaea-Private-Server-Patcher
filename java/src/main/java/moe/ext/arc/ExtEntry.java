package moe.ext.arc;

import android.content.Context;
import android.util.Log;
import moe.ext.arc.config.DomainConfigLoader;
import moe.ext.arc.core.NativeBridge;

/**
 * Primary Java bootstrap entry point invoked from the launcher Activity's onCreate().
 */
public final class ExtEntry {
    private static final String TAG = "ArcExt::Entry";
    private static volatile boolean sInitialized = false;

    private ExtEntry() {
    }

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
            if (!NativeBridge.initialize()) {
                return;
            }
            sInitialized = true;
            Log.i(TAG, "ArcExt initialization completed successfully");
        } catch (Throwable t) {
            Log.e(TAG, "Fatal error during ArcExt initialization: " + t.getMessage(), t);
        }
    }
}
