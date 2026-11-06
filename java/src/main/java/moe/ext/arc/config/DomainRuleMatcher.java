package moe.ext.arc.config;

import java.util.List;
import moe.ext.arc.network.UrlAuthorityParser;

/**
 * Matches target hostnames and ports against active DomainRule entries.
 */
public final class DomainRuleMatcher {
    private static final String LOWIRO_DOMAIN = "lowiro.com";
    private static final String LOWIRO_SUFFIX = ".lowiro.com";

    private DomainRuleMatcher() {
    }

    public static DomainRule findMatch(List<DomainRule> rules, String host, int port) {
        if (rules == null || rules.isEmpty() || host == null || host.isEmpty()) {
            return null;
        }

        int size = rules.size();

        // 1. Exact hostname match
        for (int i = 0; i < size; i++) {
            DomainRule r = rules.get(i);
            if (UrlAuthorityParser.hostEquals(r.originalHost, host)) {
                if (r.originalPort == 0 || port == 0 || r.originalPort == port) {
                    return r;
                }
            }
        }

        // 2. Fallback for any *.lowiro.com subdomain
        if (isLowiroHost(host)) {
            for (int i = 0; i < size; i++) {
                DomainRule r = rules.get(i);
                if (isLowiroHost(r.originalHost)) {
                    return r;
                }
            }
        }

        // 3. Attach custom port if URL already points to replacement host without port
        if (port == 0) {
            for (int i = 0; i < size; i++) {
                DomainRule r = rules.get(i);
                if (r.replacementPort > 0 && UrlAuthorityParser.hostEquals(r.replacementHost, host)) {
                    return r;
                }
            }
        }

        return null;
    }

    private static boolean isLowiroHost(String host) {
        String norm = UrlAuthorityParser.normalizeHost(host);
        return norm.equals(LOWIRO_DOMAIN) || norm.endsWith(LOWIRO_SUFFIX);
    }
}
