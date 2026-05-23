"""Users + auth endpoints."""
from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import RefreshToken

from apps.core.throttles import AuthThrottle

from .models import Follow, User
from .serializers import (
    LoginSerializer,
    MeSerializer,
    SignupSerializer,
    UserSerializer,
    issue_tokens,
)


# ===== Auth =====
class SignupView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [AuthThrottle]

    def post(self, request):
        ser = SignupSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        user = ser.save()
        return Response(
            {
                "user": MeSerializer(user, context={"request": request}).data,
                **issue_tokens(user),
            },
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [AuthThrottle]

    def post(self, request):
        ser = LoginSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        user = ser.validated_data["user"]
        return Response(
            {
                "user": MeSerializer(user, context={"request": request}).data,
                **issue_tokens(user),
            }
        )


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            RefreshToken(request.data.get("refresh", "")).blacklist()
        except TokenError:
            pass
        return Response(status=status.HTTP_205_RESET_CONTENT)


# ===== Profiles =====
class MeView(generics.RetrieveUpdateAPIView):
    serializer_class = MeSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user


class UserDetailView(generics.RetrieveAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]
    lookup_field = "username"
    lookup_url_kwarg = "username"
    queryset = User.objects.all()


# ===== Follow / unfollow =====
class FollowView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, username: str):
        target = get_object_or_404(User, username=username)
        if target == request.user:
            return Response(
                {"detail": "You cannot follow yourself."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        Follow.objects.get_or_create(follower=request.user, following=target)
        return Response({"following": True}, status=status.HTTP_201_CREATED)

    def delete(self, request, username: str):
        target = get_object_or_404(User, username=username)
        Follow.objects.filter(follower=request.user, following=target).delete()
        return Response({"following": False}, status=status.HTTP_200_OK)
