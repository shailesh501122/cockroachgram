"""Smoke tests for the users + auth flow."""
import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from apps.users.models import User


@pytest.fixture
def api():
    return APIClient()


@pytest.mark.django_db
def test_signup_creates_user_and_returns_tokens(api):
    payload = {
        "name": "Aarav Mehta",
        "username": "aarav_test",
        "contact": "aarav_test@cjp.in",
        "password": "cockroach-strong-1",
        "state": "Maharashtra",
        "agree": True,
    }
    r = api.post(reverse("auth:signup"), payload, format="json")
    assert r.status_code == 201, r.content
    body = r.json()
    assert "access" in body and "refresh" in body
    assert body["user"]["username"] == "aarav_test"
    assert body["user"]["member_no"].isdigit()
    assert User.objects.filter(username="aarav_test").exists()


@pytest.mark.django_db
def test_signup_rejects_unsigned_manifesto(api):
    r = api.post(
        reverse("auth:signup"),
        {
            "name": "No Manifesto",
            "username": "no_manifesto",
            "contact": "nm@cjp.in",
            "password": "cockroach-strong-1",
            "state": "Delhi",
            "agree": False,
        },
        format="json",
    )
    assert r.status_code == 400
    assert "agree" in r.json()


@pytest.mark.django_db
def test_login_with_username(api):
    User.objects.create_user(
        username="loginer",
        password="cockroach-strong-1",
        name="Login Er",
        state="Karnataka",
    )
    r = api.post(
        reverse("auth:login"),
        {"identifier": "loginer", "password": "cockroach-strong-1"},
        format="json",
    )
    assert r.status_code == 200
    assert r.json()["user"]["username"] == "loginer"


@pytest.mark.django_db
def test_me_requires_auth(api):
    assert api.get(reverse("users:me")).status_code == 401
