// This class represents a user's post (Beta)
// This class follows the given format for database parsing:
// Ref: shttps://docs.flutter.dev/cookbook/networking/background-parsing

// This class represents the Posts seen on the social feed.
// Expected Json Example:
// {
//    "id":int,
//    "user_id":String,
//    "title":String,
//    "body":String,
//    "picture":String,
//    "created":DateTime,
//    "userinfo":{
//       "username":String,
//       "profile_picture":String?
//    }
// }

class FeedPost {
  // Primary key
  final int id;
  final String title;
  final String body;
  final String picture;
  final DateTime created;

  // The user this post belongs to (FK) -> userinfo
  final String userId;

  // Owner of the post (see below)
  final PostOwner postOwner;

  const FeedPost(
      {required this.id,
      required this.userId,
      required this.title,
      required this.body,
      required this.picture,
      required this.postOwner,
      required this.created});

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    // Parse out the nexted json before setting it for the
    // "Post" level of the class to be set
    PostOwner owner = PostOwner.fromJson(json['userinfo']);
    return FeedPost(
      id: json['id'] as int,
      postOwner: json['userinfo'] = owner,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      picture: json['picture'] as String,
      created: DateTime.now(),
    );
  }
}

// Parses out Nested Json when querying
class PostOwner {
  final String username;
  final String? profilePicture;
  const PostOwner({required this.username, required this.profilePicture});

  factory PostOwner.fromJson(Map<String, dynamic> json) {
    return PostOwner(
        username: json['username'] as String,
        profilePicture: json['profile_picture'] as String?);
  }
}
