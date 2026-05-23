"""Django admin for posts, comments, hashtags, and reactions."""
from django.contrib import admin
from django.utils.html import format_html

from .models import Bookmark, Comment, Hashtag, Like, Post, Repost


@admin.register(Hashtag)
class HashtagAdmin(admin.ModelAdmin):
    list_display = ("tag", "post_count", "created_at")
    search_fields = ("tag",)
    ordering = ("tag",)

    def post_count(self, obj):
        return obj.posts.count()


class CommentInline(admin.TabularInline):
    model = Comment
    extra = 0
    autocomplete_fields = ("author",)
    readonly_fields = ("created_at",)


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = (
        "id", "author", "snippet", "audience", "location",
        "like_count", "comment_count", "repost_count", "created_at",
    )
    list_filter = ("audience", "created_at", "author__state")
    search_fields = ("text", "author__username", "author__name", "location",
                     "hashtags__tag")
    autocomplete_fields = ("author", "hashtags")
    readonly_fields = ("created_at",)
    inlines = (CommentInline,)
    date_hierarchy = "created_at"

    def snippet(self, obj):
        return format_html("<span title='{}'>{}</span>", obj.text, obj.text[:60])

    def like_count(self, obj):
        return obj.likes.count()

    def comment_count(self, obj):
        return obj.comments.count()

    def repost_count(self, obj):
        return obj.reposts.count()


@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    list_display = ("id", "post", "author", "snippet", "created_at")
    search_fields = ("text", "author__username", "post__text")
    autocomplete_fields = ("post", "author")

    def snippet(self, obj):
        return obj.text[:60]


for model in (Like, Repost, Bookmark):
    @admin.register(model)
    class _R(admin.ModelAdmin):
        list_display = ("id", "user", "post", "created_at")
        autocomplete_fields = ("user", "post")
        search_fields = ("user__username", "post__text")
