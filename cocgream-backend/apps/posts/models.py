"""The political content — posts (a.k.a. 'Roars'), comments, and reactions."""
from __future__ import annotations

import re

from django.conf import settings
from django.db import models
from django.utils import timezone


HASHTAG_RE = re.compile(r"#([A-Za-z0-9_]+)")


class Audience(models.TextChoices):
    PUBLIC = "public", "Public"
    STATE = "state", "State only"
    FOLLOWERS = "followers", "Followers"


class Hashtag(models.Model):
    tag = models.CharField(max_length=80, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("tag",)
        indexes = [models.Index(fields=["tag"])]

    def __str__(self) -> str:
        return f"#{self.tag}"

    @classmethod
    def extract(cls, text: str) -> list["Hashtag"]:
        """Return (and create-if-missing) all hashtags appearing in `text`."""
        tags = {m.group(1).lower() for m in HASHTAG_RE.finditer(text or "")}
        return [cls.objects.get_or_create(tag=t)[0] for t in tags]


class Post(models.Model):
    """One political roar."""

    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="posts",
        on_delete=models.CASCADE,
    )
    text = models.TextField()
    audience = models.CharField(
        max_length=12, choices=Audience.choices, default=Audience.PUBLIC,
    )
    location = models.CharField(max_length=80, blank=True)
    media = models.ImageField(upload_to="posts/", blank=True, null=True)
    media_caption = models.CharField(max_length=200, blank=True)
    hashtags = models.ManyToManyField(Hashtag, related_name="posts", blank=True)
    created_at = models.DateTimeField(default=timezone.now, db_index=True)

    class Meta:
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=["-created_at"]),
            models.Index(fields=["author", "-created_at"]),
            models.Index(fields=["audience"]),
        ]

    def __str__(self) -> str:
        return f"{self.author}: {self.text[:40]}…"

    def save(self, *args, **kwargs):
        if not self.location and self.author_id:
            self.location = self.author.state
        super().save(*args, **kwargs)


class Comment(models.Model):
    post = models.ForeignKey(Post, related_name="comments", on_delete=models.CASCADE)
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL, related_name="comments", on_delete=models.CASCADE,
    )
    text = models.TextField()
    created_at = models.DateTimeField(default=timezone.now, db_index=True)

    class Meta:
        ordering = ("created_at",)


class _UserPostReaction(models.Model):
    """Shared base for like / repost / bookmark — same shape, different table."""

    post = models.ForeignKey(Post, on_delete=models.CASCADE)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    created_at = models.DateTimeField(default=timezone.now, db_index=True)

    class Meta:
        abstract = True
        unique_together = [("post", "user")]


class Like(_UserPostReaction):
    class Meta(_UserPostReaction.Meta):
        default_related_name = "likes"


class Repost(_UserPostReaction):
    class Meta(_UserPostReaction.Meta):
        default_related_name = "reposts"


class Bookmark(_UserPostReaction):
    class Meta(_UserPostReaction.Meta):
        default_related_name = "bookmarks"
