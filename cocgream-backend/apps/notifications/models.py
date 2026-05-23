"""Activity feed — like/comment/follow/repost events."""
from django.conf import settings
from django.db import models
from django.utils import timezone


class NotifType(models.TextChoices):
    LIKE = "like", "Like"
    COMMENT = "comment", "Comment"
    FOLLOW = "follow", "Follow"
    REPOST = "repost", "Repost"
    MENTION = "mention", "Mention"


# Static copy per type — `{actor}` placeholder filled at render time.
NOTIF_TEXT = {
    NotifType.LIKE: "liked your post",
    NotifType.COMMENT: "replied to your post",
    NotifType.FOLLOW: "started following you",
    NotifType.REPOST: "reposted your post",
    NotifType.MENTION: "mentioned you in a post",
}


class Notification(models.Model):
    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="notifications",
        on_delete=models.CASCADE,
    )
    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="acted_notifications",
        on_delete=models.CASCADE,
    )
    type = models.CharField(max_length=12, choices=NotifType.choices)
    post = models.ForeignKey(
        "posts.Post", null=True, blank=True, on_delete=models.CASCADE,
    )
    comment = models.ForeignKey(
        "posts.Comment", null=True, blank=True, on_delete=models.CASCADE,
    )
    preview = models.CharField(max_length=160, blank=True)
    read = models.BooleanField(default=False, db_index=True)
    created_at = models.DateTimeField(default=timezone.now, db_index=True)

    class Meta:
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=["recipient", "-created_at"]),
            models.Index(fields=["recipient", "read"]),
        ]

    def __str__(self) -> str:
        return f"{self.actor} {self.text} → {self.recipient}"

    @property
    def text(self) -> str:
        return NOTIF_TEXT.get(NotifType(self.type), "")
