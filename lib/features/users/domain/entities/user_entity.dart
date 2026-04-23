enum UserRelation { none, pending, accepted, blocked }

class UserEntity {
  final String id;
  final String name;
  final String profileUrl;
  final UserRelation relation;
  final String bio;
  final Map<String, String> links;
  final int followersCount;
  final int followingCount;
  final int postsCount;

  UserEntity({
    required this.id,
    required this.name,
    this.profileUrl = '',
    this.relation = UserRelation.none,
    this.bio = '',
    this.links = const {},
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.email = '',
    this.cameraSettings = const {'alwaysStartOnFrontCamera': false, 'toolbarSide': 'left'},
  });

  final String email;
  final Map<String, dynamic> cameraSettings;

  UserEntity copyWith({
    String? id,
    String? name,
    String? profileUrl,
    UserRelation? relation,
    String? bio,
    Map<String, String>? links,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    String? email,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      profileUrl: profileUrl ?? this.profileUrl,
      relation: relation ?? this.relation,
      bio: bio ?? this.bio,
      links: links ?? this.links,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      email: email ?? this.email,
    );
  }

}

class ContactEntity {
  final String id;
  final String name;
  final String statusMessage;
  final String profileUrl;

  ContactEntity({
    required this.id,
    required this.name,
    required this.statusMessage,
    this.profileUrl = '',
  });
}

