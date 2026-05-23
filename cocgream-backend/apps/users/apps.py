from django.apps import AppConfig


class UsersConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.users"

    def ready(self) -> None:
        # Import signal receivers so they are wired on startup.
        from . import signals  # noqa: F401
