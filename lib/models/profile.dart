class Profile {
  final String name;
  final String? company_name;
  final String? position;
  final String? profilePicture;

  Profile({
    required this.name,
    this.company_name,
    this.position,
    this.profilePicture,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'],
      company_name: json['company_name'],
      position: json['position'],
      profilePicture: json['img_path'],
    );
  }
}
