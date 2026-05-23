"""Notifications endpoints."""
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Notification, NotifType
from .serializers import NotificationSerializer


class NotificationListView(generics.ListAPIView):
    """`GET /api/notifications/?filter=all|mentions|likes|follows`."""

    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    FILTERS = {
        "mentions": (NotifType.COMMENT, NotifType.MENTION),
        "likes": (NotifType.LIKE,),
        "follows": (NotifType.FOLLOW,),
    }

    def get_queryset(self):
        qs = Notification.objects.select_related("actor").filter(
            recipient=self.request.user
        )
        f = self.request.query_params.get("filter", "all")
        types = self.FILTERS.get(f)
        if types:
            qs = qs.filter(type__in=[t.value for t in types])
        return qs


class MarkReadView(APIView):
    """`POST /api/notifications/read/` — `{ids:[…]}` or `{all:true}`."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        qs = Notification.objects.filter(recipient=request.user, read=False)
        if request.data.get("all"):
            qs.update(read=True)
        else:
            ids = request.data.get("ids", [])
            qs.filter(id__in=ids).update(read=True)
        return Response({"ok": True}, status=status.HTTP_200_OK)


class UnreadCountView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        n = Notification.objects.filter(recipient=request.user, read=False).count()
        return Response({"unread": n})
