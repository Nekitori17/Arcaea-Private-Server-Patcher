.class public final Lmoe/ext/arc/config/DomainConfigLoader$DomainRule;
.super Ljava/lang/Object;
.source "DomainConfigLoader.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lmoe/ext/arc/config/DomainConfigLoader;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x19
    name = "DomainRule"
.end annotation


# instance fields
.field public final originalHost:Ljava/lang/String;

.field public final originalPort:I

.field public final replacementHost:Ljava/lang/String;

.field public final replacementPort:I


# direct methods
.method public constructor <init>(Ljava/lang/String;ILjava/lang/String;I)V
    .locals 0

    .line 33
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 34
    iput-object p1, p0, Lmoe/ext/arc/config/DomainConfigLoader$DomainRule;->originalHost:Ljava/lang/String;

    .line 35
    iput p2, p0, Lmoe/ext/arc/config/DomainConfigLoader$DomainRule;->originalPort:I

    .line 36
    iput-object p3, p0, Lmoe/ext/arc/config/DomainConfigLoader$DomainRule;->replacementHost:Ljava/lang/String;

    .line 37
    iput p4, p0, Lmoe/ext/arc/config/DomainConfigLoader$DomainRule;->replacementPort:I

    .line 38
    return-void
.end method
