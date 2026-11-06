.class public final Lmoe/ext/arc/ExtEntry;
.super Ljava/lang/Object;
.source "ExtEntry.java"


# static fields
.field private static final TAG:Ljava/lang/String; = "ArcExt::Entry"

.field private static volatile sInitialized:Z


# direct methods
.method static constructor <clinit>()V
    .locals 1

    .line 13
    const/4 v0, 0x0

    sput-boolean v0, Lmoe/ext/arc/ExtEntry;->sInitialized:Z

    return-void
.end method

.method private constructor <init>()V
    .locals 0

    .line 15
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 16
    return-void
.end method

.method public static declared-synchronized init(Landroid/content/Context;)V
    .locals 4

    const-class v0, Lmoe/ext/arc/ExtEntry;

    monitor-enter v0

    .line 19
    :try_start_3
    sget-boolean v1, Lmoe/ext/arc/ExtEntry;->sInitialized:Z

    if-eqz v1, :cond_10

    .line 20
    const-string p0, "ArcExt::Entry"

    const-string v1, "ExtEntry already initialized, skipping"

    invoke-static {p0, v1}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_e
    .catchall {:try_start_3 .. :try_end_e} :catchall_50

    .line 21
    monitor-exit v0

    return-void

    .line 23
    :cond_10
    if-nez p0, :cond_1b

    .line 24
    :try_start_12
    const-string p0, "ArcExt::Entry"

    const-string v1, "Context is null, cannot initialize ArcExt"

    invoke-static {p0, v1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_19
    .catchall {:try_start_12 .. :try_end_19} :catchall_50

    .line 25
    monitor-exit v0

    return-void

    .line 29
    :cond_1b
    :try_start_1b
    invoke-static {p0}, Lmoe/ext/arc/config/DomainConfigLoader;->ensureConfigExtracted(Landroid/content/Context;)V

    .line 30
    invoke-static {}, Lmoe/ext/arc/core/NativeBridge;->initialize()Z

    move-result p0
    :try_end_22
    .catchall {:try_start_1b .. :try_end_22} :catchall_31

    if-nez p0, :cond_26

    .line 31
    monitor-exit v0

    return-void

    .line 33
    :cond_26
    const/4 p0, 0x1

    :try_start_27
    sput-boolean p0, Lmoe/ext/arc/ExtEntry;->sInitialized:Z

    .line 34
    const-string p0, "ArcExt::Entry"

    const-string v1, "ArcExt initialization completed successfully"

    invoke-static {p0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_30
    .catchall {:try_start_27 .. :try_end_30} :catchall_31

    .line 37
    goto :goto_4e

    .line 35
    :catchall_31
    move-exception p0

    .line 36
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

    .line 38
    :goto_4e
    monitor-exit v0

    return-void

    .line 18
    :catchall_50
    move-exception p0

    :try_start_51
    monitor-exit v0
    :try_end_52
    .catchall {:try_start_51 .. :try_end_52} :catchall_50

    throw p0
.end method
