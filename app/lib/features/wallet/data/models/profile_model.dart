import 'package:json_annotation/json_annotation.dart';

import '../../../auth/domain/entities/user.dart';

part 'profile_model.g.dart';

/// `data` of GET /users/profile, as in profile.json.
@JsonSerializable(createToJson: false)
class ProfileModel {
  const ProfileModel({required this.id, required this.name, required this.email});

  factory ProfileModel.fromJson(Map<String, dynamic> json) => _$ProfileModelFromJson(json);

  final String id;
  final String name;
  final String email;

  User toEntity() => User(id: id, name: name, email: email);
}
