"""DRF serializers for users + auth flows."""
from django.contrib.auth import authenticate
from django.db import models, transaction
from django.utils import timezone
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Follow, User


# ---------- Public read ----------
class UserSerializer(serializers.ModelSerializer):
    """Read-only public profile."""

    initials = serializers.CharField(read_only=True)
    handle = serializers.CharField(read_only=True)
    joined_label = serializers.CharField(read_only=True)
    stats = serializers.SerializerMethodField()
    is_following = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = (
            "id", "username", "handle", "name", "initials",
            "verified", "member_no", "bio", "state",
            "avatar", "cover", "joined_at", "joined_label",
            "stats", "is_following",
        )
        read_only_fields = fields

    def get_stats(self, obj):
        from apps.posts.models import Post, Repost
        posts = Post.objects.filter(author=obj).count()
        roars = Repost.objects.filter(post__author=obj).count()
        return {
            "posts": posts,
            "followers": obj.follower_set.count(),
            "following": obj.following_set.count(),
            "roars": roars,
        }

    def get_is_following(self, obj):
        request = self.context.get("request")
        if not request or not request.user.is_authenticated or request.user == obj:
            return False
        return Follow.objects.filter(
            follower=request.user, following=obj
        ).exists()


class MeSerializer(UserSerializer):
    """Private profile (includes contact fields)."""

    class Meta(UserSerializer.Meta):
        fields = UserSerializer.Meta.fields + ("email", "phone", "agreed_manifesto_at")
        read_only_fields = ("id", "member_no", "joined_at", "joined_label",
                            "stats", "is_following", "agreed_manifesto_at",
                            "initials", "handle", "verified")


# ---------- Auth ----------
class SignupSerializer(serializers.Serializer):
    """3-step sign-up — collapsed into one payload from the Flutter side."""

    name = serializers.CharField(max_length=80)
    username = serializers.CharField(max_length=30)
    contact = serializers.CharField(
        max_length=80,
        help_text="Email or +91 phone — auto-routed to the right field.",
    )
    password = serializers.CharField(min_length=6, write_only=True)
    state = serializers.CharField(max_length=40)
    agree = serializers.BooleanField()

    def validate_username(self, value):
        if User.objects.filter(username__iexact=value).exists():
            raise serializers.ValidationError("Username taken.")
        return value.lower()

    def validate_agree(self, value):
        if not value:
            raise serializers.ValidationError("You must sign the manifesto to join.")
        return value

    def _split_contact(self, raw: str) -> dict:
        raw = raw.strip()
        if "@" in raw:
            return {"email": raw.lower()}
        return {"phone": raw.replace(" ", "")}

    @transaction.atomic
    def create(self, validated):
        contact = self._split_contact(validated["contact"])
        if "email" in contact and User.objects.filter(email=contact["email"]).exists():
            raise serializers.ValidationError({"contact": "Email already registered."})
        if "phone" in contact and User.objects.filter(phone=contact["phone"]).exists():
            raise serializers.ValidationError({"contact": "Phone already registered."})

        user = User.objects.create_user(
            username=validated["username"],
            password=validated["password"],
            name=validated["name"],
            state=validated["state"],
            agreed_manifesto_at=timezone.now(),
            **contact,
        )
        return user


class LoginSerializer(serializers.Serializer):
    """Accepts username, email, or phone in `identifier`."""

    identifier = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        ident = attrs["identifier"].strip()
        user = (
            User.objects.filter(username__iexact=ident).first()
            or User.objects.filter(email__iexact=ident).first()
            or User.objects.filter(phone=ident).first()
        )
        if not user:
            raise serializers.ValidationError("No account matches that identifier.")
        user = authenticate(username=user.username, password=attrs["password"])
        if not user:
            raise serializers.ValidationError("Wrong password.")
        if not user.is_active:
            raise serializers.ValidationError("Account disabled.")
        attrs["user"] = user
        return attrs


def issue_tokens(user) -> dict:
    """Issue an access + refresh pair for `user`."""
    refresh = RefreshToken.for_user(user)
    return {"refresh": str(refresh), "access": str(refresh.access_token)}
