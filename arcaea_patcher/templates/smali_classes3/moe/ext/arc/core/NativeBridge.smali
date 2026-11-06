.class public final Lmoe/ext/arc/core/NativeBridge;
.super Ljava/lang/Object;
.source "NativeBridge.java"


# static fields
.field private static final LIBRARY_NAME:Ljava/lang/String; = "ext"

.field private static final TAG:Ljava/lang/String; = "ArcExt::Bridge"


# direct methods
.method private constructor <init>()V
    .locals 0

    .line 12
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 13
    return-void
.end method

.method public static initialize()Z
    .locals 4

    .line 19
    const-string v0, "ArcExt::Bridge"

    const/4 v1, 0x0

    :try_start_3
    const-string v2, "ext"

    invoke-static {v2}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

    .line 20
    const-string v2, "libext.so loaded successfully"

    invoke-static {v0, v2}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_d
    .catchall {:try_start_3 .. :try_end_d} :catchall_1a

    .line 24
    nop

    .line 27
    :try_start_e
    invoke-static {}, Lmoe/ext/arc/core/NativeBridge;->nativeInit()V
    :try_end_11
    .catchall {:try_start_e .. :try_end_11} :catchall_13

    .line 28
    const/4 v0, 0x1

    return v0

    .line 29
    :catchall_13
    move-exception v2

    .line 30
    const-string v3, "nativeInit() failed"

    invoke-static {v0, v3, v2}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 31
    return v1

    .line 21
    :catchall_1a
    move-exception v2

    .line 22
    const-string v3, "Failed to load libext.so"

    invoke-static {v0, v3, v2}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 23
    return v1
.end method

.method public static native nativeInit()V
.end method
