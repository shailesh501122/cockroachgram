"""/api/posts/* — list/create, detail, reactions, comments, hashtag posts."""
from django.urls import path

from .views import (
    BookmarkView,
    CommentListCreateView,
    HashtagPostsView,
    LikeView,
    PostDetailView,
    PostListCreateView,
    RepostView,
)

app_name = "posts"

urlpatterns = [
    path("", PostListCreateView.as_view(), name="list"),
    path("<int:pk>/", PostDetailView.as_view(), name="detail"),
    path("<int:pk>/like/", LikeView.as_view(), name="like"),
    path("<int:pk>/repost/", RepostView.as_view(), name="repost"),
    path("<int:pk>/bookmark/", BookmarkView.as_view(), name="bookmark"),
    path("<int:pk>/comments/", CommentListCreateView.as_view(), name="comments"),
    path("hashtag/<str:tag>/", HashtagPostsView.as_view(), name="hashtag"),
]
