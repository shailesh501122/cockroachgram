"""/api/admin/* — endpoints that power the new dashboard. Staff-only."""
from django.urls import path

from .admin_views import (
    AdminActivityView,
    AdminMembersListView,
    AdminNotificationsListView,
    AdminPostsListView,
    AdminStatsView,
)

app_name = "admin_api"

urlpatterns = [
    path("stats/", AdminStatsView.as_view(), name="stats"),
    path("members/", AdminMembersListView.as_view(), name="members"),
    path("posts/", AdminPostsListView.as_view(), name="posts"),
    path("notifications/", AdminNotificationsListView.as_view(), name="notifications"),
    path("activity/", AdminActivityView.as_view(), name="activity"),
]
