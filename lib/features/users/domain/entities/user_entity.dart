enum UserRelation { none, pending, accepted }

class UserEntity {
  final String id;
  final String name;
  final String profileUrl;
  final UserRelation relation;
  final String bio;
  final Map<String, String> links;

  UserEntity({
    required this.id,
    required this.name,
    this.profileUrl = '',
    this.relation = UserRelation.none,
    this.bio = '',
    this.links = const {},
  });

  UserEntity copyWith({
    String? id,
    String? name,
    String? profileUrl,
    UserRelation? relation,
    String? bio,
    Map<String, String>? links,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      profileUrl: profileUrl ?? this.profileUrl,
      relation: relation ?? this.relation,
      bio: bio ?? this.bio,
      links: links ?? this.links,
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

