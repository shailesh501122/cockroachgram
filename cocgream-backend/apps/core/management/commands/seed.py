"""
`python manage.py seed` — populate the database with the CockroachGram demo.

Idempotent — running it twice doesn't create duplicate users / posts.
"""
import os
import random

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from apps.notifications.models import Notification, NotifType
from apps.posts.models import Comment, Hashtag, Like, Post, Repost
from apps.users.models import Follow, User


DEMO_USERS = [
    # (username, name, state, verified, bio)
    ("aaravm", "Aarav Mehta", "Maharashtra", True,
     "Citizen-organizer. Trying to make the streets vote.\n"
     "Founder, Youth For Roti. Cockroach since day one. 🪳"),
    ("arundhativ", "Arundhati Verma", "Uttar Pradesh", True,
     "Journalist. I write what the headlines bury."),
    ("manishk", "Manish Khanna", "Maharashtra", False,
     "Small-business owner. 73 lakh unemployed isn't a statistic."),
    ("cjp_official", "Cockroach Janta Party", "Delhi", True,
     "🪳 The Cockroach doesn't ask for permission to survive — it adapts."),
    ("priyas", "Priya Sharma", "Karnataka", False,
     "22. Voting for the first time. Bringing seven friends."),
    ("ravib", "Ravi Bansal", "Rajasthan", False, "Reading the manifesto in three languages."),
    ("anjalin", "Anjali Nair", "Kerala", False, "Teacher. Education is the only ladder."),
    ("vikrami", "Vikram Iyer", "Tamil Nadu", False, "Civic-tech engineer."),
    ("snehap", "Sneha Pillai", "Kerala", False, "Doctor. Healthcare is a right."),
]


DEMO_POSTS = [
    # (author_username, text, audience, has_media, media_caption)
    ("arundhativ",
     "They called us pests. We called ourselves citizens. The streets remember "
     "every promise that was buried. Today we put them on the ballot. "
     "#MainBhiCockroach #RozgaarDo",
     "public", True, "Rally at GPO Lucknow · 18,400 attendees"),
    ("manishk",
     "GDP growth doesn't reach my chai stall. 73 lakh applications, "
     "90,000 vacancies. The math is the message. #Economy #Youth",
     "public", False, ""),
    ("cjp_official",
     "Manifesto v2 drops Friday. 12 demands. Zero compromises. The Cockroach "
     "doesn't ask for permission to survive — it adapts. Stay tuned. "
     "#MainBhiCockroach #ManifestoV2",
     "public", True, "Manifesto V2 · Cover Art"),
    ("priyas",
     "First-time voter. I'm 22. I'm tired. I'm voting. And I'm bringing "
     "seven friends. #Youth #VoteCockroach",
     "public", False, ""),
    ("ravib",
     "Reading the manifesto with my dad. Hindi version is unreal. "
     "#ManifestoV2 #MainBhiCockroach",
     "public", False, ""),
    ("anjalin",
     "Government schools in my district need teachers, not slogans. "
     "#EducationKaHaq",
     "public", False, ""),
    ("vikrami",
     "Built a hashtag tracker for the movement. Open-source. PRs welcome. "
     "#CorruptionFree",
     "public", False, ""),
    ("snehap",
     "Primary health centres in rural KL are running on borrowed time. "
     "#WomenInPolitics",
     "public", False, ""),
]


class Command(BaseCommand):
    help = "Populate the demo dataset for CockroachGram."

    def add_arguments(self, parser):
        parser.add_argument(
            "--wipe",
            action="store_true",
            help="Delete existing demo posts/users before seeding.",
        )

    @transaction.atomic
    def handle(self, *args, **opts):
        if opts["wipe"]:
            self.stdout.write("🪳 wiping demo data…")
            Notification.objects.all().delete()
            Post.objects.all().delete()
            Hashtag.objects.all().delete()
            Follow.objects.all().delete()
            User.objects.filter(is_superuser=False).delete()

        # --- Admin / superuser ---
        admin_username = os.environ.get("ADMIN_USERNAME", "admin")
        admin_email = os.environ.get("ADMIN_EMAIL", "admin@cockroachgram.in")
        admin_password = os.environ.get("ADMIN_PASSWORD", "cockroach-admin")
        admin, created = User.objects.get_or_create(
            username=admin_username,
            defaults={
                "email": admin_email,
                "name": "Admin",
                "is_staff": True,
                "is_superuser": True,
                "verified": True,
            },
        )
        if created:
            admin.set_password(admin_password)
            admin.save()
            self.stdout.write(self.style.SUCCESS(
                f"  ✓ admin @{admin_username} / {admin_password}"
            ))

        # --- Demo users ---
        users: dict[str, User] = {}
        for username, name, state, verified, bio in DEMO_USERS:
            u, created = User.objects.get_or_create(
                username=username,
                defaults={
                    "name": name,
                    "state": state,
                    "verified": verified,
                    "bio": bio,
                    "agreed_manifesto_at": timezone.now(),
                },
            )
            if created:
                u.set_password("cockroach-demo")
                u.save()
            users[username] = u
        self.stdout.write(f"  ✓ {len(users)} demo users (password: cockroach-demo)")

        # --- Follows: everyone follows @aaravm and @cjp_official ---
        aarav = users["aaravm"]
        cjp = users["cjp_official"]
        for u in users.values():
            if u != aarav:
                Follow.objects.get_or_create(follower=u, following=aarav)
            if u != cjp:
                Follow.objects.get_or_create(follower=u, following=cjp)

        # --- Posts ---
        for username, text, audience, has_media, caption in DEMO_POSTS:
            author = users[username]
            if Post.objects.filter(author=author, text=text).exists():
                continue
            Post.objects.create(
                author=author,
                text=text,
                audience=audience,
                location=author.state,
                media_caption=caption if has_media else "",
            )
        self.stdout.write(f"  ✓ {Post.objects.count()} posts")

        # --- Engagement: random likes / reposts / comments on each post ---
        all_users = list(users.values())
        for post in Post.objects.all():
            likers = random.sample(all_users, k=random.randint(3, len(all_users)))
            for liker in likers:
                Like.objects.get_or_create(post=post, user=liker)
            for reposter in random.sample(all_users, k=random.randint(1, 4)):
                Repost.objects.get_or_create(post=post, user=reposter)
            for commenter in random.sample(all_users, k=random.randint(0, 2)):
                if commenter == post.author:
                    continue
                Comment.objects.get_or_create(
                    post=post,
                    author=commenter,
                    text=random.choice([
                        "Brother, this is exactly what we've been saying. Count me in.",
                        "Voting starts at home. Spreading this.",
                        "🪳",
                        "Respect.",
                        "On the streets tomorrow.",
                    ]),
                )

        self.stdout.write(self.style.SUCCESS(
            "🪳 Seed complete. "
            f"Users={User.objects.count()} "
            f"Posts={Post.objects.count()} "
            f"Likes={Like.objects.count()} "
            f"Reposts={Repost.objects.count()} "
            f"Comments={Comment.objects.count()} "
            f"Notifications={Notification.objects.count()}"
        ))
