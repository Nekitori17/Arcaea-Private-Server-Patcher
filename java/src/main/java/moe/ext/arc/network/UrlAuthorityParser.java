package moe.ext.arc.network;

import java.util.Locale;

/**
 * Utilities for parsing URL authorities, host:port pairs, and normalizing hostnames.
 */
public final class UrlAuthorityParser {

    private UrlAuthorityParser() {
    }

    public static int findAuthorityEnd(String url, int start) {
        int len = url.length();
        for (int i = start; i < len; i++) {
            char c = url.charAt(i);
            if (c == '/' || c == '?' || c == '#') {
                return i;
            }
        }
        return len;
    }

    public static String sanitize(String s) {
        if (s == null) {
            return "";
        }
        StringBuilder sb = new StringBuilder(s.length());
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (c >= 0x20 && c != '"') {
                sb.append(c);
            }
        }
        return sb.toString();
    }

    public static String normalizeHost(String host) {
        if (host == null) {
            return "";
        }
        int end = host.length();
        while (end > 0 && host.charAt(end - 1) == '.') {
            end--;
        }
        return host.substring(0, end).toLowerCase(Locale.ROOT);
    }

    public static boolean hostEquals(String a, String b) {
        return normalizeHost(a).equals(normalizeHost(b));
    }

    public static String parseHostPort(String input, int[] outPort) {
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

    public static int parsePort(String s) {
        try {
            int p = Integer.parseInt(s.trim());
            return (p > 0 && p <= 65535) ? p : 0;
        } catch (NumberFormatException e) {
            return 0;
        }
    }
}
