.class public final Lmoe/ext/arc/storage/DocumentCursorHelper;
.super Ljava/lang/Object;
.source "DocumentCursorHelper.java"


# static fields
.field public static final DEFAULT_DOCUMENT_PROJECTION:[Ljava/lang/String;

.field public static final DEFAULT_ROOT_PROJECTION:[Ljava/lang/String;


# direct methods
.method static constructor <clinit>()V
    .locals 7

    .line 18
    const-string v5, "document_id"

    const-string v6, "available_bytes"

    const-string v0, "root_id"

    const-string v1, "mime_types"

    const-string v2, "flags"

    const-string v3, "icon"

    const-string v4, "title"

    filled-new-array/range {v0 .. v6}, [Ljava/lang/String;

    move-result-object v0

    sput-object v0, Lmoe/ext/arc/storage/DocumentCursorHelper;->DEFAULT_ROOT_PROJECTION:[Ljava/lang/String;

    .line 28
    const-string v5, "flags"

    const-string v6, "_size"

    const-string v1, "document_id"

    const-string v2, "mime_type"

    const-string v3, "_display_name"

    const-string v4, "last_modified"

    filled-new-array/range {v1 .. v6}, [Ljava/lang/String;

    move-result-object v0

    sput-object v0, Lmoe/ext/arc/storage/DocumentCursorHelper;->DEFAULT_DOCUMENT_PROJECTION:[Ljava/lang/String;

    return-void
.end method

.method private constructor <init>()V
    .locals 0

    .line 37
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 38
    return-void
.end method

.method public static addFileRow(Landroid/content/Context;Landroid/database/MatrixCursor;Ljava/lang/String;Ljava/io/File;)V
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation

    .line 70
    if-nez p2, :cond_7

    .line 71
    invoke-static {p0, p3}, Lmoe/ext/arc/storage/PathSecurityGuard;->toDocumentId(Landroid/content/Context;Ljava/io/File;)Ljava/lang/String;

    move-result-object p2

    goto :goto_b

    .line 73
    :cond_7
    invoke-static {p0, p2}, Lmoe/ext/arc/storage/PathSecurityGuard;->resolveSafeFile(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object p3

    .line 76
    :goto_b
    invoke-virtual {p3}, Ljava/io/File;->isDirectory()Z

    move-result p0

    if-eqz p0, :cond_14

    .line 77
    const/16 p0, 0xc

    goto :goto_15

    .line 79
    :cond_14
    const/4 p0, 0x6

    .line 82
    :goto_15
    invoke-virtual {p1}, Landroid/database/MatrixCursor;->newRow()Landroid/database/MatrixCursor$RowBuilder;

    move-result-object p1

    .line 83
    const-string v0, "document_id"

    invoke-virtual {p1, v0, p2}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 84
    const-string p2, "_display_name"

    invoke-virtual {p3}, Ljava/io/File;->getName()Ljava/lang/String;

    move-result-object v0

    invoke-virtual {p1, p2, v0}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 85
    invoke-virtual {p3}, Ljava/io/File;->length()J

    move-result-wide v0

    invoke-static {v0, v1}, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;

    move-result-object p2

    const-string v0, "_size"

    invoke-virtual {p1, v0, p2}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 86
    const-string p2, "mime_type"

    invoke-static {p3}, Lmoe/ext/arc/storage/MimeTypeResolver;->resolveForFile(Ljava/io/File;)Ljava/lang/String;

    move-result-object v0

    invoke-virtual {p1, p2, v0}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 87
    invoke-virtual {p3}, Ljava/io/File;->lastModified()J

    move-result-wide p2

    invoke-static {p2, p3}, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;

    move-result-object p2

    const-string p3, "last_modified"

    invoke-virtual {p1, p3, p2}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 88
    const-string p2, "flags"

    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p0

    invoke-virtual {p1, p2, p0}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 89
    return-void
.end method

.method public static addRootRow(Landroid/content/Context;Landroid/database/MatrixCursor;Ljava/io/File;)V
    .locals 4

    .line 41
    nop

    .line 42
    nop

    .line 43
    const-string v0, "Arcaea"

    const v1, 0x108009b

    if-eqz p0, :cond_22

    .line 45
    :try_start_9
    invoke-virtual {p0}, Landroid/content/Context;->getPackageManager()Landroid/content/pm/PackageManager;

    move-result-object v2

    .line 46
    invoke-virtual {p0}, Landroid/content/Context;->getApplicationInfo()Landroid/content/pm/ApplicationInfo;

    move-result-object p0

    .line 47
    invoke-virtual {v2, p0}, Landroid/content/pm/PackageManager;->getApplicationLabel(Landroid/content/pm/ApplicationInfo;)Ljava/lang/CharSequence;

    move-result-object v2

    invoke-interface {v2}, Ljava/lang/CharSequence;->toString()Ljava/lang/String;

    move-result-object v0

    .line 48
    iget v2, p0, Landroid/content/pm/ApplicationInfo;->icon:I

    if-eqz v2, :cond_20

    .line 49
    iget p0, p0, Landroid/content/pm/ApplicationInfo;->icon:I
    :try_end_1f
    .catch Ljava/lang/Exception; {:try_start_9 .. :try_end_1f} :catch_21

    move v1, p0

    .line 52
    :cond_20
    goto :goto_22

    .line 51
    :catch_21
    move-exception p0

    .line 55
    :cond_22
    :goto_22
    invoke-virtual {p1}, Landroid/database/MatrixCursor;->newRow()Landroid/database/MatrixCursor$RowBuilder;

    move-result-object p0

    .line 56
    const-string p1, "root_id"

    const-string v2, "root"

    invoke-virtual {p0, p1, v2}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 57
    const-string p1, "mime_types"

    const-string v3, "*/*"

    invoke-virtual {p0, p1, v3}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 58
    const-string p1, "document_id"

    invoke-virtual {p0, p1, v2}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 59
    const-string p1, "title"

    invoke-virtual {p0, p1, v0}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 60
    nop

    .line 61
    const/16 p1, 0x13

    invoke-static {p1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p1

    .line 60
    const-string v0, "flags"

    invoke-virtual {p0, v0, p1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 64
    const-string p1, "icon"

    invoke-static {v1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v0

    invoke-virtual {p0, p1, v0}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 65
    invoke-virtual {p2}, Ljava/io/File;->getFreeSpace()J

    move-result-wide p1

    invoke-static {p1, p2}, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;

    move-result-object p1

    const-string p2, "available_bytes"

    invoke-virtual {p0, p2, p1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/String;Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;

    .line 66
    return-void
.end method

.method public static createSafeDocument(Ljava/io/File;Ljava/io/File;Ljava/lang/String;Ljava/lang/String;)Ljava/io/File;
    .locals 7
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation

    .line 115
    if-eqz p3, :cond_c6

    invoke-virtual {p3}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/String;->isEmpty()Z

    move-result v0

    if-nez v0, :cond_c6

    .line 119
    invoke-static {p3}, Lmoe/ext/arc/storage/PathSecurityGuard;->sanitizeDisplayName(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p3

    .line 120
    new-instance v0, Ljava/io/File;

    invoke-direct {v0, p1, p3}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    .line 122
    invoke-virtual {v0}, Ljava/io/File;->exists()Z

    move-result v1

    const-string v2, "vnd.android.document/directory"

    if-eqz v1, :cond_6b

    .line 123
    nop

    .line 124
    nop

    .line 125
    const/16 v1, 0x2e

    invoke-virtual {p3, v1}, Ljava/lang/String;->lastIndexOf(I)I

    move-result v1

    .line 126
    invoke-virtual {v2, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-nez v3, :cond_39

    if-lez v1, :cond_39

    .line 127
    const/4 v3, 0x0

    invoke-virtual {p3, v3, v1}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v3

    .line 128
    invoke-virtual {p3, v1}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object p3

    move-object v1, p3

    move-object p3, v3

    goto :goto_3b

    .line 130
    :cond_39
    const-string v1, ""

    :goto_3b
    const/4 v3, 0x1

    const/4 v4, 0x1

    .line 131
    :goto_3d
    invoke-virtual {v0}, Ljava/io/File;->exists()Z

    move-result v5

    if-eqz v5, :cond_6b

    .line 132
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

    .line 133
    add-int/2addr v4, v3

    goto :goto_3d

    .line 137
    :cond_6b
    invoke-static {p0, v0}, Lmoe/ext/arc/storage/PathSecurityGuard;->isPathSafe(Ljava/io/File;Ljava/io/File;)Z

    move-result p0

    if-eqz p0, :cond_be

    .line 142
    :try_start_71
    invoke-virtual {v2, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_7c

    .line 143
    invoke-virtual {v0}, Ljava/io/File;->mkdirs()Z

    move-result p0

    goto :goto_80

    .line 144
    :cond_7c
    invoke-virtual {v0}, Ljava/io/File;->createNewFile()Z

    move-result p0

    .line 145
    :goto_80
    if-eqz p0, :cond_83

    .line 148
    return-object v0

    .line 146
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

    .line 149
    :catch_a0
    move-exception p0

    .line 150
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

    .line 138
    :cond_be
    new-instance p0, Ljava/io/FileNotFoundException;

    const-string p1, "Invalid document destination."

    invoke-direct {p0, p1}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 116
    :cond_c6
    new-instance p0, Ljava/io/FileNotFoundException;

    const-string p1, "Display name cannot be empty."

    invoke-direct {p0, p1}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method public static deleteRecursively(Ljava/io/File;)Z
    .locals 4

    .line 155
    invoke-virtual {p0}, Ljava/io/File;->isDirectory()Z

    move-result v0

    if-eqz v0, :cond_1d

    .line 156
    invoke-virtual {p0}, Ljava/io/File;->listFiles()[Ljava/io/File;

    move-result-object v0

    .line 157
    if-eqz v0, :cond_1d

    .line 158
    const/4 v1, 0x0

    const/4 v2, 0x0

    :goto_e
    array-length v3, v0

    if-ge v2, v3, :cond_1d

    .line 159
    aget-object v3, v0, v2

    invoke-static {v3}, Lmoe/ext/arc/storage/DocumentCursorHelper;->deleteRecursively(Ljava/io/File;)Z

    move-result v3

    if-nez v3, :cond_1a

    .line 160
    return v1

    .line 158
    :cond_1a
    add-int/lit8 v2, v2, 0x1

    goto :goto_e

    .line 165
    :cond_1d
    invoke-virtual {p0}, Ljava/io/File;->delete()Z

    move-result p0

    return p0
.end method

.method public static parseOpenMode(Ljava/lang/String;)I
    .locals 3

    .line 92
    const-string v0, "r"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_b

    .line 93
    const/high16 p0, 0x10000000

    return p0

    .line 95
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

    .line 99
    :cond_1c
    const-string v0, "wa"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_27

    .line 100
    const/high16 p0, 0x2a000000

    return p0

    .line 103
    :cond_27
    const-string v0, "rw"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_32

    .line 104
    const/high16 p0, 0x38000000

    return p0

    .line 106
    :cond_32
    const-string v0, "rwt"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_3d

    .line 107
    const/high16 p0, 0x3c000000    # 0.0078125f

    return p0

    .line 110
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

    .line 96
    :cond_56
    :goto_56
    const/high16 p0, 0x2c000000

    return p0
.end method
