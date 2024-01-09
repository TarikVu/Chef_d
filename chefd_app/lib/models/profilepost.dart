// This class represents a user's post (Beta)
// This class follows the given format for database parsing:
// Ref: shttps://docs.flutter.dev/cookbook/networking/background-parsing

// This class represents a post shown on a User's Profile.
// It is also used in post_details.dart and other_profile.dart.
// This class is different from feedpost.dart as the jsons returned are different.

// Example expected Json:
// {
//    "id":int,
//    "user_id":String,
//    "title":String,
//    "body":String,
//    "picture":String,
//    "created":DateTime,
// }

class ProfilePost {
  // Primary Key:
  final int id;

  // The user this post belongs to (FK) -> auth.user
  final String userId;

  // Expected fields:
  final String title;
  final String body;
  final String picture;
  final DateTime created;

  const ProfilePost(
      {required this.id,
      required this.userId,
      required this.title,
      required this.body,
      required this.picture,
      required this.created});

  // Parse from json:
  factory ProfilePost.fromJson(Map<String, dynamic> json) {
    return ProfilePost(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      picture: json['picture'] as String,
      created: DateTime.now(),
    );
  }
}
