"""
Admin-only API endpoints — power the new /cgadmin/ dashboard.

Auth: every view is `IsAdminUser`, which accepts both the JWT (Bearer header)
*and* the Django session cookie set by `/admin/login/`. The dashboard is
loaded over a session so cookie auth is what fires here.
"""
from datetime import timedelta

from django.db.models import Count
from django.utils import timezone
from rest_framework import generics
from rest_framework.permissions import IsAdminUser
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.notifications.models import Notification
from apps.notifications.serializers import NotificationSerializer
from apps.posts.models import Comment, Hashtag, Like, Post, Repost
from apps.posts.serializers import PostSerializer
from apps.posts.views import annotated_posts
from apps.users.models import Follow, User
from apps.users.serializers import UserSerializer


def _pct(curr: int, prev: int) -> float:
    """Compact percentage delta — returned as a float, rounded to 1dp."""
    if prev == 0:
        return 100.0 if curr else 0.0
    return round(((curr - prev) / prev) * 100, 1)


class AdminStatsView(APIView):
    """All the headline numbers the dashboard renders, one round-trip."""

    permission_classes = [IsAdminUser]

    def get(self, request):
        now = timezone.now()
        day_ago = now - timedelta(days=1)
        prev_day = day_ago - timedelta(days=1)
        week_ago = now - timedelta(days=7)

        m_today = User.objects.filter(joined_at__gte=day_ago).count()
        m_yest = User.objects.filter(
            joined_at__gte=prev_day, joined_at__lt=day_ago
        ).count()

        p_today = Post.objects.filter(created_at__gte=day_ago).count()
        p_yest = Post.objects.filter(
            created_at__gte=prev_day, created_at__lt=day_ago
        ).count()

        likes_today = Like.objects.filter(created_at__gte=day_ago).count()
        likes_yest = Like.objects.filter(
            created_at__gte=prev_day, created_at__lt=day_ago
        ).count()

        reposts_today = Repost.objects.filter(created_at__gte=day_ago).count()
        reposts_yest = Repost.objects.filter(
            created_at__gte=prev_day, created_at__lt=day_ago
        ).count()

        return Response({
            "members": {
                "total": User.objects.count(),
                "verified": User.objects.filter(verified=True).count(),
                "today": m_today,
                "delta_pct": _pct(m_today, m_yest),
            },
            "active_today": {
                "value": User.objects.filter(last_login__gte=day_ago).count(),
                "delta_pct": 0,
            },
            "posts_24h": {
                "value": p_today,
                "delta_pct": _pct(p_today, p_yest),
            },
            "reposts_24h": {
                "value": reposts_today,
                "delta_pct": _pct(reposts_today, reposts_yest),
            },
            "likes_24h": {
                "value": likes_today,
                "delta_pct": _pct(likes_today, likes_yest),
            },
            "comments_24h": Comment.objects.filter(created_at__gte=day_ago).count(),
            "follows_7d": Follow.objects.filter(created_at__gte=week_ago).count(),
            "hashtags_count": Hashtag.objects.count(),
            "unread_notifications": Notification.objects.filter(read=False).count(),
            "top_states": list(
                User.objects.exclude(state="")
                .values("state")
                .annotate(count=Count("id"))
                .order_by("-count")[:10]
            ),
            "top_hashtags": [
                {"tag": h.tag, "count": h.post_count}
                for h in Hashtag.objects.annotate(post_count=Count("posts"))
                .order_by("-post_count")[:5]
            ],
            "generated_at": now.isoformat(),
        })


class AdminMembersListView(generics.ListAPIView):
    """All members for the moderation table. No pagination — the table paginates client-side."""

    permission_classes = [IsAdminUser]
    serializer_class = UserSerializer
    pagination_class = None

    def get_queryset(self):
        return User.objects.all().order_by("-joined_at")


class AdminPostsListView(generics.ListAPIView):
    """All posts (annotated with counts) for the moderation table."""

    permission_classes = [IsAdminUser]
    serializer_class = PostSerializer
    pagination_class = None

    def get_queryset(self):
        return annotated_posts(self.request.user).order_by("-created_at")[:200]


class AdminNotificationsListView(generics.ListAPIView):
    """System-wide notification feed (across all recipients)."""

    permission_classes = [IsAdminUser]
    serializer_class = NotificationSerializer
    pagination_class = None

    def get_queryset(self):
        return (
            Notification.objects.select_related("actor")
            .order_by("-created_at")[:100]
        )


class AdminActivityView(APIView):
    """Recent signups + posts merged into one chronological stream."""

    permission_classes = [IsAdminUser]

    def get(self, request):
        items = []
        for u in User.objects.order_by("-joined_at")[:15]:
            items.append({
                "type": "signup",
                "at": u.joined_at.isoformat(),
                "name": u.name or u.username,
                "handle": u.handle,
                "initials": u.initials,
                "verified": u.verified,
                "detail": f"joined from {u.state or '—'}",
            })
        for p in Post.objects.select_related("author").order_by("-created_at")[:15]:
            items.append({
                "type": "post",
                "at": p.created_at.isoformat(),
                "name": p.author.name or p.author.username,
                "handle": p.author.handle,
                "initials": p.author.initials,
                "verified": p.author.verified,
                "detail": p.text[:90] + ("…" if len(p.text) > 90 else ""),
            })
        items.sort(key=lambda x: x["at"], reverse=True)
        return Response({"results": items[:30]})
