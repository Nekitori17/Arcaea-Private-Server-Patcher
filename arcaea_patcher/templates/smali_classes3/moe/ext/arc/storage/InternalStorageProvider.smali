.class public Lmoe/ext/arc/storage/InternalStorageProvider;
.super Landroid/provider/DocumentsProvider;
.source "InternalStorageProvider.java"


# static fields
.field private static final TAG:Ljava/lang/String; = "ArcExt::SAF"


# direct methods
.method public constructor <init>()V
    .locals 0

    .line 16
    invoke-direct {p0}, Landroid/provider/DocumentsProvider;-><init>()V

    return-void
.end method


# virtual methods
.method public createDocument(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation

    .line 91
    invoke-virtual {p0}, Lmoe/ext/arc/storage/InternalStorageProvider;->getContext()Landroid/content/Context;

    move-result-object v0

    .line 92
    invoke-static {v0}, Lmoe/ext/arc/storage/PathSecurityGuard;->getAppRootDir(Landroid/content/Context;)Ljava/io/File;

    move-result-object v1

    .line 93
    invoke-static {v0, p1}, Lmoe/ext/arc/storage/PathSecurityGuard;->resolveSafeFile(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object p1

    .line 94
    invoke-static {v1, p1, p2, p3}, Lmoe/ext/arc/storage/DocumentCursorHelper;->createSafeDocument(Ljava/io/File;Ljava/io/File;Ljava/lang/String;Ljava/lang/String;)Ljava/io/File;

    move-result-object p1

    .line 95
    invoke-static {v0, p1}, Lmoe/ext/arc/storage/PathSecurityGuard;->toDocumentId(Landroid/content/Context;Ljava/io/File;)Ljava/lang/String;

    move-result-object p1

    return-object p1
.end method

.method public deleteDocument(Ljava/lang/String;)V
    .locals 3
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation

    .line 100
    invoke-virtual {p0}, Lmoe/ext/arc/storage/InternalStorageProvider;->getContext()Landroid/content/Context;

    move-result-object v0

    invoke-static {v0, p1}, Lmoe/ext/arc/storage/PathSecurityGuard;->resolveSafeFile(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object v0

    .line 101
    invoke-static {v0}, Lmoe/ext/arc/storage/DocumentCursorHelper;->deleteRecursively(Ljava/io/File;)Z

    move-result v0

    if-eqz v0, :cond_f

    .line 104
    return-void

    .line 102
    :cond_f
    new-instance v0, Ljava/io/FileNotFoundException;

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "Failed to delete document: "

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-direct {v0, p1}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V

    throw v0
.end method

.method public getDocumentType(Ljava/lang/String;)Ljava/lang/String;
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation

    .line 108
    invoke-virtual {p0}, Lmoe/ext/arc/storage/InternalStorageProvider;->getContext()Landroid/content/Context;

    move-result-object v0

    invoke-static {v0, p1}, Lmoe/ext/arc/storage/PathSecurityGuard;->resolveSafeFile(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object p1

    .line 109
    invoke-static {p1}, Lmoe/ext/arc/storage/MimeTypeResolver;->resolveForFile(Ljava/io/File;)Ljava/lang/String;

    move-result-object p1

    return-object p1
.end method

.method public isChildDocument(Ljava/lang/String;Ljava/lang/String;)Z
    .locals 2

    .line 37
    const/4 v0, 0x0

    :try_start_1
    invoke-virtual {p0}, Lmoe/ext/arc/storage/InternalStorageProvider;->getContext()Landroid/content/Context;

    move-result-object v1

    .line 38
    invoke-static {v1, p1}, Lmoe/ext/arc/storage/PathSecurityGuard;->resolveSafeFile(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object p1

    .line 39
    invoke-static {v1, p2}, Lmoe/ext/arc/storage/PathSecurityGuard;->resolveSafeFile(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object p2

    .line 40
    invoke-virtual {p1}, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;

    move-result-object p1

    .line 41
    invoke-virtual {p2}, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;

    move-result-object p2

    .line 42
    invoke-virtual {p1, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-nez v1, :cond_34

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    sget-object v1, Ljava/io/File;->separator:Ljava/lang/String;

    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-virtual {p2, p1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result p1
    :try_end_32
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_32} :catch_36

    if-eqz p1, :cond_35

    :cond_34
    const/4 v0, 0x1

    :cond_35
    return v0

    .line 43
    :catch_36
    move-exception p1

    .line 44
    return v0
.end method

.method public onCreate()Z
    .locals 1

    .line 21
    const/4 v0, 0x1

    return v0
.end method

.method public openDocument(Ljava/lang/String;Ljava/lang/String;Landroid/os/CancellationSignal;)Landroid/os/ParcelFileDescriptor;
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation

    .line 81
    invoke-virtual {p0}, Lmoe/ext/arc/storage/InternalStorageProvider;->getContext()Landroid/content/Context;

    move-result-object p3

    invoke-static {p3, p1}, Lmoe/ext/arc/storage/PathSecurityGuard;->resolveSafeFile(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object p3

    .line 82
    invoke-virtual {p3}, Ljava/io/File;->isDirectory()Z

    move-result v0

    if-nez v0, :cond_17

    .line 85
    invoke-static {p2}, Lmoe/ext/arc/storage/DocumentCursorHelper;->parseOpenMode(Ljava/lang/String;)I

    move-result p1

    invoke-static {p3, p1}, Landroid/os/ParcelFileDescriptor;->open(Ljava/io/File;I)Landroid/os/ParcelFileDescriptor;

    move-result-object p1

    return-object p1

    .line 83
    :cond_17
    new-instance p2, Ljava/io/FileNotFoundException;

    new-instance p3, Ljava/lang/StringBuilder;

    invoke-direct {p3}, Ljava/lang/StringBuilder;-><init>()V

    const-string v0, "Cannot open a directory: "

    invoke-virtual {p3, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p3

    invoke-virtual {p3, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-direct {p2, p1}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V

    throw p2
.end method

.method public queryChildDocuments(Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;)Landroid/database/Cursor;
    .locals 5
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation

    .line 59
    if-eqz p2, :cond_3

    goto :goto_5

    :cond_3
    sget-object p2, Lmoe/ext/arc/storage/DocumentCursorHelper;->DEFAULT_DOCUMENT_PROJECTION:[Ljava/lang/String;

    .line 60
    :goto_5
    new-instance p3, Landroid/database/MatrixCursor;

    invoke-direct {p3, p2}, Landroid/database/MatrixCursor;-><init>([Ljava/lang/String;)V

    .line 61
    invoke-virtual {p0}, Lmoe/ext/arc/storage/InternalStorageProvider;->getContext()Landroid/content/Context;

    move-result-object p2

    .line 62
    invoke-static {p2}, Lmoe/ext/arc/storage/PathSecurityGuard;->getAppRootDir(Landroid/content/Context;)Ljava/io/File;

    move-result-object v0

    .line 63
    invoke-static {p2, p1}, Lmoe/ext/arc/storage/PathSecurityGuard;->resolveSafeFile(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object p1

    .line 64
    invoke-virtual {p1}, Ljava/io/File;->listFiles()[Ljava/io/File;

    move-result-object p1

    .line 65
    if-eqz p1, :cond_4c

    .line 66
    const/4 v1, 0x0

    :goto_1d
    array-length v2, p1

    if-ge v1, v2, :cond_4c

    .line 67
    aget-object v2, p1, v1

    .line 68
    invoke-static {v0, v2}, Lmoe/ext/arc/storage/PathSecurityGuard;->isPathSafe(Ljava/io/File;Ljava/io/File;)Z

    move-result v3

    if-nez v3, :cond_45

    .line 69
    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    const-string v4, "Skipping out-of-root entry: "

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v2}, Ljava/io/File;->getAbsolutePath()Ljava/lang/String;

    move-result-object v2

    invoke-virtual {v3, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    const-string v3, "ArcExt::SAF"

    invoke-static {v3, v2}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 70
    goto :goto_49

    .line 72
    :cond_45
    const/4 v3, 0x0

    invoke-static {p2, p3, v3, v2}, Lmoe/ext/arc/storage/DocumentCursorHelper;->addFileRow(Landroid/content/Context;Landroid/database/MatrixCursor;Ljava/lang/String;Ljava/io/File;)V

    .line 66
    :goto_49
    add-int/lit8 v1, v1, 0x1

    goto :goto_1d

    .line 75
    :cond_4c
    return-object p3
.end method

.method public queryDocument(Ljava/lang/String;[Ljava/lang/String;)Landroid/database/Cursor;
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation

    .line 50
    if-eqz p2, :cond_3

    goto :goto_5

    :cond_3
    sget-object p2, Lmoe/ext/arc/storage/DocumentCursorHelper;->DEFAULT_DOCUMENT_PROJECTION:[Ljava/lang/String;

    .line 51
    :goto_5
    new-instance v0, Landroid/database/MatrixCursor;

    invoke-direct {v0, p2}, Landroid/database/MatrixCursor;-><init>([Ljava/lang/String;)V

    .line 52
    invoke-virtual {p0}, Lmoe/ext/arc/storage/InternalStorageProvider;->getContext()Landroid/content/Context;

    move-result-object p2

    const/4 v1, 0x0

    invoke-static {p2, v0, p1, v1}, Lmoe/ext/arc/storage/DocumentCursorHelper;->addFileRow(Landroid/content/Context;Landroid/database/MatrixCursor;Ljava/lang/String;Ljava/io/File;)V

    .line 53
    return-object v0
.end method

.method public queryRoots([Ljava/lang/String;)Landroid/database/Cursor;
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation

    .line 26
    if-eqz p1, :cond_3

    goto :goto_5

    :cond_3
    sget-object p1, Lmoe/ext/arc/storage/DocumentCursorHelper;->DEFAULT_ROOT_PROJECTION:[Ljava/lang/String;

    .line 27
    :goto_5
    new-instance v0, Landroid/database/MatrixCursor;

    invoke-direct {v0, p1}, Landroid/database/MatrixCursor;-><init>([Ljava/lang/String;)V

    .line 28
    invoke-virtual {p0}, Lmoe/ext/arc/storage/InternalStorageProvider;->getContext()Landroid/content/Context;

    move-result-object p1

    .line 29
    invoke-static {p1}, Lmoe/ext/arc/storage/PathSecurityGuard;->getAppRootDir(Landroid/content/Context;)Ljava/io/File;

    move-result-object v1

    .line 30
    invoke-static {p1, v0, v1}, Lmoe/ext/arc/storage/DocumentCursorHelper;->addRootRow(Landroid/content/Context;Landroid/database/MatrixCursor;Ljava/io/File;)V

    .line 31
    return-object v0
.end method
