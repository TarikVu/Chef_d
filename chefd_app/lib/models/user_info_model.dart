// This class represents a user's info (Beta)
// This class follows the given format for database parsing:
// Ref: shttps://docs.flutter.dev/cookbook/networking/background-parsing
class UserInfo {
  final String userId;
  final int difficulty;
  final int timespend;
  final String username;
  final String? profilePicture;

  const UserInfo(
      {required this.userId,
      required this.difficulty,
      required this.timespend,
      required this.username,
      required this.profilePicture});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['user_id'] as String,
      difficulty: json['difficulty'] as int,
      timespend: json['timespend'] as int,
      username: json['username'] as String,
      profilePicture: json['profile_picture'] as String?,
    );
  }
}
