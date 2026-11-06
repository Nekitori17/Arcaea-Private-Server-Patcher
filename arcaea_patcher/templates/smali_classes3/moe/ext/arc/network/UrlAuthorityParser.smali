.class public final Lmoe/ext/arc/network/UrlAuthorityParser;
.super Ljava/lang/Object;
.source "UrlAuthorityParser.java"


# direct methods
.method private constructor <init>()V
    .locals 0

    .line 10
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 11
    return-void
.end method

.method public static findAuthorityEnd(Ljava/lang/String;I)I
    .locals 3

    .line 14
    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v0

    .line 15
    nop

    :goto_5
    if-ge p1, v0, :cond_1c

    .line 16
    invoke-virtual {p0, p1}, Ljava/lang/String;->charAt(I)C

    move-result v1

    .line 17
    const/16 v2, 0x2f

    if-eq v1, v2, :cond_1b

    const/16 v2, 0x3f

    if-eq v1, v2, :cond_1b

    const/16 v2, 0x23

    if-ne v1, v2, :cond_18

    goto :goto_1b

    .line 15
    :cond_18
    add-int/lit8 p1, p1, 0x1

    goto :goto_5

    .line 18
    :cond_1b
    :goto_1b
    return p1

    .line 21
    :cond_1c
    return v0
.end method

.method public static hostEquals(Ljava/lang/String;Ljava/lang/String;)Z
    .locals 0

    .line 50
    invoke-static {p0}, Lmoe/ext/arc/network/UrlAuthorityParser;->normalizeHost(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    invoke-static {p1}, Lmoe/ext/arc/network/UrlAuthorityParser;->normalizeHost(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p1

    invoke-virtual {p0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    return p0
.end method

.method public static normalizeHost(Ljava/lang/String;)Ljava/lang/String;
    .locals 3

    .line 39
    if-nez p0, :cond_5

    .line 40
    const-string p0, ""

    return-object p0

    .line 42
    :cond_5
    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v0

    .line 43
    :goto_9
    if-lez v0, :cond_18

    add-int/lit8 v1, v0, -0x1

    invoke-virtual {p0, v1}, Ljava/lang/String;->charAt(I)C

    move-result v1

    const/16 v2, 0x2e

    if-ne v1, v2, :cond_18

    .line 44
    add-int/lit8 v0, v0, -0x1

    goto :goto_9

    .line 46
    :cond_18
    const/4 v1, 0x0

    invoke-virtual {p0, v1, v0}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p0

    sget-object v0, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    invoke-virtual {p0, v0}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object p0

    return-object p0
.end method

.method public static parseHostPort(Ljava/lang/String;[I)Ljava/lang/String;
    .locals 7

    .line 54
    const/4 v0, 0x0

    aput v0, p1, v0

    .line 55
    if-eqz p0, :cond_63

    invoke-virtual {p0}, Ljava/lang/String;->isEmpty()Z

    move-result v1

    if-eqz v1, :cond_c

    goto :goto_63

    .line 58
    :cond_c
    invoke-virtual {p0, v0}, Ljava/lang/String;->charAt(I)C

    move-result v1

    const/16 v2, 0x5b

    const/16 v3, 0x3a

    if-ne v1, v2, :cond_3d

    .line 59
    const/16 v1, 0x5d

    invoke-virtual {p0, v1}, Ljava/lang/String;->indexOf(I)I

    move-result v1

    .line 60
    if-lez v1, :cond_3d

    .line 61
    const/4 v2, 0x1

    invoke-virtual {p0, v2, v1}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v4

    .line 62
    add-int/lit8 v5, v1, 0x2

    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v6

    if-gt v5, v6, :cond_3c

    add-int/2addr v1, v2

    invoke-virtual {p0, v1}, Ljava/lang/String;->charAt(I)C

    move-result v1

    if-ne v1, v3, :cond_3c

    .line 63
    invoke-virtual {p0, v5}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object p0

    invoke-static {p0}, Lmoe/ext/arc/network/UrlAuthorityParser;->parsePort(Ljava/lang/String;)I

    move-result p0

    aput p0, p1, v0

    .line 65
    :cond_3c
    return-object v4

    .line 68
    :cond_3d
    invoke-virtual {p0, v3}, Ljava/lang/String;->indexOf(I)I

    move-result v1

    .line 69
    invoke-virtual {p0, v3}, Ljava/lang/String;->lastIndexOf(I)I

    move-result v2

    .line 70
    if-lez v1, :cond_62

    if-ne v1, v2, :cond_62

    add-int/lit8 v1, v2, 0x1

    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v3

    if-ge v1, v3, :cond_62

    .line 71
    invoke-virtual {p0, v1}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v1

    invoke-static {v1}, Lmoe/ext/arc/network/UrlAuthorityParser;->parsePort(Ljava/lang/String;)I

    move-result v1

    .line 72
    if-lez v1, :cond_62

    .line 73
    aput v1, p1, v0

    .line 74
    invoke-virtual {p0, v0, v2}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p0

    return-object p0

    .line 77
    :cond_62
    return-object p0

    .line 56
    :cond_63
    :goto_63
    const-string p0, ""

    return-object p0
.end method

.method public static parsePort(Ljava/lang/String;)I
    .locals 2

    .line 82
    const/4 v0, 0x0

    :try_start_1
    invoke-virtual {p0}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object p0

    invoke-static {p0}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I

    move-result p0
    :try_end_9
    .catch Ljava/lang/NumberFormatException; {:try_start_1 .. :try_end_9} :catch_12

    .line 83
    if-lez p0, :cond_11

    const v1, 0xffff

    if-gt p0, v1, :cond_11

    move v0, p0

    :cond_11
    return v0

    .line 84
    :catch_12
    move-exception p0

    .line 85
    return v0
.end method

.method public static sanitize(Ljava/lang/String;)Ljava/lang/String;
    .locals 4

    .line 25
    if-nez p0, :cond_5

    .line 26
    const-string p0, ""

    return-object p0

    .line 28
    :cond_5
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v1

    invoke-direct {v0, v1}, Ljava/lang/StringBuilder;-><init>(I)V

    .line 29
    const/4 v1, 0x0

    :goto_f
    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v2

    if-ge v1, v2, :cond_27

    .line 30
    invoke-virtual {p0, v1}, Ljava/lang/String;->charAt(I)C

    move-result v2

    .line 31
    const/16 v3, 0x20

    if-lt v2, v3, :cond_24

    const/16 v3, 0x22

    if-eq v2, v3, :cond_24

    .line 32
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    .line 29
    :cond_24
    add-int/lit8 v1, v1, 0x1

    goto :goto_f

    .line 35
    :cond_27
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    return-object p0
.end method
