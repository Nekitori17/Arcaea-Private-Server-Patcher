.class public final Lmoe/ext/arc/network/DomainUrlRewriter;
.super Ljava/lang/Object;
.source "DomainUrlRewriter.java"


# static fields
.field private static final TAG:Ljava/lang/String; = "ArcExt::UrlRewriter"

.field private static volatile sLoaded:Z

.field private static volatile sRules:Ljava/util/List;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/List<",
            "Lmoe/ext/arc/config/DomainRule;",
            ">;"
        }
    .end annotation
.end field


# direct methods
.method static constructor <clinit>()V
    .locals 1

    .line 17
    const/4 v0, 0x0

    sput-boolean v0, Lmoe/ext/arc/network/DomainUrlRewriter;->sLoaded:Z

    .line 18
    invoke-static {}, Ljava/util/Collections;->emptyList()Ljava/util/List;

    move-result-object v0

    sput-object v0, Lmoe/ext/arc/network/DomainUrlRewriter;->sRules:Ljava/util/List;

    return-void
.end method

.method private constructor <init>()V
    .locals 0

    .line 20
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 21
    return-void
.end method

.method private static ensureLoaded()V
    .locals 2

    .line 94
    sget-boolean v0, Lmoe/ext/arc/network/DomainUrlRewriter;->sLoaded:Z

    if-eqz v0, :cond_5

    .line 95
    return-void

    .line 97
    :cond_5
    const-class v0, Lmoe/ext/arc/network/DomainUrlRewriter;

    monitor-enter v0

    .line 98
    :try_start_8
    sget-boolean v1, Lmoe/ext/arc/network/DomainUrlRewriter;->sLoaded:Z

    if-nez v1, :cond_15

    .line 99
    invoke-static {}, Lmoe/ext/arc/config/DomainConfigLoader;->loadActiveRules()Ljava/util/List;

    move-result-object v1

    sput-object v1, Lmoe/ext/arc/network/DomainUrlRewriter;->sRules:Ljava/util/List;

    .line 100
    const/4 v1, 0x1

    sput-boolean v1, Lmoe/ext/arc/network/DomainUrlRewriter;->sLoaded:Z

    .line 102
    :cond_15
    monitor-exit v0

    .line 103
    return-void

    .line 102
    :catchall_17
    move-exception v1

    monitor-exit v0
    :try_end_19
    .catchall {:try_start_8 .. :try_end_19} :catchall_17

    throw v1
.end method

.method public static rewriteUrl(Ljava/lang/String;)Ljava/lang/String;
    .locals 8

    .line 24
    if-eqz p0, :cond_ef

    invoke-virtual {p0}, Ljava/lang/String;->isEmpty()Z

    move-result v0

    if-eqz v0, :cond_a

    goto/16 :goto_ef

    .line 28
    :cond_a
    const-string v0, "://"

    invoke-virtual {p0, v0}, Ljava/lang/String;->indexOf(Ljava/lang/String;)I

    move-result v0

    .line 29
    const/4 v1, 0x4

    if-eq v0, v1, :cond_17

    const/4 v1, 0x5

    if-eq v0, v1, :cond_17

    .line 30
    return-object p0

    .line 32
    :cond_17
    const/4 v1, 0x0

    invoke-virtual {p0, v1, v0}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v2

    sget-object v3, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    invoke-virtual {v2, v3}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object v2

    .line 33
    const-string v3, "http"

    invoke-virtual {v3, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-nez v3, :cond_33

    const-string v3, "https"

    invoke-virtual {v3, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-nez v2, :cond_33

    .line 34
    return-object p0

    .line 37
    :cond_33
    invoke-static {}, Lmoe/ext/arc/network/DomainUrlRewriter;->ensureLoaded()V

    .line 38
    sget-object v2, Lmoe/ext/arc/network/DomainUrlRewriter;->sRules:Ljava/util/List;

    .line 39
    invoke-interface {v2}, Ljava/util/List;->isEmpty()Z

    move-result v3

    if-eqz v3, :cond_3f

    .line 40
    return-object p0

    .line 43
    :cond_3f
    add-int/lit8 v0, v0, 0x3

    .line 44
    invoke-static {p0, v0}, Lmoe/ext/arc/network/UrlAuthorityParser;->findAuthorityEnd(Ljava/lang/String;I)I

    move-result v3

    .line 45
    if-gt v3, v0, :cond_48

    .line 46
    return-object p0

    .line 49
    :cond_48
    invoke-virtual {p0, v0, v3}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v4

    .line 50
    const/16 v5, 0x40

    invoke-virtual {v4, v5}, Ljava/lang/String;->lastIndexOf(I)I

    move-result v4

    .line 51
    const/4 v5, 0x1

    if-ltz v4, :cond_57

    add-int/2addr v0, v4

    add-int/2addr v0, v5

    .line 52
    :cond_57
    if-lt v0, v3, :cond_5a

    .line 53
    return-object p0

    .line 56
    :cond_5a
    invoke-virtual {p0, v0, v3}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v4

    .line 57
    new-array v5, v5, [I

    .line 58
    invoke-static {v4, v5}, Lmoe/ext/arc/network/UrlAuthorityParser;->parseHostPort(Ljava/lang/String;[I)Ljava/lang/String;

    move-result-object v4

    .line 59
    aget v5, v5, v1

    .line 60
    invoke-virtual {v4}, Ljava/lang/String;->isEmpty()Z

    move-result v6

    if-eqz v6, :cond_6d

    .line 61
    return-object p0

    .line 64
    :cond_6d
    invoke-static {v2, v4, v5}, Lmoe/ext/arc/config/DomainRuleMatcher;->findMatch(Ljava/util/List;Ljava/lang/String;I)Lmoe/ext/arc/config/DomainRule;

    move-result-object v2

    .line 65
    if-nez v2, :cond_74

    .line 66
    return-object p0

    .line 69
    :cond_74
    iget-object v6, v2, Lmoe/ext/arc/config/DomainRule;->replacementHost:Ljava/lang/String;

    .line 70
    iget v7, v2, Lmoe/ext/arc/config/DomainRule;->replacementPort:I

    if-lez v7, :cond_7d

    iget v2, v2, Lmoe/ext/arc/config/DomainRule;->replacementPort:I

    goto :goto_7e

    :cond_7d
    move v2, v5

    .line 72
    :goto_7e
    invoke-static {v4, v6}, Lmoe/ext/arc/network/UrlAuthorityParser;->hostEquals(Ljava/lang/String;Ljava/lang/String;)Z

    move-result v4

    if-eqz v4, :cond_87

    if-ne v5, v2, :cond_87

    .line 73
    return-object p0

    .line 76
    :cond_87
    new-instance v4, Ljava/lang/StringBuilder;

    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v5

    add-int/lit8 v5, v5, 0x20

    invoke-direct {v4, v5}, Ljava/lang/StringBuilder;-><init>(I)V

    .line 77
    invoke-virtual {v4, p0, v1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/CharSequence;II)Ljava/lang/StringBuilder;

    .line 78
    const/16 v0, 0x3a

    invoke-virtual {v6, v0}, Ljava/lang/String;->indexOf(I)I

    move-result v1

    if-ltz v1, :cond_b5

    const-string v1, "["

    invoke-virtual {v6, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v1

    if-nez v1, :cond_b5

    .line 79
    const/16 v1, 0x5b

    invoke-virtual {v4, v1}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    const/16 v5, 0x5d

    invoke-virtual {v1, v5}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    goto :goto_b8

    .line 81
    :cond_b5
    invoke-virtual {v4, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 83
    :goto_b8
    if-lez v2, :cond_c1

    .line 84
    invoke-virtual {v4, v0}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    .line 86
    :cond_c1
    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v0

    invoke-virtual {v4, p0, v3, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/CharSequence;II)Ljava/lang/StringBuilder;

    .line 88
    invoke-virtual {v4}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    .line 89
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "Redirected URL: "

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string v1, " -> "

    invoke-virtual {p0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    const-string v1, "ArcExt::UrlRewriter"

    invoke-static {v1, p0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 90
    return-object v0

    .line 25
    :cond_ef
    :goto_ef
    return-object p0
.end method
