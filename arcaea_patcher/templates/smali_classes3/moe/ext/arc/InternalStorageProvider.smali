.class public Lmoe/ext/arc/InternalStorageProvider;
.super Landroid/provider/DocumentsProvider;
.source "InternalStorageProvider.java"


# static fields
.field private static final DEFAULT_DOCUMENT_PROJECTION:[Ljava/lang/String;

.field private static final DEFAULT_ROOT_ID:Ljava/lang/String; = "root"

.field private static final DEFAULT_ROOT_PROJECTION:[Ljava/lang/String;

.field private static final TAG:Ljava/lang/String; = "ArcExt::SAF"


# direct methods
.method static constructor <clinit>()V
    .locals 7

    .line 26
    const-string v5, "document_id"

    const-string v6, "available_bytes"

    const-string v0, "root_id"

    const-string v1, "mime_types"

    const-string v2, "flags"

    const-string v3, "icon"

    const-string v4, "title"

    filled-new-array/range {v0 .. v6}, [Ljava/lang/String;

    move-result-object v0

    sput-object v0, Lmoe/ext/arc/InternalStorageProvider;->DEFAULT_ROOT_PROJECTION:[Ljava/lang/String;

    .line 36
    const-string v5, "flags"

    const-string v6, "_size"

    const-string v1, "document_id"

    const-string v2, "mime_type"

    const-string v3, "_display_name"

    const-string v4, "last_modified"

    filled-new-array/range {v1 .. v6}, [Ljava/lang/String;

    move-result-object v0

    sput-object v0, Lmoe/ext/arc/InternalStorageProvider;->DEFAULT_DOCUMENT_PROJECTION:[Ljava/lang/String;

    return-void
.end method

.method public constructor <init>()V
    .locals 0

    .line 22
    invoke-direct {p0}, Landroid/provider/DocumentsProvider;-><init>()V

    return-void
.end method

.method private static addFileRow(Landroid/content/Context;Landroid/database/MatrixCursor;Ljava/lang/String;Ljava/io/File;)V
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation

    .line 256
    if-nez p2, :cond_7

    .line 257
    invoke-static {p0, p3}, Lmoe/ext/arc/InternalStorageProvider;->toDocumentId(Landroid/content/Context;Ljava/io/File;)Ljava/lang/String;

    move-result-object p2

    goto :goto_b

    .line 259
    :cond_7
    invoke-static {p0, p2}, Lmoe/ext/arc/InternalStorageProvider;->resolveSafeFile(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object p3

    .line 262
    :goto_b
    invoke-virtual {p3}, Ljava/io/File;->isDirectory()Z

    move-result p0

    if-eqz p0, :cond_14

    .line 263
    const/16 p0, 0xc

    goto :goto_15

    .line 265
    :cond_14
    const/4 p0, 0x6

    .line 268
    :goto_15
    invoke-virtual {p1}, Landroid/database/MatrixCursor;->newRow()Landroid/database/MatrixCursor$RowBuilder;

    move-result-object p1

    .line 269
    const-string v0, "document_id"

    invoke-virtual {p1, v0, p2}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 270
    const-string p2, "_display_name"

    invoke-virtual {p3}, Ljava/io/File;->getName()Ljava/lang/String;

    move-result-object v0

    invoke-virtual {p1, p2, v0}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 271
    invoke-virtual {p3}, Ljava/io/File;->length()J

    move-result-wide v0

    invoke-static {v0, v1}, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;

    move-result-object p2

    const-string v0, "_size"

    invoke-virtual {p1, v0, p2}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 272
    const-string p2, "mime_type"

    invoke-static {p3}, Lmoe/ext/arc/InternalStorageProvider;->resolveMimeType(Ljava/io/File;)Ljava/lang/String;

    move-result-object v0

    invoke-virtual {p1, p2, v0}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 273
    invoke-virtual {p3}, Ljava/io/File;->lastModified()J

    move-result-wide p2

    invoke-static {p2, p3}, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;

    move-result-object p2

    const-string p3, "last_modified"

    invoke-virtual {p1, p3, p2}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 274
    const-string p2, "flags"

    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p0

    invoke-virtual {p1, p2, p0}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 275
    return-void
.end method

.method private static addRootRow(Landroid/content/Context;Landroid/database/MatrixCursor;Ljava/io/File;)V
    .locals 4

    .line 227
    nop

    .line 228
    nop

    .line 229
    const-string v0, "Arcaea"

    const v1, 0x108009b

    if-eqz p0, :cond_22

    .line 231
    :try_start_9
    invoke-virtual {p0}, Landroid/content/Context;->getPackageManager()Landroid/content/pm/PackageManager;

    move-result-object v2

    .line 232
    invoke-virtual {p0}, Landroid/content/Context;->getApplicationInfo()Landroid/content/pm/ApplicationInfo;

    move-result-object p0

    .line 233
    invoke-virtual {v2, p0}, Landroid/content/pm/PackageManager;->getApplicationLabel(Landroid/content/pm/ApplicationInfo;)Ljava/lang/CharSequence;

    move-result-object v2

    invoke-interface {v2}, Ljava/lang/CharSequence;->toString()Ljava/lang/String;

    move-result-object v0

    .line 234
    iget v2, p0, Landroid/content/pm/ApplicationInfo;->icon:I

    if-eqz v2, :cond_20

    .line 235
    iget p0, p0, Landroid/content/pm/ApplicationInfo;->icon:I
    :try_end_1f
    .catch Ljava/lang/Exception; {:try_start_9 .. :try_end_1f} :catch_21

    move v1, p0

    .line 238
    :cond_20
    goto :goto_22

    .line 237
    :catch_21
    move-exception p0

    .line 241
    :cond_22
    :goto_22
    invoke-virtual {p1}, Landroid/database/MatrixCursor;->newRow()Landroid/database/MatrixCursor$RowBuilder;

    move-result-object p0

    .line 242
    const-string p1, "root_id"

    const-string v2, "root"

    invoke-virtual {p0, p1, v2}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 243
    const-string p1, "mime_types"

    const-string v3, "*/*"

    invoke-virtual {p0, p1, v3}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 244
    const-string p1, "document_id"

    invoke-virtual {p0, p1, v2}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 245
    const-string p1, "title"

    invoke-virtual {p0, p1, v0}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 246
    nop

    .line 247
    const/16 p1, 0x13

    invoke-static {p1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p1

    .line 246
    const-string v0, "flags"

    invoke-virtual {p0, v0, p1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 250
    const-string p1, "icon"

    invoke-static {v1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v0

    invoke-virtual {p0, p1, v0}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 251
    invoke-virtual {p2}, Ljava/io/File;->getFreeSpace()J

    move-result-wide p1

    invoke-static {p1, p2}, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;

    move-result-object p1

    const-string p2, "available_bytes"

    invoke-virtual {p0, p2, p1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 252
    return-void
.end method

.method private static createSafeDocument(Ljava/io/File;Ljava/io/File;Ljava/lang/String;Ljava/lang/String;)Ljava/io/File;
    .locals 7
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation

    .line 301
    if-eqz p3, :cond_c6

    invoke-virtual {p3}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/String;->isEmpty()Z

    move-result v0

    if-nez v0, :cond_c6

    .line 305
    invoke-static {p3}, Lmoe/ext/arc/InternalStorageProvider;->sanitizeDisplayName(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p3

    .line 306
    new-instance v0, Ljava/io/File;

    invoke-direct {v0, p1, p3}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    .line 308
    invoke-virtual {v0}, Ljava/io/File;->exists()Z

    move-result v1

    const-string v2, "vnd.android.document/directory"

    if-eqz v1, :cond_6b

    .line 309
    nop

    .line 310
    nop

    .line 311
    const/16 v1, 0x2e

    invoke-virtual {p3, v1}, Ljava/lang/String;->lastIndexOf(I)I

    move-result v1

    .line 312
    invoke-virtual {v2, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-nez v3, :cond_39

    if-lez v1, :cond_39

    .line 313
    const/4 v3, 0x0

    invoke-virtual {p3, v3, v1}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v3

    .line 314
    invoke-virtual {p3, v1}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object p3

    move-object v1, p3

    move-object p3, v3

    goto :goto_3b

    .line 316
    :cond_39
    const-string v1, ""

    :goto_3b
    const/4 v3, 0x1

    const/4 v4, 0x1

    .line 317
    :goto_3d
    invoke-virtual {v0}, Ljava/io/File;->exists()Z

    move-result v5

    if-eqz v5, :cond_6b

    .line 318
    new-instance v0, Ljava/io/File;

    new-instance v5, Ljava/lang/StringBuilder;

    invoke-direct {v5}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v5, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    const-string v6, " ("

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    invoke-virtual {v5, v4}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v5

    const-string v6, ")"

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    invoke-virtual {v5, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v5

    invoke-direct {v0, p1, v5}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    .line 319
    add-int/2addr v4, v3

    goto :goto_3d

    .line 323
    :cond_6b
    invoke-static {p0, v0}, Lmoe/ext/arc/InternalStorageProvider;->isPathSafe(Ljava/io/File;Ljava/io/File;)Z

    move-result p0

    if-eqz p0, :cond_be

    .line 328
    :try_start_71
    invoke-virtual {v2, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_7c

    .line 329
    invoke-virtual {v0}, Ljava/io/File;->mkdirs()Z

    move-result p0

    goto :goto_80

    .line 330
    :cond_7c
    invoke-virtual {v0}, Ljava/io/File;->createNewFile()Z

    move-result p0

    .line 331
    :goto_80
    if-eqz p0, :cond_83

    .line 334
    return-object v0

    .line 332
    :cond_83
    new-instance p0, Ljava/io/IOException;

    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    const-string p2, "Failed to create: "

    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {v0}, Ljava/io/File;->getAbsolutePath()Ljava/lang/String;

    move-result-object p2

    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
    :try_end_a0
    .catch Ljava/lang/Exception; {:try_start_71 .. :try_end_a0} :catch_a0

    .line 335
    :catch_a0
    move-exception p0

    .line 336
    new-instance p1, Ljava/io/FileNotFoundException;

    new-instance p2, Ljava/lang/StringBuilder;

    invoke-direct {p2}, Ljava/lang/StringBuilder;-><init>()V

    const-string p3, "Failed to create document: "

    invoke-virtual {p2, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p0}, Ljava/lang/Exception;->getMessage()Ljava/lang/String;

    move-result-object p0

    invoke-virtual {p2, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    invoke-direct {p1, p0}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 324
    :cond_be
    new-instance p0, Ljava/io/FileNotFoundException;

    const-string p1, "Invalid document destination."

    invoke-direct {p0, p1}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 302
    :cond_c6
    new-instance p0, Ljava/io/FileNotFoundException;

    const-string p1, "Display name cannot be empty."

    invoke-direct {p0, p1}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static deleteRecursively(Ljava/io/File;)Z
    .locals 4

    .line 341
    invoke-virtual {p0}, Ljava/io/File;->isDirectory()Z

    move-result v0

    if-eqz v0, :cond_1d

    .line 342
    invoke-virtual {p0}, Ljava/io/File;->listFiles()[Ljava/io/File;

    move-result-object v0

    .line 343
    if-eqz v0, :cond_1d

    .line 344
    const/4 v1, 0x0

    const/4 v2, 0x0

    :goto_e
    array-length v3, v0

    if-ge v2, v3, :cond_1d

    .line 345
    aget-object v3, v0, v2

    invoke-static {v3}, Lmoe/ext/arc/InternalStorageProvider;->deleteRecursively(Ljava/io/File;)Z

    move-result v3

    if-nez v3, :cond_1a

    .line 346
    return v1

    .line 344
    :cond_1a
    add-int/lit8 v2, v2, 0x1

    goto :goto_e

    .line 351
    :cond_1d
    invoke-virtual {p0}, Ljava/io/File;->delete()Z

    move-result p0

    return p0
.end method

.method private static getAppRootDir(Landroid/content/Context;)Ljava/io/File;
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation

    .line 141
    if-eqz p0, :cond_3e

    .line 144
    nop

    .line 145
    invoke-virtual {p0}, Landroid/content/Context;->getApplicationInfo()Landroid/content/pm/ApplicationInfo;

    move-result-object v0

    if-eqz v0, :cond_1d

    invoke-virtual {p0}, Landroid/content/Context;->getApplicationInfo()Landroid/content/pm/ApplicationInfo;

    move-result-object v0

    iget-object v0, v0, Landroid/content/pm/ApplicationInfo;->dataDir:Ljava/lang/String;

    if-eqz v0, :cond_1d

    .line 146
    new-instance v0, Ljava/io/File;

    invoke-virtual {p0}, Landroid/content/Context;->getApplicationInfo()Landroid/content/pm/ApplicationInfo;

    move-result-object p0

    iget-object p0, p0, Landroid/content/pm/ApplicationInfo;->dataDir:Ljava/lang/String;

    invoke-direct {v0, p0}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    goto :goto_2d

    .line 147
    :cond_1d
    invoke-virtual {p0}, Landroid/content/Context;->getFilesDir()Ljava/io/File;

    move-result-object v0

    if-eqz v0, :cond_2c

    .line 148
    invoke-virtual {p0}, Landroid/content/Context;->getFilesDir()Ljava/io/File;

    move-result-object p0

    invoke-virtual {p0}, Ljava/io/File;->getParentFile()Ljava/io/File;

    move-result-object v0

    goto :goto_2d

    .line 147
    :cond_2c
    const/4 v0, 0x0

    .line 150
    :goto_2d
    if-eqz v0, :cond_36

    invoke-virtual {v0}, Ljava/io/File;->exists()Z

    move-result p0

    if-eqz p0, :cond_36

    .line 153
    return-object v0

    .line 151
    :cond_36
    new-instance p0, Ljava/io/FileNotFoundException;

    const-string v0, "App root directory is not accessible"

    invoke-direct {p0, v0}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 142
    :cond_3e
    new-instance p0, Ljava/io/FileNotFoundException;

    const-string v0, "Context is not available"

    invoke-direct {p0, v0}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static isPathSafe(Ljava/io/File;Ljava/io/File;)Z
    .locals 2

    .line 170
    const/4 v0, 0x0

    :try_start_1
    invoke-virtual {p0}, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;

    move-result-object p0

    .line 171
    invoke-virtual {p1}, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;

    move-result-object p1

    .line 172
    invoke-virtual {p1, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-nez v1, :cond_28

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v1, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    sget-object v1, Ljava/io/File;->separator:Ljava/lang/String;

    invoke-virtual {p0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    invoke-virtual {p1, p0}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result p0
    :try_end_26
    .catch Ljava/io/IOException; {:try_start_1 .. :try_end_26} :catch_2a

    if-eqz p0, :cond_29

    :cond_28
    const/4 v0, 0x1

    :cond_29
    return v0

    .line 173
    :catch_2a
    move-exception p0

    .line 174
    return v0
.end method

.method private static parseOpenMode(Ljava/lang/String;)I
    .locals 3

    .line 278
    const-string v0, "r"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_b

    .line 279
    const/high16 p0, 0x10000000

    return p0

    .line 281
    :cond_b
    const-string v0, "w"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_56

    const-string v0, "wt"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_1c

    goto :goto_56

    .line 285
    :cond_1c
    const-string v0, "wa"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_27

    .line 286
    const/high16 p0, 0x2a000000

    return p0

    .line 289
    :cond_27
    const-string v0, "rw"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_32

    .line 290
    const/high16 p0, 0x38000000

    return p0

    .line 292
    :cond_32
    const-string v0, "rwt"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_3d

    .line 293
    const/high16 p0, 0x3c000000    # 0.0078125f

    return p0

    .line 296
    :cond_3d
    new-instance v0, Ljava/lang/IllegalArgumentException;

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "Invalid mode: "

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    invoke-direct {v0, p0}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 282
    :cond_56
    :goto_56
    const/high16 p0, 0x2c000000

    return p0
.end method

.method private static resolveMimeType(Ljava/io/File;)Ljava/lang/String;
    .locals 1

    .line 209
    invoke-virtual {p0}, Ljava/io/File;->isDirectory()Z

    move-result v0

    if-eqz v0, :cond_9

    .line 210
    const-string p0, "vnd.android.document/directory"

    return-object p0

    .line 212
    :cond_9
    invoke-virtual {p0}, Ljava/io/File;->getName()Ljava/lang/String;

    move-result-object p0

    .line 213
    const/16 v0, 0x2e

    invoke-virtual {p0, v0}, Ljava/lang/String;->lastIndexOf(I)I

    move-result v0

    .line 214
    if-ltz v0, :cond_2c

    .line 215
    add-int/lit8 v0, v0, 0x1

    invoke-virtual {p0, v0}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object p0

    sget-object v0, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    invoke-virtual {p0, v0}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object p0

    .line 216
    invoke-static {}, Landroid/webkit/MimeTypeMap;->getSingleton()Landroid/webkit/MimeTypeMap;

    move-result-object v0

    invoke-virtual {v0, p0}, Landroid/webkit/MimeTypeMap;->getMimeTypeFromExtension(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    .line 217
    if-eqz p0, :cond_2c

    .line 218
    return-object p0

    .line 221
    :cond_2c
    const-string p0, "application/octet-stream"

    return-object p0
.end method

.method private static resolveSafeFile(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation

    .line 157
    invoke-static {p0}, Lmoe/ext/arc/InternalStorageProvider;->getAppRootDir(Landroid/content/Context;)Ljava/io/File;

    move-result-object p0

    .line 158
    nop

    .line 159
    if-eqz p1, :cond_1b

    invoke-virtual {p1}, Ljava/lang/String;->isEmpty()Z

    move-result v0

    if-nez v0, :cond_1b

    const-string v0, "root"

    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_1b

    .line 160
    new-instance v0, Ljava/io/File;

    invoke-direct {v0, p0, p1}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    goto :goto_1c

    .line 162
    :cond_1b
    move-object v0, p0

    :goto_1c
    invoke-virtual {v0}, Ljava/io/File;->exists()Z

    move-result v1

    if-eqz v1, :cond_29

    invoke-static {p0, v0}, Lmoe/ext/arc/InternalStorageProvider;->isPathSafe(Ljava/io/File;Ljava/io/File;)Z

    move-result p0

    if-eqz p0, :cond_29

    .line 165
    return-object v0

    .line 163
    :cond_29
    new-instance p0, Ljava/io/FileNotFoundException;

    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "Missing or unauthorized file for: "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-direct {p0, p1}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static sanitizeDisplayName(Ljava/lang/String;)Ljava/lang/String;
    .locals 2

    .line 199
    const-string v0, "[/\\\\:*?\"<>|]"

    const-string v1, "_"

    invoke-virtual {p0, v0, v1}, Ljava/lang/String;->replaceAll(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object p0

    .line 200
    const-string v0, "."

    invoke-virtual {p0, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_24

    const-string v0, ".."

    invoke-virtual {p0, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_24

    invoke-virtual {p0}, Ljava/lang/String;->isEmpty()Z

    move-result v0

    if-eqz v0, :cond_23

    goto :goto_24

    .line 203
    :cond_23
    return-object p0

    .line 201
    :cond_24
    :goto_24
    const-string p0, "unnamed_file"

    return-object p0
.end method

.method private static toDocumentId(Landroid/content/Context;Ljava/io/File;)Ljava/lang/String;
    .locals 2

    .line 180
    :try_start_0
    invoke-static {p0}, Lmoe/ext/arc/InternalStorageProvider;->getAppRootDir(Landroid/content/Context;)Ljava/io/File;

    move-result-object p0

    .line 181
    invoke-virtual {p1}, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;

    move-result-object v0

    .line 182
    invoke-virtual {p0}, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;

    move-result-object p0

    .line 183
    invoke-virtual {p0, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_15

    .line 184
    const-string p0, "root"

    return-object p0

    .line 186
    :cond_15
    sget-object v1, Ljava/io/File;->separator:Ljava/lang/String;

    invoke-virtual {p0, v1}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v1

    if-eqz v1, :cond_1e

    .line 187
    goto :goto_31

    .line 188
    :cond_1e
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v1, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    sget-object v1, Ljava/io/File;->separator:Ljava/lang/String;

    invoke-virtual {p0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    .line 189
    :goto_31
    invoke-virtual {v0, p0}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v1

    if-eqz v1, :cond_40

    .line 190
    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result p0

    invoke-virtual {v0, p0}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object p0
    :try_end_3f
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_3f} :catch_41

    return-object p0

    .line 192
    :cond_40
    return-object v0

    .line 193
    :catch_41
    move-exception p0

    .line 194
    invoke-virtual {p1}, Ljava/io/File;->getAbsolutePath()Ljava/lang/String;

    move-result-object p0

    return-object p0
.end method


# virtual methods
.method public createDocument(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation

    .line 117
    invoke-virtual {p0}, Lmoe/ext/arc/InternalStorageProvider;->getContext()Landroid/content/Context;

    move-result-object v0

    .line 118
    invoke-static {v0}, Lmoe/ext/arc/InternalStorageProvider;->getAppRootDir(Landroid/content/Context;)Ljava/io/File;

    move-result-object v1

    .line 119
    invoke-static {v0, p1}, Lmoe/ext/arc/InternalStorageProvider;->resolveSafeFile(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object p1

    .line 120
    invoke-static {v1, p1, p2, p3}, Lmoe/ext/arc/InternalStorageProvider;->createSafeDocument(Ljava/io/File;Ljava/io/File;Ljava/lang/String;Ljava/lang/String;)Ljava/io/File;

    move-result-object p1

    .line 121
    invoke-static {v0, p1}, Lmoe/ext/arc/InternalStorageProvider;->toDocumentId(Landroid/content/Context;Ljava/io/File;)Ljava/lang/String;

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

    .line 126
    invoke-virtual {p0}, Lmoe/ext/arc/InternalStorageProvider;->getContext()Landroid/content/Context;

    move-result-object v0

    invoke-static {v0, p1}, Lmoe/ext/arc/InternalStorageProvider;->resolveSafeFile(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object v0

    .line 127
    invoke-static {v0}, Lmoe/ext/arc/InternalStorageProvider;->deleteRecursively(Ljava/io/File;)Z

    move-result v0

    if-eqz v0, :cond_f

    .line 130
    return-void

    .line 128
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

    .line 134
    invoke-virtual {p0}, Lmoe/ext/arc/InternalStorageProvider;->getContext()Landroid/content/Context;

    move-result-object v0

    invoke-static {v0, p1}, Lmoe/ext/arc/InternalStorageProvider;->resolveSafeFile(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object p1

    .line 135
    invoke-static {p1}, Lmoe/ext/arc/InternalStorageProvider;->resolveMimeType(Ljava/io/File;)Ljava/lang/String;

    move-result-object p1

    return-object p1
.end method

.method public isChildDocument(Ljava/lang/String;Ljava/lang/String;)Z
    .locals 2

    .line 63
    const/4 v0, 0x0

    :try_start_1
    invoke-virtual {p0}, Lmoe/ext/arc/InternalStorageProvider;->getContext()Landroid/content/Context;

    move-result-object v1

    .line 64
    invoke-static {v1, p1}, Lmoe/ext/arc/InternalStorageProvider;->resolveSafeFile(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object p1

    .line 65
    invoke-static {v1, p2}, Lmoe/ext/arc/InternalStorageProvider;->resolveSafeFile(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object p2

    .line 66
    invoke-virtual {p1}, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;

    move-result-object p1

    .line 67
    invoke-virtual {p2}, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;

    move-result-object p2

    .line 68
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

    .line 69
    :catch_36
    move-exception p1

    .line 70
    return v0
.end method

.method public onCreate()Z
    .locals 1

    .line 47
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

    .line 107
    invoke-virtual {p0}, Lmoe/ext/arc/InternalStorageProvider;->getContext()Landroid/content/Context;

    move-result-object p3

    invoke-static {p3, p1}, Lmoe/ext/arc/InternalStorageProvider;->resolveSafeFile(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object p3

    .line 108
    invoke-virtual {p3}, Ljava/io/File;->isDirectory()Z

    move-result v0

    if-nez v0, :cond_17

    .line 111
    invoke-static {p2}, Lmoe/ext/arc/InternalStorageProvider;->parseOpenMode(Ljava/lang/String;)I

    move-result p1

    invoke-static {p3, p1}, Landroid/os/ParcelFileDescriptor;->open(Ljava/io/File;I)Landroid/os/ParcelFileDescriptor;

    move-result-object p1

    return-object p1

    .line 109
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

    .line 85
    if-eqz p2, :cond_3

    goto :goto_5

    :cond_3
    sget-object p2, Lmoe/ext/arc/InternalStorageProvider;->DEFAULT_DOCUMENT_PROJECTION:[Ljava/lang/String;

    .line 86
    :goto_5
    new-instance p3, Landroid/database/MatrixCursor;

    invoke-direct {p3, p2}, Landroid/database/MatrixCursor;-><init>([Ljava/lang/String;)V

    .line 87
    invoke-virtual {p0}, Lmoe/ext/arc/InternalStorageProvider;->getContext()Landroid/content/Context;

    move-result-object p2

    .line 88
    invoke-static {p2}, Lmoe/ext/arc/InternalStorageProvider;->getAppRootDir(Landroid/content/Context;)Ljava/io/File;

    move-result-object v0

    .line 89
    invoke-static {p2, p1}, Lmoe/ext/arc/InternalStorageProvider;->resolveSafeFile(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object p1

    .line 90
    invoke-virtual {p1}, Ljava/io/File;->listFiles()[Ljava/io/File;

    move-result-object p1

    .line 91
    if-eqz p1, :cond_4c

    .line 92
    const/4 v1, 0x0

    :goto_1d
    array-length v2, p1

    if-ge v1, v2, :cond_4c

    .line 93
    aget-object v2, p1, v1

    .line 94
    invoke-static {v0, v2}, Lmoe/ext/arc/InternalStorageProvider;->isPathSafe(Ljava/io/File;Ljava/io/File;)Z

    move-result v3

    if-nez v3, :cond_45

    .line 95
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

    .line 96
    goto :goto_49

    .line 98
    :cond_45
    const/4 v3, 0x0

    invoke-static {p2, p3, v3, v2}, Lmoe/ext/arc/InternalStorageProvider;->addFileRow(Landroid/content/Context;Landroid/database/MatrixCursor;Ljava/lang/String;Ljava/io/File;)V

    .line 92
    :goto_49
    add-int/lit8 v1, v1, 0x1

    goto :goto_1d

    .line 101
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

    .line 76
    if-eqz p2, :cond_3

    goto :goto_5

    :cond_3
    sget-object p2, Lmoe/ext/arc/InternalStorageProvider;->DEFAULT_DOCUMENT_PROJECTION:[Ljava/lang/String;

    .line 77
    :goto_5
    new-instance v0, Landroid/database/MatrixCursor;

    invoke-direct {v0, p2}, Landroid/database/MatrixCursor;-><init>([Ljava/lang/String;)V

    .line 78
    invoke-virtual {p0}, Lmoe/ext/arc/InternalStorageProvider;->getContext()Landroid/content/Context;

    move-result-object p2

    const/4 v1, 0x0

    invoke-static {p2, v0, p1, v1}, Lmoe/ext/arc/InternalStorageProvider;->addFileRow(Landroid/content/Context;Landroid/database/MatrixCursor;Ljava/lang/String;Ljava/io/File;)V

    .line 79
    return-object v0
.end method

.method public queryRoots([Ljava/lang/String;)Landroid/database/Cursor;
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation

    .line 52
    if-eqz p1, :cond_3

    goto :goto_5

    :cond_3
    sget-object p1, Lmoe/ext/arc/InternalStorageProvider;->DEFAULT_ROOT_PROJECTION:[Ljava/lang/String;

    .line 53
    :goto_5
    new-instance v0, Landroid/database/MatrixCursor;

    invoke-direct {v0, p1}, Landroid/database/MatrixCursor;-><init>([Ljava/lang/String;)V

    .line 54
    invoke-virtual {p0}, Lmoe/ext/arc/InternalStorageProvider;->getContext()Landroid/content/Context;

    move-result-object p1

    .line 55
    invoke-static {p1}, Lmoe/ext/arc/InternalStorageProvider;->getAppRootDir(Landroid/content/Context;)Ljava/io/File;

    move-result-object v1

    .line 56
    invoke-static {p1, v0, v1}, Lmoe/ext/arc/InternalStorageProvider;->addRootRow(Landroid/content/Context;Landroid/database/MatrixCursor;Ljava/io/File;)V

    .line 57
    return-object v0
.end method
