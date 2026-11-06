.class public final Lmoe/ext/arc/storage/MimeTypeResolver;
.super Ljava/lang/Object;
.source "MimeTypeResolver.java"


# direct methods
.method private constructor <init>()V
    .locals 0

    .line 13
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 14
    return-void
.end method

.method public static resolveForFile(Ljava/io/File;)Ljava/lang/String;
    .locals 1

    .line 17
    invoke-virtual {p0}, Ljava/io/File;->isDirectory()Z

    move-result v0

    if-eqz v0, :cond_9

    .line 18
    const-string p0, "vnd.android.document/directory"

    return-object p0

    .line 20
    :cond_9
    invoke-virtual {p0}, Ljava/io/File;->getName()Ljava/lang/String;

    move-result-object p0

    invoke-static {p0}, Lmoe/ext/arc/storage/MimeTypeResolver;->resolveForName(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    return-object p0
.end method

.method public static resolveForName(Ljava/lang/String;)Ljava/lang/String;
    .locals 1

    .line 24
    const/16 v0, 0x2e

    invoke-virtual {p0, v0}, Ljava/lang/String;->lastIndexOf(I)I

    move-result v0

    .line 25
    if-ltz v0, :cond_1f

    .line 26
    add-int/lit8 v0, v0, 0x1

    invoke-virtual {p0, v0}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object p0

    sget-object v0, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    invoke-virtual {p0, v0}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object p0

    .line 27
    invoke-static {}, Landroid/webkit/MimeTypeMap;->getSingleton()Landroid/webkit/MimeTypeMap;

    move-result-object v0

    invoke-virtual {v0, p0}, Landroid/webkit/MimeTypeMap;->getMimeTypeFromExtension(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    .line 28
    if-eqz p0, :cond_1f

    .line 29
    return-object p0

    .line 32
    :cond_1f
    const-string p0, "application/octet-stream"

    return-object p0
.end method
