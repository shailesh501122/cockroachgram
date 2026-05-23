from django.contrib import admin

from .models import Notification


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ("id", "recipient", "actor", "type", "read", "created_at")
    list_filter = ("type", "read", "created_at")
    search_fields = ("recipient__username", "actor__username", "preview")
    autocomplete_fields = ("recipient", "actor", "post", "comment")
    date_hierarchy = "created_at"
