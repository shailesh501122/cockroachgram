"""/api/notifications/* — list, mark-read, unread-count."""
from django.urls import path

from .views import MarkReadView, NotificationListView, UnreadCountView

app_name = "notifications"

urlpatterns = [
    path("", NotificationListView.as_view(), name="list"),
    path("read/", MarkReadView.as_view(), name="read"),
    path("unread/", UnreadCountView.as_view(), name="unread"),
]
