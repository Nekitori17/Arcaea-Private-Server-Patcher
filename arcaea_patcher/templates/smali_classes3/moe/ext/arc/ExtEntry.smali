.class public final Lmoe/ext/arc/ExtEntry;
.super Ljava/lang/Object;
.source "ExtEntry.java"


# static fields
.field private static final LIBRARY_NAME:Ljava/lang/String; = "ext"

.field private static final TAG:Ljava/lang/String; = "ArcExt::Entry"

.field private static volatile sInitialized:Z


# direct methods
.method static constructor <clinit>()V
    .locals 1

    .line 17
    const/4 v0, 0x0

    sput-boolean v0, Lmoe/ext/arc/ExtEntry;->sInitialized:Z

    return-void
.end method

.method private constructor <init>()V
    .locals 0

    .line 19
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 20
    return-void
.end method

.method public static getCurrentPackageName()Ljava/lang/String;
    .locals 5

    .line 47
    :try_start_0
    new-instance v0, Ljava/io/FileInputStream;

    const-string v1, "/proc/self/cmdline"

    invoke-direct {v0, v1}, Ljava/io/FileInputStream;-><init>(Ljava/lang/String;)V
    :try_end_7
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_7} :catch_53

    .line 48
    :try_start_7
    new-instance v1, Ljava/io/InputStreamReader;

    sget-object v2, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-direct {v1, v0, v2}, Ljava/io/InputStreamReader;-><init>(Ljava/io/InputStream;Ljava/nio/charset/Charset;)V
    :try_end_e
    .catchall {:try_start_7 .. :try_end_e} :catchall_49

    .line 49
    :try_start_e
    new-instance v2, Ljava/io/BufferedReader;

    invoke-direct {v2, v1}, Ljava/io/BufferedReader;-><init>(Ljava/io/Reader;)V
    :try_end_13
    .catchall {:try_start_e .. :try_end_13} :catchall_3f

    .line 50
    :try_start_13
    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    .line 52
    :goto_18
    invoke-virtual {v2}, Ljava/io/BufferedReader;->read()I

    move-result v4

    if-lez v4, :cond_23

    .line 53
    int-to-char v4, v4

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    goto :goto_18

    .line 55
    :cond_23
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    invoke-virtual {v3}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v3
    :try_end_2b
    .catchall {:try_start_13 .. :try_end_2b} :catchall_35

    .line 56
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

    .line 55
    return-object v3

    .line 47
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

    .line 56
    :catch_53
    move-exception v0

    .line 57
    const/4 v0, 0x0

    return-object v0
.end method

.method public static declared-synchronized init(Landroid/content/Context;)V
    .locals 4

    const-class v0, Lmoe/ext/arc/ExtEntry;

    monitor-enter v0

    .line 25
    :try_start_3
    sget-boolean v1, Lmoe/ext/arc/ExtEntry;->sInitialized:Z

    if-eqz v1, :cond_10

    .line 26
    const-string p0, "ArcExt::Entry"

    const-string v1, "ExtEntry already initialized, skipping"

    invoke-static {p0, v1}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_e
    .catchall {:try_start_3 .. :try_end_e} :catchall_50

    .line 27
    monitor-exit v0

    return-void

    .line 29
    :cond_10
    if-nez p0, :cond_1b

    .line 30
    :try_start_12
    const-string p0, "ArcExt::Entry"

    const-string v1, "Context is null, cannot initialize ArcExt"

    invoke-static {p0, v1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_19
    .catchall {:try_start_12 .. :try_end_19} :catchall_50

    .line 31
    monitor-exit v0

    return-void

    .line 35
    :cond_1b
    :try_start_1b
    invoke-static {p0}, Lmoe/ext/arc/config/DomainConfigLoader;->ensureConfigExtracted(Landroid/content/Context;)V

    .line 36
    invoke-static {}, Lmoe/ext/arc/ExtEntry;->initializeNative()Z

    move-result p0
    :try_end_22
    .catchall {:try_start_1b .. :try_end_22} :catchall_31

    if-nez p0, :cond_26

    .line 37
    monitor-exit v0

    return-void

    .line 39
    :cond_26
    const/4 p0, 0x1

    :try_start_27
    sput-boolean p0, Lmoe/ext/arc/ExtEntry;->sInitialized:Z

    .line 40
    const-string p0, "ArcExt::Entry"

    const-string v1, "ArcExt initialization completed successfully"

    invoke-static {p0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_30
    .catchall {:try_start_27 .. :try_end_30} :catchall_31

    .line 43
    goto :goto_4e

    .line 41
    :catchall_31
    move-exception p0

    .line 42
    :try_start_32
    const-string v1, "ArcExt::Entry"

    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "Fatal error during ArcExt initialization: "

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {p0}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    move-result-object v3

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    invoke-static {v1, v2, p0}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I
    :try_end_4e
    .catchall {:try_start_32 .. :try_end_4e} :catchall_50

    .line 44
    :goto_4e
    monitor-exit v0

    return-void

    .line 24
    :catchall_50
    move-exception p0

    :try_start_51
    monitor-exit v0
    :try_end_52
    .catchall {:try_start_51 .. :try_end_52} :catchall_50

    throw p0
.end method

.method public static initializeNative()Z
    .locals 4

    .line 63
    const-string v0, "ArcExt::Entry"

    const/4 v1, 0x0

    :try_start_3
    const-string v2, "ext"

    invoke-static {v2}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

    .line 64
    const-string v2, "libext.so loaded successfully"

    invoke-static {v0, v2}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_d
    .catchall {:try_start_3 .. :try_end_d} :catchall_1a

    .line 68
    nop

    .line 71
    :try_start_e
    invoke-static {}, Lmoe/ext/arc/ExtEntry;->nativeInit()V
    :try_end_11
    .catchall {:try_start_e .. :try_end_11} :catchall_13

    .line 72
    const/4 v0, 0x1

    return v0

    .line 73
    :catchall_13
    move-exception v2

    .line 74
    const-string v3, "nativeInit() failed"

    invoke-static {v0, v3, v2}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 75
    return v1

    .line 65
    :catchall_1a
    move-exception v2

    .line 66
    const-string v3, "Failed to load libext.so"

    invoke-static {v0, v3, v2}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 67
    return v1
.end method

.method public static native nativeInit()V
.end method
