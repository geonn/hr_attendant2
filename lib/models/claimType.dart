class ClaimType {
  final String id;
  final String name;

  ClaimType({
    required this.id,
    required this.name,
  });

  factory ClaimType.fromJson(Map<String, dynamic> json) {
    return ClaimType(
      id: json['id'],
      name: json['name'],
    );
  }
}
