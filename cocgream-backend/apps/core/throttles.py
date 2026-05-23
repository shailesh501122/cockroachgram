"""Custom throttles — keep the bots out, let the citizens through."""
from rest_framework.throttling import UserRateThrottle


class BurstThrottle(UserRateThrottle):
    """Short-window throttle — defends against rapid-fire abuse (like-spam, etc.)."""

    scope = "burst"


class AuthThrottle(UserRateThrottle):
    """Tighter throttle scoped to auth endpoints (login/signup)."""

    scope = "auth"
