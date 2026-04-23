import 'package:equatable/equatable.dart';

class ChannelEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String avatarUrl;
  final int memberCount;
  final String adminId;

  const ChannelEntity({
    required this.id,
    required this.name,
    this.description = '',
    this.avatarUrl = '',
    this.memberCount = 0,
    required this.adminId,
  });

  @override
  List<Object?> get props => [id, name, description, avatarUrl, memberCount, adminId];
}
