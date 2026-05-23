"""Serializer for the Alerts screen."""
from django.utils import timezone
from rest_framework import serializers

from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source="actor.name", read_only=True)
    initials = serializers.CharField(source="actor.initials", read_only=True)
    verified = serializers.BooleanField(source="actor.verified", read_only=True)
    text = serializers.CharField(read_only=True)
    time = serializers.SerializerMethodField()
    unread = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = (
            "id", "type", "name", "initials", "verified",
            "text", "preview", "time", "unread", "created_at",
        )
        read_only_fields = fields

    def get_unread(self, obj):
        return not obj.read

    def get_time(self, obj):
        delta = timezone.now() - obj.created_at
        s = int(delta.total_seconds())
        if s < 60:
            return "now"
        if s < 3600:
            return f"{s // 60}m"
        if s < 86400:
            return f"{s // 3600}h"
        return f"{s // 86400}d"
