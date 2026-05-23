"""Post-related signal receivers — hashtag extraction + engagement notifications."""
from django.db.models.signals import post_save
from django.dispatch import receiver

from apps.notifications.models import Notification, NotifType

from .models import Comment, Hashtag, Like, Post, Repost


@receiver(post_save, sender=Post)
def attach_hashtags(sender, instance: Post, created: bool, **kwargs):
    """Auto-attach hashtags found in the post text."""
    if not created:
        return
    tags = Hashtag.extract(instance.text)
    if tags:
        instance.hashtags.add(*tags)


@receiver(post_save, sender=Like)
def notify_on_like(sender, instance: Like, created: bool, **kwargs):
    if not created or instance.post.author_id == instance.user_id:
        return
    Notification.objects.create(
        recipient=instance.post.author,
        actor=instance.user,
        type=NotifType.LIKE,
        post=instance.post,
        preview=instance.post.text[:80],
    )


@receiver(post_save, sender=Repost)
def notify_on_repost(sender, instance: Repost, created: bool, **kwargs):
    if not created or instance.post.author_id == instance.user_id:
        return
    Notification.objects.create(
        recipient=instance.post.author,
        actor=instance.user,
        type=NotifType.REPOST,
        post=instance.post,
        preview=instance.post.text[:80],
    )


@receiver(post_save, sender=Comment)
def notify_on_comment(sender, instance: Comment, created: bool, **kwargs):
    if not created or instance.post.author_id == instance.author_id:
        return
    Notification.objects.create(
        recipient=instance.post.author,
        actor=instance.author,
        type=NotifType.COMMENT,
        post=instance.post,
        comment=instance,
        preview=instance.text[:80],
    )
