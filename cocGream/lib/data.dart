// Models for CockroachGram — populated from the API.
//
// Field names match the backend's JSON exactly. Compatibility getters on
// `Post` (name/handle/initials/verified) keep the existing widgets working.

/// Compact count formatter — 12400 -> "12.4K", 4_200_000 -> "4.2M".
String fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

// ===== Reference data (constant, not content) =====
// The only static list kept — the 28 + 8 administrative regions of India,
// used in the signup state dropdown. Everything else (stories, topic tags,
// posts, notifications, trending) is fetched from the API.
const kStates = <String>[
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh', 'Goa',
  'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka', 'Kerala',
  'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland',
  'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
  'Uttar Pradesh', 'Uttarakhand', 'West Bengal', 'Delhi', 'Jammu & Kashmir',
  'Ladakh', 'Puducherry', 'Chandigarh',
];

// ===== User =====
class UserStats {
  final int posts;
  final int followers;
  final int following;
  final int roars;
  const UserStats({
    required this.posts,
    required this.followers,
    required this.following,
    required this.roars,
  });
  factory UserStats.fromJson(Map<String, dynamic> j) => UserStats(
        posts: (j['posts'] as num?)?.toInt() ?? 0,
        followers: (j['followers'] as num?)?.toInt() ?? 0,
        following: (j['following'] as num?)?.toInt() ?? 0,
        roars: (j['roars'] as num?)?.toInt() ?? 0,
      );
  static const empty = UserStats(posts: 0, followers: 0, following: 0, roars: 0);
}

class User {
  final int id;
  final String username;
  final String handle;
  final String name;
  final String initials;
  final bool verified;
  final String memberNo;
  final String bio;
  final String state;
  final String? avatar;
  final String? cover;
  final String joinedLabel;
  final UserStats stats;
  final bool isFollowing;
  final String? email;
  final String? phone;

  const User({
    required this.id,
    required this.username,
    required this.handle,
    required this.name,
    required this.initials,
    required this.verified,
    required this.memberNo,
    required this.bio,
    required this.state,
    this.avatar,
    this.cover,
    required this.joinedLabel,
    this.stats = UserStats.empty,
    this.isFollowing = false,
    this.email,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: (j['id'] as num).toInt(),
        username: j['username'] as String,
        handle: j['handle'] as String? ?? '@${j['username']}',
        name: j['name'] as String? ?? '',
        initials: j['initials'] as String? ?? '?',
        verified: j['verified'] as bool? ?? false,
        memberNo: j['member_no'] as String? ?? '',
        bio: j['bio'] as String? ?? '',
        state: j['state'] as String? ?? '',
        avatar: j['avatar'] as String?,
        cover: j['cover'] as String?,
        joinedLabel: j['joined_label'] as String? ?? '',
        stats: j['stats'] is Map<String, dynamic>
            ? UserStats.fromJson(j['stats'] as Map<String, dynamic>)
            : UserStats.empty,
        isFollowing: j['is_following'] as bool? ?? false,
        email: j['email'] as String?,
        phone: j['phone'] as String?,
      );
}

// ===== Post =====
class PostMedia {
  final String? url;
  final String caption;
  const PostMedia({this.url, required this.caption});
  factory PostMedia.fromJson(Map<String, dynamic> j) => PostMedia(
        url: j['url'] as String?,
        caption: j['caption'] as String? ?? '',
      );
}

class Post {
  final int id;
  final User author;
  final String text;
  final String audience;
  final String location;
  final String time;
  final PostMedia? media;
  final List<String> hashtags;
  int likes;
  int comments;
  int reposts;
  bool liked;
  bool reposted;
  bool bookmarked;

  Post({
    required this.id,
    required this.author,
    required this.text,
    required this.audience,
    required this.location,
    required this.time,
    this.media,
    this.hashtags = const [],
    this.likes = 0,
    this.comments = 0,
    this.reposts = 0,
    this.liked = false,
    this.reposted = false,
    this.bookmarked = false,
  });

  factory Post.fromJson(Map<String, dynamic> j) => Post(
        id: (j['id'] as num).toInt(),
        author: User.fromJson(j['author'] as Map<String, dynamic>),
        text: j['text'] as String? ?? '',
        audience: j['audience'] as String? ?? 'public',
        location: j['location'] as String? ?? '',
        time: j['time'] as String? ?? '',
        media: j['media'] is Map<String, dynamic>
            ? PostMedia.fromJson(j['media'] as Map<String, dynamic>)
            : null,
        hashtags:
            (j['hashtags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        likes: (j['likes'] as num?)?.toInt() ?? 0,
        comments: (j['comments'] as num?)?.toInt() ?? 0,
        reposts: (j['reposts'] as num?)?.toInt() ?? 0,
        liked: j['liked'] as bool? ?? false,
        reposted: j['reposted'] as bool? ?? false,
        bookmarked: j['bookmarked'] as bool? ?? false,
      );

  // ----- Convenience getters so the existing widgets keep working -----
  String get name => author.name;
  String get handle => author.handle;
  String get initials => author.initials;
  bool get verified => author.verified;
}

// ===== Trend =====
class Trend {
  final int rank;
  final String tag;
  final String category;
  final String count;
  final bool hot;
  const Trend({
    required this.rank,
    required this.tag,
    required this.category,
    required this.count,
    required this.hot,
  });
  factory Trend.fromJson(Map<String, dynamic> j) => Trend(
        rank: (j['rank'] as num).toInt(),
        tag: j['tag'] as String,
        category: j['category'] as String? ?? '',
        count: j['count'] as String? ?? '',
        hot: j['hot'] as bool? ?? false,
      );
}

// ===== Notification =====
enum NotifType { like, comment, follow, repost, mention }

NotifType _parseNotifType(String s) =>
    NotifType.values.firstWhere((t) => t.name == s, orElse: () => NotifType.like);

class Notif {
  final int id;
  final NotifType type;
  final String name;
  final String initials;
  final String time;
  final String text;
  final String? preview;
  final bool unread;
  final bool verified;
  const Notif({
    required this.id,
    required this.type,
    required this.name,
    required this.initials,
    required this.time,
    required this.text,
    this.preview,
    this.unread = false,
    this.verified = false,
  });
  factory Notif.fromJson(Map<String, dynamic> j) => Notif(
        id: (j['id'] as num).toInt(),
        type: _parseNotifType(j['type'] as String? ?? 'like'),
        name: j['name'] as String? ?? '',
        initials: j['initials'] as String? ?? '?',
        time: j['time'] as String? ?? '',
        text: j['text'] as String? ?? '',
        preview: (j['preview'] as String?)?.isEmpty == true
            ? null
            : j['preview'] as String?,
        unread: j['unread'] as bool? ?? false,
        verified: j['verified'] as bool? ?? false,
      );
}
