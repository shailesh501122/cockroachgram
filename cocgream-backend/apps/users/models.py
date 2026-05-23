"""Members of the movement."""
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.core.validators import RegexValidator
from django.db import models
from django.utils import timezone

from .managers import UserManager

# Member numbers start from this offset so #00042871 matches the design's
# splash-screen "Cockroach Member #42,871" copy.
MEMBER_NO_OFFSET = 42_870


INDIAN_STATES = [
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh", "Goa",
    "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka", "Kerala",
    "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram", "Nagaland",
    "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana", "Tripura",
    "Uttar Pradesh", "Uttarakhand", "West Bengal", "Delhi", "Jammu & Kashmir",
    "Ladakh", "Puducherry", "Chandigarh",
]
STATE_CHOICES = [(s, s) for s in INDIAN_STATES]


username_validator = RegexValidator(
    regex=r"^[a-zA-Z0-9_.]{3,30}$",
    message="3–30 chars, letters / numbers / _ / . only.",
)


class User(AbstractBaseUser, PermissionsMixin):
    """A cockroach who's signed the manifesto."""

    username = models.CharField(
        max_length=30, unique=True, validators=[username_validator],
    )
    email = models.EmailField(blank=True, null=True, unique=True)
    phone = models.CharField(max_length=20, blank=True, null=True, unique=True)
    name = models.CharField(max_length=80)
    state = models.CharField(max_length=40, choices=STATE_CHOICES, blank=True)

    # Public identity / profile
    verified = models.BooleanField(default=False)
    bio = models.TextField(blank=True)
    avatar = models.ImageField(upload_to="avatars/", blank=True, null=True)
    cover = models.ImageField(upload_to="covers/", blank=True, null=True)

    # Movement metadata
    member_no = models.CharField(max_length=8, unique=True, editable=False)
    agreed_manifesto_at = models.DateTimeField(null=True, blank=True)

    # Plumbing
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    joined_at = models.DateTimeField(auto_now_add=True)
    last_login = models.DateTimeField(blank=True, null=True)

    objects = UserManager()

    USERNAME_FIELD = "username"
    REQUIRED_FIELDS = ["name"]

    class Meta:
        ordering = ["-joined_at"]
        indexes = [
            models.Index(fields=["username"]),
            models.Index(fields=["state"]),
        ]

    def __str__(self) -> str:
        return f"@{self.username} ({self.name})"

    @property
    def initials(self) -> str:
        parts = (self.name or self.username).split()
        return "".join(p[0] for p in parts[:2]).upper() or "??"

    @property
    def handle(self) -> str:
        return f"@{self.username}"

    @property
    def joined_label(self) -> str:
        return self.joined_at.strftime("Joined %B %Y") if self.joined_at else ""

    def save(self, *args, **kwargs):
        creating = self._state.adding
        super().save(*args, **kwargs)
        if creating and not self.member_no:
            # Use the auto-assigned PK to derive a unique zero-padded member no.
            self.member_no = f"{(self.pk + MEMBER_NO_OFFSET):08d}"
            super().save(update_fields=["member_no"])


class Follow(models.Model):
    """`follower` follows `following`."""

    follower = models.ForeignKey(
        User, related_name="following_set", on_delete=models.CASCADE,
    )
    following = models.ForeignKey(
        User, related_name="follower_set", on_delete=models.CASCADE,
    )
    created_at = models.DateTimeField(default=timezone.now, db_index=True)

    class Meta:
        unique_together = [("follower", "following")]
        indexes = [models.Index(fields=["follower", "following"])]

    def __str__(self) -> str:
        return f"{self.follower} → {self.following}"
