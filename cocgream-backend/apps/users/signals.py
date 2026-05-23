"""User-related signal receivers."""
from django.db.models.signals import post_save
from django.dispatch import receiver

from apps.notifications.models import Notification, NotifType

from .models import Follow


@receiver(post_save, sender=Follow)
def notify_on_follow(sender, instance: Follow, created: bool, **kwargs):
    """Drop a follow notification into the followee's inbox."""
    if not created:
        return
    Notification.objects.create(
        recipient=instance.following,
        actor=instance.follower,
        type=NotifType.FOLLOW,
    )
