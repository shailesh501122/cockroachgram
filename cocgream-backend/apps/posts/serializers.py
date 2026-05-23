"""Serializers for posts, comments, hashtags."""
from django.utils.timesince import timesince
from rest_framework import serializers

from apps.users.serializers import UserSerializer

from .models import Audience, Bookmark, Comment, Hashtag, Like, Post, Repost


def _short_timesince(dt) -> str:
    """Twitter-style relative time — '12m', '1h', '3d'."""
    from django.utils import timezone
    delta = timezone.now() - dt
    s = int(delta.total_seconds())
    if s < 60:
        return "now"
    if s < 3600:
        return f"{s // 60}m"
    if s < 86400:
        return f"{s // 3600}h"
    if s < 86400 * 7:
        return f"{s // 86400}d"
    return timesince(dt).split(",")[0]


class HashtagSerializer(serializers.ModelSerializer):
    class Meta:
        model = Hashtag
        fields = ("tag",)


class PostMediaSerializer(serializers.Serializer):
    """The shape Flutter expects under post.media."""

    url = serializers.URLField()
    caption = serializers.CharField()


class PostSerializer(serializers.ModelSerializer):
    """Read shape — all the fields Flutter's PostCard renders."""

    author = UserSerializer(read_only=True)
    media = serializers.SerializerMethodField()
    hashtags = serializers.SlugRelatedField(
        many=True, read_only=True, slug_field="tag",
    )
    likes = serializers.IntegerField(source="likes_count", read_only=True)
    comments = serializers.IntegerField(source="comments_count", read_only=True)
    reposts = serializers.IntegerField(source="reposts_count", read_only=True)
    liked = serializers.BooleanField(read_only=True)
    reposted = serializers.BooleanField(read_only=True)
    bookmarked = serializers.BooleanField(read_only=True)
    time = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = (
            "id", "author", "text", "audience", "location",
            "media", "hashtags",
            "likes", "comments", "reposts",
            "liked", "reposted", "bookmarked",
            "created_at", "time",
        )
        read_only_fields = fields

    def get_media(self, obj):
        if not obj.media:
            return None
        request = self.context.get("request")
        url = obj.media.url
        if request and not url.startswith(("http://", "https://")):
            url = request.build_absolute_uri(url)
        return {"url": url, "caption": obj.media_caption}

    def get_time(self, obj):
        return _short_timesince(obj.created_at)


class PostCreateSerializer(serializers.ModelSerializer):
    """Write shape — what Flutter sends from the Compose screen."""

    tags = serializers.ListField(
        child=serializers.CharField(max_length=80),
        required=False, write_only=True,
    )

    class Meta:
        model = Post
        fields = ("text", "audience", "location", "media", "media_caption", "tags")

    def create(self, validated):
        request = self.context["request"]
        explicit_tags = validated.pop("tags", [])
        post = Post.objects.create(author=request.user, **validated)
        # Tags from the chip selector come in as plain strings; the signal
        # also extracts inline hashtags from the body.
        if explicit_tags:
            post.hashtags.add(*Hashtag.extract(" ".join(f"#{t}" for t in explicit_tags)))
        return post


class CommentSerializer(serializers.ModelSerializer):
    author = UserSerializer(read_only=True)
    time = serializers.SerializerMethodField()

    class Meta:
        model = Comment
        fields = ("id", "post", "author", "text", "created_at", "time")
        read_only_fields = ("id", "author", "created_at", "time", "post")

    def get_time(self, obj):
        return _short_timesince(obj.created_at)
