"""Root URL config — mounts /admin, /api/*, OpenAPI, and dev media."""
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.http import JsonResponse
from django.urls import include, path
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularRedocView,
    SpectacularSwaggerView,
)


def health(_request):
    return JsonResponse({"status": "ok", "service": "cockroachgram-api"})


urlpatterns = [
    path("", health),
    path("admin/", admin.site.urls),
    path("api/health/", health),
    path("api/auth/", include("apps.users.urls_auth")),
    path("api/users/", include("apps.users.urls")),
    path("api/posts/", include("apps.posts.urls")),
    path("api/trending/", include("apps.posts.urls_trending")),
    path("api/notifications/", include("apps.notifications.urls")),
    # OpenAPI / Swagger
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="docs"),
    path("api/redoc/", SpectacularRedocView.as_view(url_name="schema"), name="redoc"),
]

if settings.DEBUG and not getattr(settings, "USE_S3", False):
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)


admin.site.site_header = "🪳 CockroachGram Admin"
admin.site.site_title = "CockroachGram"
admin.site.index_title = "Operations · Members · Posts · Movement"
