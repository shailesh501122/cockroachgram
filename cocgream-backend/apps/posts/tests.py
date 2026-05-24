"""Smoke tests for the post + feed + trending flow."""
import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from apps.posts.models import Hashtag, Like, Post
from apps.users.models import User


@pytest.fixture
def me(db):
    return User.objects.create_user(
        username="me", password="cockroach-strong-1",
        name="Me Self", state="Maharashtra",
    )


@pytest.fixture
def api(me):
    c = APIClient()
    c.force_authenticate(me)
    return c


def test_create_post_extracts_hashtags(api, me):
    r = api.post(
        reverse("posts:list"),
        {"text": "Voting #MainBhiCockroach #RozgaarDo", "audience": "public"},
        format="json",
    )
    assert r.status_code == 201, r.content
    post = Post.objects.get(pk=r.json()["id"])
    assert {h.tag for h in post.hashtags.all()} == {"mainbhicockroach", "rozgaardo"}


def test_feed_lists_authenticated_user_posts(api, me):
    Post.objects.create(author=me, text="hello world", audience="public")
    r = api.get(reverse("posts:list") + "?tab=foryou")
    assert r.status_code == 200
    results = r.json()["results"] if "results" in r.json() else r.json()
    assert any(p["text"] == "hello world" for p in results)


def test_like_toggle(api, me):
    post = Post.objects.create(author=me, text="x", audience="public")
    r = api.post(reverse("posts:like", args=[post.pk]))
    assert r.status_code == 201
    assert Like.objects.filter(post=post, user=me).exists()

    r = api.delete(reverse("posts:like", args=[post.pk]))
    assert r.status_code == 200
    assert not Like.objects.filter(post=post, user=me).exists()


def test_trending_returns_hot_tags(api, me):
    p = Post.objects.create(author=me, text="#trendingnow", audience="public")
    p.hashtags.add(Hashtag.objects.get_or_create(tag="trendingnow")[0])
    r = api.get(reverse("trending:hashtags") + "?window=now")
    assert r.status_code == 200
    tags = [t["tag"] for t in r.json()["results"]]
    assert "#trendingnow" in tags
