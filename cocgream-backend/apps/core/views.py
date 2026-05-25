"""Core views — currently just the new admin dashboard shell."""
from django.contrib.admin.views.decorators import staff_member_required
from django.views.decorators.cache import never_cache
from django.views.generic import TemplateView
from django.utils.decorators import method_decorator


@method_decorator(staff_member_required, name="dispatch")
@method_decorator(never_cache, name="dispatch")
class AdminUIView(TemplateView):
    """The new amber/brown CockroachGram Admin dashboard.

    Renders the single-file design prototype as a Django template. Templating
    is bypassed via a `{% verbatim %}` wrapper baked into the .html so the
    embedded JS — which uses `${...}` template literals and inline object
    syntax — is served untouched. Authentication is the same session cookie
    Django admin already uses (`@staff_member_required`).
    """

    template_name = "cgadmin/index.html"
