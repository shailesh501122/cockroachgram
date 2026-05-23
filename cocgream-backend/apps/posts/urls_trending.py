"""/api/trending/ — ranked hashtags."""
from django.urls import path

from .views import TrendingHashtagsView

app_name = "trending"

urlpatterns = [
    path("", TrendingHashtagsView.as_view(), name="hashtags"),
]
