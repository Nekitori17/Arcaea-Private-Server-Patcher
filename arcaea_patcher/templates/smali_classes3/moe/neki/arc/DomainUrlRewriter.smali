.class public final Lmoe/neki/arc/DomainUrlRewriter;
.super Ljava/lang/Object;
.source "DomainUrlRewriter.java"


# static fields
.field private static final CONFIG_FILENAME:Ljava/lang/String; = "domain.cfg"

.field private static final DEFAULT_PACKAGES:[Ljava/lang/String;

.field private static final LOWIRO_DOMAIN:Ljava/lang/String; = "lowiro.com"

.field private static final LOWIRO_SUFFIX:Ljava/lang/String; = ".lowiro.com"

.field private static final TAG:Ljava/lang/String; = "DomainUrlRewriter"

.field private static volatile sLoaded:Z

.field private static sOrigHosts:[Ljava/lang/String;

.field private static sOrigPorts:[I

.field private static sReplHosts:[Ljava/lang/String;

.field private static sReplPorts:[I


# direct methods
.method static constructor <clinit>()V
    .locals 2

    .line 23
    const-string v0, "moe.neki.arc"

    const-string v1, "moe.low.arc"

    filled-new-array {v0, v1}, [Ljava/lang/String;

    move-result-object v0

    sput-object v0, Lmoe/neki/arc/DomainUrlRewriter;->DEFAULT_PACKAGES:[Ljava/lang/String;

    .line 28
    const/4 v0, 0x0

    sput-boolean v0, Lmoe/neki/arc/DomainUrlRewriter;->sLoaded:Z

    .line 29
    new-array v1, v0, [Ljava/lang/String;

    sput-object v1, Lmoe/neki/arc/DomainUrlRewriter;->sOrigHosts:[Ljava/lang/String;

    .line 30
    new-array v1, v0, [I

    sput-object v1, Lmoe/neki/arc/DomainUrlRewriter;->sOrigPorts:[I

    .line 31
    new-array v1, v0, [Ljava/lang/String;

    sput-object v1, Lmoe/neki/arc/DomainUrlRewriter;->sReplHosts:[Ljava/lang/String;

    .line 32
    new-array v0, v0, [I

    sput-object v0, Lmoe/neki/arc/DomainUrlRewriter;->sReplPorts:[I

    return-void
.end method

.method private constructor <init>()V
    .locals 0

    .line 34
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 35
    return-void
.end method

.method private static ensureLoaded()V
    .locals 2

    .line 112
    sget-boolean v0, Lmoe/neki/arc/DomainUrlRewriter;->sLoaded:Z

    if-eqz v0, :cond_5

    .line 113
    return-void

    .line 115
    :cond_5
    const-class v0, Lmoe/neki/arc/DomainUrlRewriter;

    monitor-enter v0

    .line 116
    :try_start_8
    sget-boolean v1, Lmoe/neki/arc/DomainUrlRewriter;->sLoaded:Z

    if-nez v1, :cond_18

    .line 117
    invoke-static {}, Lmoe/neki/arc/DomainUrlRewriter;->resolveConfigFile()Ljava/io/File;

    move-result-object v1

    .line 118
    if-eqz v1, :cond_15

    .line 119
    invoke-static {v1}, Lmoe/neki/arc/DomainUrlRewriter;->parseConfigFile(Ljava/io/File;)V

    .line 121
    :cond_15
    const/4 v1, 0x1

    sput-boolean v1, Lmoe/neki/arc/DomainUrlRewriter;->sLoaded:Z

    .line 123
    :cond_18
    monitor-exit v0

    .line 124
    return-void

    .line 123
    :catchall_1a
    move-exception v1

    monitor-exit v0
    :try_end_1c
    .catchall {:try_start_8 .. :try_end_1c} :catchall_1a

    throw v1
.end method

.method private static findAuthorityEnd(Ljava/lang/String;I)I
    .locals 3

    .line 257
    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v0

    .line 258
    nop

    :goto_5
    if-ge p1, v0, :cond_1c

    .line 259
    invoke-virtual {p0, p1}, Ljava/lang/String;->charAt(I)C

    move-result v1

    .line 260
    const/16 v2, 0x2f

    if-eq v1, v2, :cond_1b

    const/16 v2, 0x3f

    if-eq v1, v2, :cond_1b

    const/16 v2, 0x23

    if-ne v1, v2, :cond_18

    goto :goto_1b

    .line 258
    :cond_18
    add-int/lit8 p1, p1, 0x1

    goto :goto_5

    .line 261
    :cond_1b
    :goto_1b
    return p1

    .line 264
    :cond_1c
    return v0
.end method

.method private static findMatchingRule(Ljava/lang/String;I)I
    .locals 4

    .line 127
    sget-object v0, Lmoe/neki/arc/DomainUrlRewriter;->sOrigHosts:[Ljava/lang/String;

    array-length v0, v0

    .line 130
    const/4 v1, 0x0

    const/4 v2, 0x0

    :goto_5
    if-ge v2, v0, :cond_1f

    .line 131
    sget-object v3, Lmoe/neki/arc/DomainUrlRewriter;->sOrigHosts:[Ljava/lang/String;

    aget-object v3, v3, v2

    invoke-static {v3, p0}, Lmoe/neki/arc/DomainUrlRewriter;->hostEquals(Ljava/lang/String;Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_1c

    .line 132
    sget-object v3, Lmoe/neki/arc/DomainUrlRewriter;->sOrigPorts:[I

    aget v3, v3, v2

    .line 133
    if-eqz v3, :cond_1b

    if-eqz p1, :cond_1b

    if-ne v3, p1, :cond_1c

    .line 134
    :cond_1b
    return v2

    .line 130
    :cond_1c
    add-int/lit8 v2, v2, 0x1

    goto :goto_5

    .line 140
    :cond_1f
    invoke-static {p0}, Lmoe/neki/arc/DomainUrlRewriter;->isLowiroHost(Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :cond_36

    .line 141
    const/4 v2, 0x0

    :goto_26
    if-ge v2, v0, :cond_36

    .line 142
    sget-object v3, Lmoe/neki/arc/DomainUrlRewriter;->sOrigHosts:[Ljava/lang/String;

    aget-object v3, v3, v2

    invoke-static {v3}, Lmoe/neki/arc/DomainUrlRewriter;->isLowiroHost(Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_33

    .line 143
    return v2

    .line 141
    :cond_33
    add-int/lit8 v2, v2, 0x1

    goto :goto_26

    .line 149
    :cond_36
    if-nez p1, :cond_4f

    .line 150
    nop

    :goto_39
    if-ge v1, v0, :cond_4f

    .line 151
    sget-object p1, Lmoe/neki/arc/DomainUrlRewriter;->sReplPorts:[I

    aget p1, p1, v1

    if-lez p1, :cond_4c

    sget-object p1, Lmoe/neki/arc/DomainUrlRewriter;->sReplHosts:[Ljava/lang/String;

    aget-object p1, p1, v1

    invoke-static {p1, p0}, Lmoe/neki/arc/DomainUrlRewriter;->hostEquals(Ljava/lang/String;Ljava/lang/String;)Z

    move-result p1

    if-eqz p1, :cond_4c

    .line 152
    return v1

    .line 150
    :cond_4c
    add-int/lit8 v1, v1, 0x1

    goto :goto_39

    .line 157
    :cond_4f
    const/4 p0, -0x1

    return p0
.end method

.method private static hostEquals(Ljava/lang/String;Ljava/lang/String;)Z
    .locals 0

    .line 290
    invoke-static {p0}, Lmoe/neki/arc/DomainUrlRewriter;->normalizeHost(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    invoke-static {p1}, Lmoe/neki/arc/DomainUrlRewriter;->normalizeHost(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p1

    invoke-virtual {p0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    return p0
.end method

.method private static isLowiroHost(Ljava/lang/String;)Z
    .locals 1

    .line 294
    invoke-static {p0}, Lmoe/neki/arc/DomainUrlRewriter;->normalizeHost(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    .line 295
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

.method private static normalizeHost(Ljava/lang/String;)Ljava/lang/String;
    .locals 3

    .line 279
    if-nez p0, :cond_5

    .line 280
    const-string p0, ""

    return-object p0

    .line 282
    :cond_5
    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v0

    .line 283
    :goto_9
    if-lez v0, :cond_18

    add-int/lit8 v1, v0, -0x1

    invoke-virtual {p0, v1}, Ljava/lang/String;->charAt(I)C

    move-result v1

    const/16 v2, 0x2e

    if-ne v1, v2, :cond_18

    .line 284
    add-int/lit8 v0, v0, -0x1

    goto :goto_9

    .line 286
    :cond_18
    const/4 v1, 0x0

    invoke-virtual {p0, v1, v0}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p0

    sget-object v0, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    invoke-virtual {p0, v0}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object p0

    return-object p0
.end method

.method private static parseConfigFile(Ljava/io/File;)V
    .locals 13

    .line 161
    const-string v0, "DomainUrlRewriter"

    new-instance v1, Ljava/util/ArrayList;

    invoke-direct {v1}, Ljava/util/ArrayList;-><init>()V

    .line 162
    new-instance v2, Ljava/util/ArrayList;

    invoke-direct {v2}, Ljava/util/ArrayList;-><init>()V

    .line 163
    new-instance v3, Ljava/util/ArrayList;

    invoke-direct {v3}, Ljava/util/ArrayList;-><init>()V

    .line 164
    new-instance v4, Ljava/util/ArrayList;

    invoke-direct {v4}, Ljava/util/ArrayList;-><init>()V

    .line 165
    const/4 v5, 0x1

    new-array v6, v5, [I

    .line 167
    :try_start_19
    new-instance v7, Ljava/io/BufferedReader;

    new-instance v8, Ljava/io/FileReader;

    invoke-direct {v8, p0}, Ljava/io/FileReader;-><init>(Ljava/io/File;)V

    invoke-direct {v7, v8}, Ljava/io/BufferedReader;-><init>(Ljava/io/Reader;)V
    :try_end_23
    .catch Ljava/lang/Exception; {:try_start_19 .. :try_end_23} :catch_111

    .line 169
    :cond_23
    :goto_23
    :try_start_23
    invoke-virtual {v7}, Ljava/io/BufferedReader;->readLine()Ljava/lang/String;

    move-result-object v8

    const/4 v9, 0x0

    if-eqz v8, :cond_9d

    .line 170
    invoke-static {v8}, Lmoe/neki/arc/DomainUrlRewriter;->sanitize(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v8

    invoke-virtual {v8}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v8

    .line 171
    invoke-virtual {v8}, Ljava/lang/String;->isEmpty()Z

    move-result v10

    if-nez v10, :cond_23

    const-string v10, "#"

    invoke-virtual {v8, v10}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v10

    if-eqz v10, :cond_41

    .line 172
    goto :goto_23

    .line 174
    :cond_41
    const/16 v10, 0x3d

    invoke-virtual {v8, v10}, Ljava/lang/String;->indexOf(I)I

    move-result v10

    .line 175
    if-lez v10, :cond_23

    invoke-virtual {v8}, Ljava/lang/String;->length()I

    move-result v11

    sub-int/2addr v11, v5

    if-ne v10, v11, :cond_51

    .line 176
    goto :goto_23

    .line 178
    :cond_51
    invoke-virtual {v8, v9, v10}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v11

    invoke-virtual {v11}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v11

    .line 179
    add-int/lit8 v10, v10, 0x1

    invoke-virtual {v8, v10}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v8

    invoke-virtual {v8}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v8

    .line 180
    invoke-virtual {v11}, Ljava/lang/String;->isEmpty()Z

    move-result v10

    if-nez v10, :cond_23

    invoke-virtual {v8}, Ljava/lang/String;->isEmpty()Z

    move-result v10

    if-eqz v10, :cond_70

    .line 181
    goto :goto_23

    .line 183
    :cond_70
    invoke-static {v11, v6}, Lmoe/neki/arc/DomainUrlRewriter;->parseHostPort(Ljava/lang/String;[I)Ljava/lang/String;

    move-result-object v10

    .line 184
    aget v11, v6, v9

    .line 185
    invoke-static {v8, v6}, Lmoe/neki/arc/DomainUrlRewriter;->parseHostPort(Ljava/lang/String;[I)Ljava/lang/String;

    move-result-object v8

    .line 186
    aget v9, v6, v9

    .line 187
    invoke-virtual {v10}, Ljava/lang/String;->isEmpty()Z

    move-result v12

    if-nez v12, :cond_9c

    invoke-virtual {v8}, Ljava/lang/String;->isEmpty()Z

    move-result v12

    if-nez v12, :cond_9c

    .line 188
    invoke-interface {v1, v10}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 189
    invoke-static {v11}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v10

    invoke-interface {v2, v10}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 190
    invoke-interface {v3, v8}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 191
    invoke-static {v9}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v8

    invoke-interface {v4, v8}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 193
    :cond_9c
    goto :goto_23

    .line 194
    :cond_9d
    invoke-interface {v1}, Ljava/util/List;->size()I

    move-result v5

    .line 195
    new-array v6, v5, [Ljava/lang/String;

    .line 196
    new-array v8, v5, [I

    .line 197
    new-array v10, v5, [Ljava/lang/String;

    .line 198
    new-array v11, v5, [I

    .line 199
    nop

    :goto_aa
    if-ge v9, v5, :cond_d7

    .line 200
    invoke-interface {v1, v9}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v12

    check-cast v12, Ljava/lang/String;

    aput-object v12, v6, v9

    .line 201
    invoke-interface {v2, v9}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v12

    check-cast v12, Ljava/lang/Integer;

    invoke-virtual {v12}, Ljava/lang/Integer;->intValue()I

    move-result v12

    aput v12, v8, v9

    .line 202
    invoke-interface {v3, v9}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v12

    check-cast v12, Ljava/lang/String;

    aput-object v12, v10, v9

    .line 203
    invoke-interface {v4, v9}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v12

    check-cast v12, Ljava/lang/Integer;

    invoke-virtual {v12}, Ljava/lang/Integer;->intValue()I

    move-result v12

    aput v12, v11, v9

    .line 199
    add-int/lit8 v9, v9, 0x1

    goto :goto_aa

    .line 205
    :cond_d7
    sput-object v6, Lmoe/neki/arc/DomainUrlRewriter;->sOrigHosts:[Ljava/lang/String;

    .line 206
    sput-object v8, Lmoe/neki/arc/DomainUrlRewriter;->sOrigPorts:[I

    .line 207
    sput-object v10, Lmoe/neki/arc/DomainUrlRewriter;->sReplHosts:[Ljava/lang/String;

    .line 208
    sput-object v11, Lmoe/neki/arc/DomainUrlRewriter;->sReplPorts:[I

    .line 209
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "Loaded "

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, v5}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v2, " URL rewrite rule(s) from "

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {p0}, Ljava/io/File;->getAbsolutePath()Ljava/lang/String;

    move-result-object p0

    invoke-virtual {v1, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    invoke-static {v0, p0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_103
    .catchall {:try_start_23 .. :try_end_103} :catchall_107

    .line 210
    :try_start_103
    invoke-virtual {v7}, Ljava/io/BufferedReader;->close()V
    :try_end_106
    .catch Ljava/lang/Exception; {:try_start_103 .. :try_end_106} :catch_111

    .line 212
    goto :goto_12c

    .line 167
    :catchall_107
    move-exception p0

    :try_start_108
    invoke-virtual {v7}, Ljava/io/BufferedReader;->close()V
    :try_end_10b
    .catchall {:try_start_108 .. :try_end_10b} :catchall_10c

    goto :goto_110

    :catchall_10c
    move-exception v1

    :try_start_10d
    invoke-virtual {p0, v1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_110
    throw p0
    :try_end_111
    .catch Ljava/lang/Exception; {:try_start_10d .. :try_end_111} :catch_111

    .line 210
    :catch_111
    move-exception p0

    .line 211
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "Failed to read domain.cfg: "

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {p0}, Ljava/lang/Exception;->getMessage()Ljava/lang/String;

    move-result-object p0

    invoke-virtual {v1, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    invoke-static {v0, p0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 213
    :goto_12c
    return-void
.end method

.method private static parseHostPort(Ljava/lang/String;[I)Ljava/lang/String;
    .locals 7

    .line 299
    const/4 v0, 0x0

    aput v0, p1, v0

    .line 300
    if-eqz p0, :cond_63

    invoke-virtual {p0}, Ljava/lang/String;->isEmpty()Z

    move-result v1

    if-eqz v1, :cond_c

    goto :goto_63

    .line 303
    :cond_c
    invoke-virtual {p0, v0}, Ljava/lang/String;->charAt(I)C

    move-result v1

    const/16 v2, 0x5b

    const/16 v3, 0x3a

    if-ne v1, v2, :cond_3d

    .line 304
    const/16 v1, 0x5d

    invoke-virtual {p0, v1}, Ljava/lang/String;->indexOf(I)I

    move-result v1

    .line 305
    if-lez v1, :cond_3d

    .line 306
    const/4 v2, 0x1

    invoke-virtual {p0, v2, v1}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v4

    .line 307
    add-int/lit8 v5, v1, 0x2

    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v6

    if-gt v5, v6, :cond_3c

    add-int/2addr v1, v2

    invoke-virtual {p0, v1}, Ljava/lang/String;->charAt(I)C

    move-result v1

    if-ne v1, v3, :cond_3c

    .line 308
    invoke-virtual {p0, v5}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object p0

    invoke-static {p0}, Lmoe/neki/arc/DomainUrlRewriter;->parsePort(Ljava/lang/String;)I

    move-result p0

    aput p0, p1, v0

    .line 310
    :cond_3c
    return-object v4

    .line 313
    :cond_3d
    invoke-virtual {p0, v3}, Ljava/lang/String;->indexOf(I)I

    move-result v1

    .line 314
    invoke-virtual {p0, v3}, Ljava/lang/String;->lastIndexOf(I)I

    move-result v2

    .line 315
    if-lez v1, :cond_62

    if-ne v1, v2, :cond_62

    add-int/lit8 v1, v2, 0x1

    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v3

    if-ge v1, v3, :cond_62

    .line 316
    invoke-virtual {p0, v1}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v1

    invoke-static {v1}, Lmoe/neki/arc/DomainUrlRewriter;->parsePort(Ljava/lang/String;)I

    move-result v1

    .line 317
    if-lez v1, :cond_62

    .line 318
    aput v1, p1, v0

    .line 319
    invoke-virtual {p0, v0, v2}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p0

    return-object p0

    .line 322
    :cond_62
    return-object p0

    .line 301
    :cond_63
    :goto_63
    const-string p0, ""

    return-object p0
.end method

.method private static parsePort(Ljava/lang/String;)I
    .locals 2

    .line 327
    const/4 v0, 0x0

    :try_start_1
    invoke-virtual {p0}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object p0

    invoke-static {p0}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I

    move-result p0
    :try_end_9
    .catch Ljava/lang/NumberFormatException; {:try_start_1 .. :try_end_9} :catch_12

    .line 328
    if-lez p0, :cond_11

    const v1, 0xffff

    if-gt p0, v1, :cond_11

    move v0, p0

    :cond_11
    return v0

    .line 329
    :catch_12
    move-exception p0

    .line 330
    return v0
.end method

.method private static readProcCmdline()Ljava/lang/String;
    .locals 5

    .line 242
    :try_start_0
    new-instance v0, Ljava/io/FileInputStream;

    const-string v1, "/proc/self/cmdline"

    invoke-direct {v0, v1}, Ljava/io/FileInputStream;-><init>(Ljava/lang/String;)V
    :try_end_7
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_7} :catch_53

    .line 243
    :try_start_7
    new-instance v1, Ljava/io/InputStreamReader;

    sget-object v2, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-direct {v1, v0, v2}, Ljava/io/InputStreamReader;-><init>(Ljava/io/InputStream;Ljava/nio/charset/Charset;)V
    :try_end_e
    .catchall {:try_start_7 .. :try_end_e} :catchall_49

    .line 244
    :try_start_e
    new-instance v2, Ljava/io/BufferedReader;

    invoke-direct {v2, v1}, Ljava/io/BufferedReader;-><init>(Ljava/io/Reader;)V
    :try_end_13
    .catchall {:try_start_e .. :try_end_13} :catchall_3f

    .line 245
    :try_start_13
    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    .line 247
    :goto_18
    invoke-virtual {v2}, Ljava/io/BufferedReader;->read()I

    move-result v4

    if-lez v4, :cond_23

    .line 248
    int-to-char v4, v4

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    goto :goto_18

    .line 250
    :cond_23
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    invoke-virtual {v3}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v3
    :try_end_2b
    .catchall {:try_start_13 .. :try_end_2b} :catchall_35

    .line 251
    :try_start_2b
    invoke-virtual {v2}, Ljava/io/BufferedReader;->close()V
    :try_end_2e
    .catchall {:try_start_2b .. :try_end_2e} :catchall_3f

    :try_start_2e
    invoke-virtual {v1}, Ljava/io/InputStreamReader;->close()V
    :try_end_31
    .catchall {:try_start_2e .. :try_end_31} :catchall_49

    :try_start_31
    invoke-virtual {v0}, Ljava/io/FileInputStream;->close()V
    :try_end_34
    .catch Ljava/lang/Exception; {:try_start_31 .. :try_end_34} :catch_53

    .line 250
    return-object v3

    .line 242
    :catchall_35
    move-exception v3

    :try_start_36
    invoke-virtual {v2}, Ljava/io/BufferedReader;->close()V
    :try_end_39
    .catchall {:try_start_36 .. :try_end_39} :catchall_3a

    goto :goto_3e

    :catchall_3a
    move-exception v2

    :try_start_3b
    invoke-virtual {v3, v2}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_3e
    throw v3
    :try_end_3f
    .catchall {:try_start_3b .. :try_end_3f} :catchall_3f

    :catchall_3f
    move-exception v2

    :try_start_40
    invoke-virtual {v1}, Ljava/io/InputStreamReader;->close()V
    :try_end_43
    .catchall {:try_start_40 .. :try_end_43} :catchall_44

    goto :goto_48

    :catchall_44
    move-exception v1

    :try_start_45
    invoke-virtual {v2, v1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_48
    throw v2
    :try_end_49
    .catchall {:try_start_45 .. :try_end_49} :catchall_49

    :catchall_49
    move-exception v1

    :try_start_4a
    invoke-virtual {v0}, Ljava/io/FileInputStream;->close()V
    :try_end_4d
    .catchall {:try_start_4a .. :try_end_4d} :catchall_4e

    goto :goto_52

    :catchall_4e
    move-exception v0

    :try_start_4f
    invoke-virtual {v1, v0}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_52
    throw v1
    :try_end_53
    .catch Ljava/lang/Exception; {:try_start_4f .. :try_end_53} :catch_53

    .line 251
    :catch_53
    move-exception v0

    .line 252
    const/4 v0, 0x0

    return-object v0
.end method

.method private static resolveConfigFile()Ljava/io/File;
    .locals 8

    .line 216
    new-instance v0, Ljava/util/ArrayList;

    invoke-direct {v0}, Ljava/util/ArrayList;-><init>()V

    .line 217
    invoke-static {}, Lmoe/neki/arc/DomainUrlRewriter;->readProcCmdline()Ljava/lang/String;

    move-result-object v1

    .line 218
    if-eqz v1, :cond_14

    invoke-virtual {v1}, Ljava/lang/String;->isEmpty()Z

    move-result v2

    if-nez v2, :cond_14

    .line 219
    invoke-interface {v0, v1}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 221
    :cond_14
    sget-object v1, Lmoe/neki/arc/DomainUrlRewriter;->DEFAULT_PACKAGES:[Ljava/lang/String;

    array-length v2, v1

    const/4 v3, 0x0

    const/4 v4, 0x0

    :goto_19
    if-ge v4, v2, :cond_29

    aget-object v5, v1, v4

    .line 222
    invoke-interface {v0, v5}, Ljava/util/List;->contains(Ljava/lang/Object;)Z

    move-result v6

    if-nez v6, :cond_26

    .line 223
    invoke-interface {v0, v5}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 221
    :cond_26
    add-int/lit8 v4, v4, 0x1

    goto :goto_19

    .line 227
    :cond_29
    nop

    :goto_2a
    invoke-interface {v0}, Ljava/util/List;->size()I

    move-result v1

    if-ge v3, v1, :cond_97

    .line 228
    invoke-interface {v0, v3}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Ljava/lang/String;

    .line 229
    new-instance v2, Ljava/io/File;

    new-instance v4, Ljava/lang/StringBuilder;

    invoke-direct {v4}, Ljava/lang/StringBuilder;-><init>()V

    const-string v5, "/data/user/0/"

    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    const-string v5, "/files/"

    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    const-string v6, "domain.cfg"

    invoke-virtual {v4, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v4

    invoke-direct {v2, v4}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    .line 230
    invoke-virtual {v2}, Ljava/io/File;->isFile()Z

    move-result v4

    if-eqz v4, :cond_67

    invoke-virtual {v2}, Ljava/io/File;->canRead()Z

    move-result v4

    if-eqz v4, :cond_67

    .line 231
    return-object v2

    .line 233
    :cond_67
    new-instance v2, Ljava/io/File;

    new-instance v4, Ljava/lang/StringBuilder;

    invoke-direct {v4}, Ljava/lang/StringBuilder;-><init>()V

    const-string v7, "/data/data/"

    invoke-virtual {v4, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-direct {v2, v1}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    .line 234
    invoke-virtual {v2}, Ljava/io/File;->isFile()Z

    move-result v1

    if-eqz v1, :cond_94

    invoke-virtual {v2}, Ljava/io/File;->canRead()Z

    move-result v1

    if-eqz v1, :cond_94

    .line 235
    return-object v2

    .line 227
    :cond_94
    add-int/lit8 v3, v3, 0x1

    goto :goto_2a

    .line 238
    :cond_97
    const/4 v0, 0x0

    return-object v0
.end method

.method public static rewriteUrl(Ljava/lang/String;)Ljava/lang/String;
    .locals 8

    .line 42
    if-eqz p0, :cond_ee

    invoke-virtual {p0}, Ljava/lang/String;->isEmpty()Z

    move-result v0

    if-eqz v0, :cond_a

    goto/16 :goto_ee

    .line 46
    :cond_a
    const-string v0, "://"

    invoke-virtual {p0, v0}, Ljava/lang/String;->indexOf(Ljava/lang/String;)I

    move-result v0

    .line 47
    const/4 v1, 0x4

    if-eq v0, v1, :cond_17

    const/4 v1, 0x5

    if-eq v0, v1, :cond_17

    .line 48
    return-object p0

    .line 50
    :cond_17
    const/4 v1, 0x0

    invoke-virtual {p0, v1, v0}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v2

    sget-object v3, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    invoke-virtual {v2, v3}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object v2

    .line 51
    const-string v3, "http"

    invoke-virtual {v3, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-nez v3, :cond_33

    const-string v3, "https"

    invoke-virtual {v3, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-nez v2, :cond_33

    .line 52
    return-object p0

    .line 55
    :cond_33
    invoke-static {}, Lmoe/neki/arc/DomainUrlRewriter;->ensureLoaded()V

    .line 56
    sget-object v2, Lmoe/neki/arc/DomainUrlRewriter;->sOrigHosts:[Ljava/lang/String;

    array-length v2, v2

    if-nez v2, :cond_3c

    .line 57
    return-object p0

    .line 60
    :cond_3c
    add-int/lit8 v0, v0, 0x3

    .line 61
    invoke-static {p0, v0}, Lmoe/neki/arc/DomainUrlRewriter;->findAuthorityEnd(Ljava/lang/String;I)I

    move-result v2

    .line 62
    if-gt v2, v0, :cond_45

    .line 63
    return-object p0

    .line 66
    :cond_45
    invoke-virtual {p0, v0, v2}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v3

    .line 67
    const/16 v4, 0x40

    invoke-virtual {v3, v4}, Ljava/lang/String;->lastIndexOf(I)I

    move-result v3

    .line 68
    const/4 v4, 0x1

    if-ltz v3, :cond_54

    add-int/2addr v0, v3

    add-int/2addr v0, v4

    .line 69
    :cond_54
    if-lt v0, v2, :cond_57

    .line 70
    return-object p0

    .line 73
    :cond_57
    invoke-virtual {p0, v0, v2}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v3

    .line 74
    new-array v4, v4, [I

    .line 75
    invoke-static {v3, v4}, Lmoe/neki/arc/DomainUrlRewriter;->parseHostPort(Ljava/lang/String;[I)Ljava/lang/String;

    move-result-object v3

    .line 76
    aget v4, v4, v1

    .line 77
    invoke-virtual {v3}, Ljava/lang/String;->isEmpty()Z

    move-result v5

    if-eqz v5, :cond_6a

    .line 78
    return-object p0

    .line 81
    :cond_6a
    invoke-static {v3, v4}, Lmoe/neki/arc/DomainUrlRewriter;->findMatchingRule(Ljava/lang/String;I)I

    move-result v5

    .line 82
    if-gez v5, :cond_71

    .line 83
    return-object p0

    .line 86
    :cond_71
    sget-object v6, Lmoe/neki/arc/DomainUrlRewriter;->sReplHosts:[Ljava/lang/String;

    aget-object v6, v6, v5

    .line 87
    sget-object v7, Lmoe/neki/arc/DomainUrlRewriter;->sReplPorts:[I

    aget v5, v7, v5

    .line 88
    if-lez v5, :cond_7c

    goto :goto_7d

    :cond_7c
    move v5, v4

    .line 90
    :goto_7d
    invoke-static {v3, v6}, Lmoe/neki/arc/DomainUrlRewriter;->hostEquals(Ljava/lang/String;Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_86

    if-ne v4, v5, :cond_86

    .line 91
    return-object p0

    .line 94
    :cond_86
    new-instance v3, Ljava/lang/StringBuilder;

    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v4

    add-int/lit8 v4, v4, 0x20

    invoke-direct {v3, v4}, Ljava/lang/StringBuilder;-><init>(I)V

    .line 95
    invoke-virtual {v3, p0, v1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/CharSequence;II)Ljava/lang/StringBuilder;

    .line 96
    const/16 v0, 0x3a

    invoke-virtual {v6, v0}, Ljava/lang/String;->indexOf(I)I

    move-result v1

    if-ltz v1, :cond_b4

    const-string v1, "["

    invoke-virtual {v6, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v1

    if-nez v1, :cond_b4

    .line 97
    const/16 v1, 0x5b

    invoke-virtual {v3, v1}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    const/16 v4, 0x5d

    invoke-virtual {v1, v4}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    goto :goto_b7

    .line 99
    :cond_b4
    invoke-virtual {v3, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 101
    :goto_b7
    if-lez v5, :cond_c0

    .line 102
    invoke-virtual {v3, v0}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, v5}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    .line 104
    :cond_c0
    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v0

    invoke-virtual {v3, p0, v2, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/CharSequence;II)Ljava/lang/StringBuilder;

    .line 106
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    .line 107
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

    const-string v1, "DomainUrlRewriter"

    invoke-static {v1, p0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 108
    return-object v0

    .line 43
    :cond_ee
    :goto_ee
    return-object p0
.end method

.method private static sanitize(Ljava/lang/String;)Ljava/lang/String;
    .locals 4

    .line 268
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v1

    invoke-direct {v0, v1}, Ljava/lang/StringBuilder;-><init>(I)V

    .line 269
    const/4 v1, 0x0

    :goto_a
    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v2

    if-ge v1, v2, :cond_22

    .line 270
    invoke-virtual {p0, v1}, Ljava/lang/String;->charAt(I)C

    move-result v2

    .line 271
    const/16 v3, 0x20

    if-lt v2, v3, :cond_1f

    const/16 v3, 0x22

    if-eq v2, v3, :cond_1f

    .line 272
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    .line 269
    :cond_1f
    add-int/lit8 v1, v1, 0x1

    goto :goto_a

    .line 275
    :cond_22
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    return-object p0
.end method
