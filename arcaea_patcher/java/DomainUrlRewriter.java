package moe.neki.arc;

import android.util.Log;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Standalone URL rewriter for Java-layer HTTP clients (Cocos2dxDownloader / AsyncHttpClient).
 * Reads routing rules from domain.cfg and rewrites target hostnames and ports.
 */
public final class DomainUrlRewriter {
    private static final String TAG = "DomainUrlRewriter";
    private static final String CONFIG_FILENAME = "domain.cfg";
    private static final String LOWIRO_DOMAIN = "lowiro.com";
    private static final String LOWIRO_SUFFIX = ".lowiro.com";
    private static final String[] DEFAULT_PACKAGES = new String[] {
        "moe.neki.arc",
        "moe.low.arc"
    };

    private static volatile boolean sLoaded = false;
    private static String[] sOrigHosts = new String[0];
    private static int[] sOrigPorts = new int[0];
    private static String[] sReplHosts = new String[0];
    private static int[] sReplPorts = new int[0];

    private DomainUrlRewriter() {
    }

    /**
     * Rewrites a URL string according to the active domain.cfg rules.
     * Safe and idempotent: returns the original URL if no rule applies or if already rewritten.
     */
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
        if (sOrigHosts.length == 0) {
            return url;
        }

        int authStart = schemeEnd + 3;
        int authEnd = findAuthorityEnd(url, authStart);
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
        String urlHost = parseHostPort(hostPortStr, portHolder);
        int urlPort = portHolder[0];
        if (urlHost.isEmpty()) {
            return url;
        }

        int ruleIdx = findMatchingRule(urlHost, urlPort);
        if (ruleIdx < 0) {
            return url;
        }

        String targetHost = sReplHosts[ruleIdx];
        int replPort = sReplPorts[ruleIdx];
        int targetPort = (replPort > 0) ? replPort : urlPort;

        if (hostEquals(urlHost, targetHost) && urlPort == targetPort) {
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
                File cfg = resolveConfigFile();
                if (cfg != null) {
                    parseConfigFile(cfg);
                }
                sLoaded = true;
            }
        }
    }

    private static int findMatchingRule(String host, int port) {
        int count = sOrigHosts.length;

        // 1. Exact host match
        for (int i = 0; i < count; i++) {
            if (hostEquals(sOrigHosts[i], host)) {
                int origPort = sOrigPorts[i];
                if (origPort == 0 || port == 0 || origPort == port) {
                    return i;
                }
            }
        }

        // 2. Fallback for any *.lowiro.com subdomain (e.g. CDN / asset hosts)
        if (isLowiroHost(host)) {
            for (int i = 0; i < count; i++) {
                if (isLowiroHost(sOrigHosts[i])) {
                    return i;
                }
            }
        }

        // 3. If URL already points to replacement host without custom port, attach port
        if (port == 0) {
            for (int i = 0; i < count; i++) {
                if (sReplPorts[i] > 0 && hostEquals(sReplHosts[i], host)) {
                    return i;
                }
            }
        }

        return -1;
    }

    private static void parseConfigFile(File file) {
        List<String> origHosts = new ArrayList<String>();
        List<Integer> origPorts = new ArrayList<Integer>();
        List<String> replHosts = new ArrayList<String>();
        List<Integer> replPorts = new ArrayList<Integer>();
        int[] portHolder = new int[1];

        try (BufferedReader reader = new BufferedReader(new FileReader(file))) {
            String line;
            while ((line = reader.readLine()) != null) {
                String trimmed = sanitize(line).trim();
                if (trimmed.isEmpty() || trimmed.startsWith("#")) {
                    continue;
                }
                int eq = trimmed.indexOf('=');
                if (eq <= 0 || eq == trimmed.length() - 1) {
                    continue;
                }
                String left = trimmed.substring(0, eq).trim();
                String right = trimmed.substring(eq + 1).trim();
                if (left.isEmpty() || right.isEmpty()) {
                    continue;
                }
                String oHost = parseHostPort(left, portHolder);
                int oPort = portHolder[0];
                String rHost = parseHostPort(right, portHolder);
                int rPort = portHolder[0];
                if (!oHost.isEmpty() && !rHost.isEmpty()) {
                    origHosts.add(oHost);
                    origPorts.add(Integer.valueOf(oPort));
                    replHosts.add(rHost);
                    replPorts.add(Integer.valueOf(rPort));
                }
            }
            int n = origHosts.size();
            String[] oH = new String[n];
            int[] oP = new int[n];
            String[] rH = new String[n];
            int[] rP = new int[n];
            for (int i = 0; i < n; i++) {
                oH[i] = origHosts.get(i);
                oP[i] = origPorts.get(i).intValue();
                rH[i] = replHosts.get(i);
                rP[i] = replPorts.get(i).intValue();
            }
            sOrigHosts = oH;
            sOrigPorts = oP;
            sReplHosts = rH;
            sReplPorts = rP;
            Log.i(TAG, "Loaded " + n + " URL rewrite rule(s) from " + file.getAbsolutePath());
        } catch (Exception e) {
            Log.w(TAG, "Failed to read domain.cfg: " + e.getMessage());
        }
    }

    private static File resolveConfigFile() {
        List<String> pkgs = new ArrayList<String>();
        String selfPkg = readProcCmdline();
        if (selfPkg != null && !selfPkg.isEmpty()) {
            pkgs.add(selfPkg);
        }
        for (String defPkg : DEFAULT_PACKAGES) {
            if (!pkgs.contains(defPkg)) {
                pkgs.add(defPkg);
            }
        }

        for (int i = 0; i < pkgs.size(); i++) {
            String pkg = pkgs.get(i);
            File c1 = new File("/data/user/0/" + pkg + "/files/" + CONFIG_FILENAME);
            if (c1.isFile() && c1.canRead()) {
                return c1;
            }
            File c2 = new File("/data/data/" + pkg + "/files/" + CONFIG_FILENAME);
            if (c2.isFile() && c2.canRead()) {
                return c2;
            }
        }
        return null;
    }

    private static String readProcCmdline() {
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

    private static int findAuthorityEnd(String url, int start) {
        int len = url.length();
        for (int i = start; i < len; i++) {
            char c = url.charAt(i);
            if (c == '/' || c == '?' || c == '#') {
                return i;
            }
        }
        return len;
    }

    private static String sanitize(String s) {
        StringBuilder sb = new StringBuilder(s.length());
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (c >= 0x20 && c != '"') {
                sb.append(c);
            }
        }
        return sb.toString();
    }

    private static String normalizeHost(String host) {
        if (host == null) {
            return "";
        }
        int end = host.length();
        while (end > 0 && host.charAt(end - 1) == '.') {
            end--;
        }
        return host.substring(0, end).toLowerCase(Locale.ROOT);
    }

    private static boolean hostEquals(String a, String b) {
        return normalizeHost(a).equals(normalizeHost(b));
    }

    private static boolean isLowiroHost(String host) {
        String norm = normalizeHost(host);
        return norm.equals(LOWIRO_DOMAIN) || norm.endsWith(LOWIRO_SUFFIX);
    }

    private static String parseHostPort(String input, int[] outPort) {
        outPort[0] = 0;
        if (input == null || input.isEmpty()) {
            return "";
        }
        if (input.charAt(0) == '[') {
            int rb = input.indexOf(']');
            if (rb > 0) {
                String h = input.substring(1, rb);
                if (rb + 2 <= input.length() && input.charAt(rb + 1) == ':') {
                    outPort[0] = parsePort(input.substring(rb + 2));
                }
                return h;
            }
        }
        int firstColon = input.indexOf(':');
        int lastColon = input.lastIndexOf(':');
        if (firstColon > 0 && firstColon == lastColon && lastColon + 1 < input.length()) {
            int p = parsePort(input.substring(lastColon + 1));
            if (p > 0) {
                outPort[0] = p;
                return input.substring(0, lastColon);
            }
        }
        return input;
    }

    private static int parsePort(String s) {
        try {
            int p = Integer.parseInt(s.trim());
            return (p > 0 && p <= 65535) ? p : 0;
        } catch (NumberFormatException e) {
            return 0;
        }
    }
}
