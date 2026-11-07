.class public final Lmoe/ext/arc/config/DomainRuleMatcher;
.super Ljava/lang/Object;
.source "DomainRuleMatcher.java"


# static fields
.field private static final LOWIRO_DOMAIN:Ljava/lang/String; = "lowiro.com"

.field private static final LOWIRO_SUFFIX:Ljava/lang/String; = ".lowiro.com"


# direct methods
.method private constructor <init>()V
    .locals 0

    .line 14
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 15
    return-void
.end method

.method public static findMatch(Ljava/util/List;Ljava/lang/String;I)Lmoe/ext/arc/config/DomainConfigLoader$DomainRule;
    .locals 6
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/util/List<",
            "Lmoe/ext/arc/config/DomainConfigLoader$DomainRule;",
            ">;",
            "Ljava/lang/String;",
            "I)",
            "Lmoe/ext/arc/config/DomainConfigLoader$DomainRule;"
        }
    .end annotation

    .line 18
    const/4 v0, 0x0

    if-eqz p0, :cond_6d

    invoke-interface {p0}, Ljava/util/List;->isEmpty()Z

    move-result v1

    if-nez v1, :cond_6d

    if-eqz p1, :cond_6d

    invoke-virtual {p1}, Ljava/lang/String;->isEmpty()Z

    move-result v1

    if-eqz v1, :cond_12

    goto :goto_6d

    .line 22
    :cond_12
    invoke-interface {p0}, Ljava/util/List;->size()I

    move-result v1

    .line 25
    const/4 v2, 0x0

    const/4 v3, 0x0

    :goto_18
    if-ge v3, v1, :cond_36

    .line 26
    invoke-interface {p0, v3}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v4

    check-cast v4, Lmoe/ext/arc/config/DomainConfigLoader$DomainRule;

    .line 27
    iget-object v5, v4, Lmoe/ext/arc/config/DomainConfigLoader$DomainRule;->originalHost:Ljava/lang/String;

    invoke-static {v5, p1}, Lmoe/ext/arc/network/UrlAuthorityParser;->hostEquals(Ljava/lang/String;Ljava/lang/String;)Z

    move-result v5

    if-eqz v5, :cond_33

    .line 28
    iget v5, v4, Lmoe/ext/arc/config/DomainConfigLoader$DomainRule;->originalPort:I

    if-eqz v5, :cond_32

    if-eqz p2, :cond_32

    iget v5, v4, Lmoe/ext/arc/config/DomainConfigLoader$DomainRule;->originalPort:I

    if-ne v5, p2, :cond_33

    .line 29
    :cond_32
    return-object v4

    .line 25
    :cond_33
    add-int/lit8 v3, v3, 0x1

    goto :goto_18

    .line 35
    :cond_36
    invoke-static {p1}, Lmoe/ext/arc/config/DomainRuleMatcher;->isLowiroHost(Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_51

    .line 36
    const/4 v3, 0x0

    :goto_3d
    if-ge v3, v1, :cond_51

    .line 37
    invoke-interface {p0, v3}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v4

    check-cast v4, Lmoe/ext/arc/config/DomainConfigLoader$DomainRule;

    .line 38
    iget-object v5, v4, Lmoe/ext/arc/config/DomainConfigLoader$DomainRule;->originalHost:Ljava/lang/String;

    invoke-static {v5}, Lmoe/ext/arc/config/DomainRuleMatcher;->isLowiroHost(Ljava/lang/String;)Z

    move-result v5

    if-eqz v5, :cond_4e

    .line 39
    return-object v4

    .line 36
    :cond_4e
    add-int/lit8 v3, v3, 0x1

    goto :goto_3d

    .line 45
    :cond_51
    if-nez p2, :cond_6c

    .line 46
    nop

    :goto_54
    if-ge v2, v1, :cond_6c

    .line 47
    invoke-interface {p0, v2}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object p2

    check-cast p2, Lmoe/ext/arc/config/DomainConfigLoader$DomainRule;

    .line 48
    iget v3, p2, Lmoe/ext/arc/config/DomainConfigLoader$DomainRule;->replacementPort:I

    if-lez v3, :cond_69

    iget-object v3, p2, Lmoe/ext/arc/config/DomainConfigLoader$DomainRule;->replacementHost:Ljava/lang/String;

    invoke-static {v3, p1}, Lmoe/ext/arc/network/UrlAuthorityParser;->hostEquals(Ljava/lang/String;Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_69

    .line 49
    return-object p2

    .line 46
    :cond_69
    add-int/lit8 v2, v2, 0x1

    goto :goto_54

    .line 54
    :cond_6c
    return-object v0

    .line 19
    :cond_6d
    :goto_6d
    return-object v0
.end method

.method private static isLowiroHost(Ljava/lang/String;)Z
    .locals 1

    .line 58
    invoke-static {p0}, Lmoe/ext/arc/network/UrlAuthorityParser;->normalizeHost(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    .line 59
    const-string v0, "lowiro.com"

    invoke-virtual {p0, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_17

    const-string v0, ".lowiro.com"

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result p0

    if-eqz p0, :cond_15

    goto :goto_17

    :cond_15
    const/4 p0, 0x0

    goto :goto_18

    :cond_17
    :goto_17
    const/4 p0, 0x1

    :goto_18
    return p0
.end method
