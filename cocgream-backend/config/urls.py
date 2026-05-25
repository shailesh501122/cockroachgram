"""Root URL config — mounts /admin, /cgadmin, /api/*, OpenAPI, and dev media."""
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.http import JsonResponse
from django.shortcuts import redirect
from django.urls import include, path
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularRedocView,
    SpectacularSwaggerView,
)

from apps.core.views import AdminUIView


def health(_request):
    return JsonResponse({"status": "ok", "service": "cockroachgram-api"})


urlpatterns = [
    # /         → forwards to the new amber/brown admin dashboard.
    # /cgadmin/ → the new UI (uses Django admin's session — log in at /admin/login/).
    # /admin/   → raw Django admin, also our auth endpoint for /cgadmin/.
    path("", lambda r: redirect("/cgadmin/")),
    path("cgadmin/", AdminUIView.as_view(), name="cgadmin"),
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

# After a successful Django-admin login, the user lands on the admin index.
# Swap that index for a redirect into the new dashboard at /cgadmin/ so the
# old yellow Django admin only shows up if someone navigates into a model
# CRUD page (e.g. /admin/posts/post/) directly.
def _admin_index_to_cgadmin(_request, *_args, **_kwargs):
    return redirect("/cgadmin/")


admin.site.index = _admin_index_to_cgadmin
