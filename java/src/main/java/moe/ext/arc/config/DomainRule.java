package moe.ext.arc.config;

/**
 * Immutable representation of a single domain routing rule.
 */
public final class DomainRule {
    public final String originalHost;
    public final int originalPort;
    public final String replacementHost;
    public final int replacementPort;

    public DomainRule(String originalHost, int originalPort, String replacementHost, int replacementPort) {
        this.originalHost = originalHost;
        this.originalPort = originalPort;
        this.replacementHost = replacementHost;
        this.replacementPort = replacementPort;
    }
}
