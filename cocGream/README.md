# 🪳 CockroachGram

> *"Your political voice. Unsilenced."*

A Flutter implementation of **CockroachGram** — a political social-media app
concept for India's youth, ported pixel-faithfully from a Claude Design
HTML/CSS/JS handoff bundle (`CockroachGram.html`).

## Screens

All 7 designed screens are implemented as a real, navigable app:

1. **Splash** — brand mark, tagline, Join / Log in CTAs
2. **Sign Up** — 3-step flow (identity → credentials → state + manifesto) with
   live validation and progress dots
3. **Feed** — app header, stories row, For You / Following / State / Trending
   tabs, post cards with amber hashtags, like/repost interactions, compose FAB
4. **Compose** — audience selector, topic-tag chips, character counter, media
   toolbar; new posts appear at the top of the feed
5. **Trending** — ranked hashtag list with 🔥 indicators
6. **Profile** — cockroach-pattern cover, member badge, 4-stat row, post grid
7. **Notifications** — type-coded alerts with unread dots and inline follow

Compose is wired live: posting from the FAB or the centre nav button inserts a
new post into the feed.

## Design system

Tokens are ported verbatim from the bundle's `styles.css` into
[lib/theme.dart](lib/theme.dart):

- **Colors** — deep-brown backgrounds, amber `#c8720a → #ff9f2e` accent gradient
- **Type** — Bebas Neue (display), Syne (headings), DM Sans (body), via
  `google_fonts`
- **Style** — dark, glassmorphism nav, amber glow, 10–28px radii

## Project layout

```
lib/
  main.dart            — app entry, theme
  theme.dart           — design tokens (CG) + type helpers (T)
  data.dart            — models + sample data
  widgets/             — Avatar, AppHeader, CGBottomNav, PostCard, …
  screens/             — splash, signup, main_shell, feed, compose,
                         trending, profile, notifications
```

## Running

```sh
flutter pub get
flutter run            # pick a device — Android / Windows / Chrome
```

Verified with `flutter analyze` (clean), `flutter test`, and `flutter build web`.
