.class public final Lmoe/ext/arc/config/DomainRule;
.super Ljava/lang/Object;
.source "DomainRule.java"


# instance fields
.field public final originalHost:Ljava/lang/String;

.field public final originalPort:I

.field public final replacementHost:Ljava/lang/String;

.field public final replacementPort:I


# direct methods
.method public constructor <init>(Ljava/lang/String;ILjava/lang/String;I)V
    .locals 0

    .line 12
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 13
    iput-object p1, p0, Lmoe/ext/arc/config/DomainRule;->originalHost:Ljava/lang/String;

    .line 14
    iput p2, p0, Lmoe/ext/arc/config/DomainRule;->originalPort:I

    .line 15
    iput-object p3, p0, Lmoe/ext/arc/config/DomainRule;->replacementHost:Ljava/lang/String;

    .line 16
    iput p4, p0, Lmoe/ext/arc/config/DomainRule;->replacementPort:I

    .line 17
    return-void
.end method
