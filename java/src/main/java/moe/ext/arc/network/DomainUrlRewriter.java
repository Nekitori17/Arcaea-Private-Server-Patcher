package moe.ext.arc.network;

import android.util.Log;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import moe.ext.arc.config.DomainConfigLoader;
import moe.ext.arc.config.DomainRule;
import moe.ext.arc.config.DomainRuleMatcher;

/**
 * URL rewriter for Java-layer HTTP clients (Cocos2dxDownloader, AsyncHttpClient, HttpURLConnection).
 */
public final class DomainUrlRewriter {
    private static final String TAG = "ArcExt::UrlRewriter";

    private static volatile boolean sLoaded = false;
    private static volatile List<DomainRule> sRules = Collections.emptyList();

    private DomainUrlRewriter() {
    }

    public static String rewriteUrl(String url) {
        if (url == null || url.isEmpty()) {
            return url;
        }

        int schemeEnd = url.indexOf("://");
        if (schemeEnd != 4 && schemeEnd != 5) {
            return url;
        }
        String scheme = url.substring(0, schemeEnd).toLowerCase(Locale.ROOT);
        if (!"http".equals(scheme) && !"https".equals(scheme)) {
            return url;
        }

        ensureLoaded();
        List<DomainRule> rules = sRules;
        if (rules.isEmpty()) {
            return url;
        }

        int authStart = schemeEnd + 3;
        int authEnd = UrlAuthorityParser.findAuthorityEnd(url, authStart);
        if (authEnd <= authStart) {
            return url;
        }

        String authority = url.substring(authStart, authEnd);
        int atIdx = authority.lastIndexOf('@');
        int hostPortStart = (atIdx >= 0) ? (authStart + atIdx + 1) : authStart;
        if (hostPortStart >= authEnd) {
            return url;
        }

        String hostPortStr = url.substring(hostPortStart, authEnd);
        int[] portHolder = new int[1];
        String urlHost = UrlAuthorityParser.parseHostPort(hostPortStr, portHolder);
        int urlPort = portHolder[0];
        if (urlHost.isEmpty()) {
            return url;
        }

        DomainRule match = DomainRuleMatcher.findMatch(rules, urlHost, urlPort);
        if (match == null) {
            return url;
        }

        String targetHost = match.replacementHost;
        int targetPort = (match.replacementPort > 0) ? match.replacementPort : urlPort;

        if (UrlAuthorityParser.hostEquals(urlHost, targetHost) && urlPort == targetPort) {
            return url;
        }

        StringBuilder rebuilt = new StringBuilder(url.length() + 32);
        rebuilt.append(url, 0, hostPortStart);
        if (targetHost.indexOf(':') >= 0 && !targetHost.startsWith("[")) {
            rebuilt.append('[').append(targetHost).append(']');
        } else {
            rebuilt.append(targetHost);
        }
        if (targetPort > 0) {
            rebuilt.append(':').append(targetPort);
        }
        rebuilt.append(url, authEnd, url.length());

        String result = rebuilt.toString();
        Log.i(TAG, "Redirected URL: " + url + " -> " + result);
        return result;
    }

    private static void ensureLoaded() {
        if (sLoaded) {
            return;
        }
        synchronized (DomainUrlRewriter.class) {
            if (!sLoaded) {
                sRules = DomainConfigLoader.loadActiveRules();
                sLoaded = true;
            }
        }
    }
}
