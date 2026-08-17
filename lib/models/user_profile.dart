/// ユーザー（保護者・子ども）プロフィール
class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final int defaultChildAge;
  final int defaultParticipantCount;
  final String? createdAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.defaultChildAge,
    required this.defaultParticipantCount,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'defaultChildAge': defaultChildAge,
      'defaultParticipantCount': defaultParticipantCount,
      'createdAt': createdAt,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '保護者さま',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      defaultChildAge: (json['defaultChildAge'] as num?)?.toInt() ?? 6,
      defaultParticipantCount: (json['defaultParticipantCount'] as num?)?.toInt() ?? 2,
      createdAt: json['createdAt'] as String?,
    );
  }
}
