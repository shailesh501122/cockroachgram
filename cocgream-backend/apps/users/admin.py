"""Django admin for the users app — the 'free Instagram admin panel'."""
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from .models import Follow, User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    list_display = (
        "username", "name", "member_no", "state",
        "verified", "is_staff", "joined_at",
    )
    list_filter = ("verified", "is_staff", "is_superuser", "state")
    search_fields = ("username", "name", "email", "phone", "member_no")
    ordering = ("-joined_at",)
    readonly_fields = ("member_no", "joined_at", "last_login")

    fieldsets = (
        (None, {"fields": ("username", "password")}),
        ("Identity", {"fields": ("name", "email", "phone", "state",
                                  "bio", "avatar", "cover")}),
        ("Movement", {"fields": ("verified", "member_no",
                                   "agreed_manifesto_at")}),
        ("Permissions", {"fields": ("is_active", "is_staff", "is_superuser",
                                     "groups", "user_permissions")}),
        ("Timestamps", {"fields": ("joined_at", "last_login")}),
    )
    add_fieldsets = (
        (None, {
            "classes": ("wide",),
            "fields": ("username", "name", "email", "password1", "password2"),
        }),
    )


@admin.register(Follow)
class FollowAdmin(admin.ModelAdmin):
    list_display = ("follower", "following", "created_at")
    search_fields = (
        "follower__username", "follower__name",
        "following__username", "following__name",
    )
    autocomplete_fields = ("follower", "following")
