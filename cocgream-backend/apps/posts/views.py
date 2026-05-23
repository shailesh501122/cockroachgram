"""Post + reaction endpoints — the heart of the feed."""
from datetime import timedelta

from django.db.models import (
    Count,
    Exists,
    F,
    OuterRef,
    Q,
)
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.users.models import Follow

from .models import Bookmark, Comment, Hashtag, Like, Post, Repost
from .serializers import (
    CommentSerializer,
    PostCreateSerializer,
    PostSerializer,
)


# ---------- Helpers ----------
def annotated_posts(user):
    """Base feed queryset with counts and per-user reaction flags."""
    return (
        Post.objects.select_related("author")
        .prefetch_related("hashtags")
        .annotate(
            likes_count=Count("likes", distinct=True),
            comments_count=Count("comments", distinct=True),
            reposts_count=Count("reposts", distinct=True),
            liked=Exists(Like.objects.filter(post=OuterRef("pk"), user=user)),
            reposted=Exists(Repost.objects.filter(post=OuterRef("pk"), user=user)),
            bookmarked=Exists(Bookmark.objects.filter(post=OuterRef("pk"), user=user)),
        )
    )


def visible_to(user, qs):
    """Apply audience visibility."""
    return qs.filter(
        Q(audience="public")
        | Q(author=user)
        | Q(audience="state", author__state=user.state)
        | Q(audience="followers", author__follower_set__follower=user)
    ).distinct()


# ---------- Posts ----------
class PostListCreateView(generics.ListCreateAPIView):
    """`GET /api/posts/?tab=foryou|following|state|trending` + `POST` to create."""

    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        return PostCreateSerializer if self.request.method == "POST" else PostSerializer

    def get_queryset(self):
        user = self.request.user
        qs = visible_to(user, annotated_posts(user))
        tab = self.request.query_params.get("tab", "foryou")
        if tab == "following":
            qs = qs.filter(
                author_id__in=Follow.objects.filter(
                    follower=user
                ).values("following_id")
            )
        elif tab == "state":
            qs = qs.filter(author__state=user.state) if user.state else qs.none()
        elif tab == "trending":
            since = timezone.now() - timedelta(hours=24)
            qs = qs.filter(created_at__gte=since).order_by(
                (F("likes_count") + F("reposts_count") * 2 + F("comments_count")).desc(),
                "-created_at",
            )
        return qs

    def create(self, request, *args, **kwargs):
        write = self.get_serializer(data=request.data)
        write.is_valid(raise_exception=True)
        post = write.save()
        # Re-fetch with annotations so the client gets the full read shape back.
        post = annotated_posts(request.user).get(pk=post.pk)
        return Response(
            PostSerializer(post, context={"request": request}).data,
            status=status.HTTP_201_CREATED,
        )


class PostDetailView(generics.RetrieveDestroyAPIView):
    serializer_class = PostSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return visible_to(self.request.user, annotated_posts(self.request.user))

    def perform_destroy(self, instance):
        if instance.author_id != self.request.user.id:
            self.permission_denied(self.request, "Not your post.")
        instance.delete()


# ---------- Reactions ----------
class _ToggleReactionView(APIView):
    """Base for like / repost / bookmark — POST creates, DELETE removes."""

    permission_classes = [IsAuthenticated]
    model = None  # override
    field = ""    # response key ("liked", "reposted", "bookmarked")

    def post(self, request, pk: int):
        post = get_object_or_404(Post, pk=pk)
        _, created = self.model.objects.get_or_create(post=post, user=request.user)
        return Response(
            {self.field: True, "created": created},
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )

    def delete(self, request, pk: int):
        post = get_object_or_404(Post, pk=pk)
        self.model.objects.filter(post=post, user=request.user).delete()
        return Response({self.field: False})


class LikeView(_ToggleReactionView):
    model = Like
    field = "liked"


class RepostView(_ToggleReactionView):
    model = Repost
    field = "reposted"


class BookmarkView(_ToggleReactionView):
    model = Bookmark
    field = "bookmarked"


# ---------- Comments ----------
class CommentListCreateView(generics.ListCreateAPIView):
    serializer_class = CommentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return (
            Comment.objects.select_related("author")
            .filter(post_id=self.kwargs["pk"])
        )

    def perform_create(self, serializer):
        post = get_object_or_404(Post, pk=self.kwargs["pk"])
        serializer.save(post=post, author=self.request.user)


# ---------- Hashtag posts ----------
class HashtagPostsView(generics.ListAPIView):
    serializer_class = PostSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        tag = self.kwargs["tag"].lstrip("#").lower()
        return visible_to(
            self.request.user, annotated_posts(self.request.user)
        ).filter(hashtags__tag=tag)


# ---------- Trending ----------
WINDOWS = {
    "now": timedelta(hours=1),
    "today": timedelta(hours=24),
    "week": timedelta(days=7),
    "state": timedelta(days=7),
}


class TrendingHashtagsView(APIView):
    """`GET /api/trending/?window=now|today|week|state` — ranked hashtags."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        window = request.query_params.get("window", "now")
        delta = WINDOWS.get(window, WINDOWS["now"])
        since = timezone.now() - delta
        qs = Hashtag.objects.filter(posts__created_at__gte=since)
        if window == "state" and request.user.state:
            qs = qs.filter(posts__author__state=request.user.state)
        qs = (
            qs.annotate(post_count=Count("posts", distinct=True))
            .filter(post_count__gt=0)
            .order_by("-post_count")[:30]
        )
        data = []
        for i, h in enumerate(qs, start=1):
            data.append(
                {
                    "rank": i,
                    "tag": f"#{h.tag}",
                    "category": _category_for(h.tag),
                    "count": _humanize(h.post_count),
                    "hot": i <= 3,
                }
            )
        return Response({"window": window, "results": data})


def _humanize(n: int) -> str:
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M posts"
    if n >= 1_000:
        return f"{n / 1_000:.1f}K posts"
    return f"{n} posts"


def _category_for(tag: str) -> str:
    t = tag.lower()
    if "rozgaar" in t or "jobs" in t or "economy" in t or "budget" in t:
        return "Economy"
    if "vote" in t or "youth" in t or "cockroach" in t:
        return "Politics · Trending"
    if "farmer" in t:
        return "Agriculture · Trending"
    if "education" in t or "edu" in t:
        return "Education"
    if "women" in t:
        return "Society"
    return "India · Trending"
