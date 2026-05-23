"""Custom User manager — usernames are mandatory, email/phone are optional."""
from django.contrib.auth.hashers import make_password
from django.contrib.auth.models import BaseUserManager


class UserManager(BaseUserManager):
    use_in_migrations = True

    def _create_user(self, username, password, **extra):
        if not username:
            raise ValueError("Username is required")
        email = extra.pop("email", None)
        if email:
            email = self.normalize_email(email)
        user = self.model(username=username, email=email, **extra)
        user.password = make_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, username, password=None, **extra):
        extra.setdefault("is_staff", False)
        extra.setdefault("is_superuser", False)
        return self._create_user(username, password, **extra)

    def create_superuser(self, username, password=None, **extra):
        extra.setdefault("is_staff", True)
        extra.setdefault("is_superuser", True)
        extra.setdefault("verified", True)
        if extra["is_staff"] is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra["is_superuser"] is not True:
            raise ValueError("Superuser must have is_superuser=True.")
        return self._create_user(username, password, **extra)
