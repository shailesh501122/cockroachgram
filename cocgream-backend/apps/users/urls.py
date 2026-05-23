"""/api/users/* — me, by-username, follow."""
from django.urls import path

from .views import FollowView, MeView, UserDetailView

app_name = "users"

urlpatterns = [
    path("me/", MeView.as_view(), name="me"),
    path("<str:username>/", UserDetailView.as_view(), name="detail"),
    path("<str:username>/follow/", FollowView.as_view(), name="follow"),
]
