class Payslip {
  final String id;
  final String userId;
  final String month;
  final String year;
  final String category;
  final List<String> imgPaths;
  final String imgTitle;
  final String updated;

  Payslip({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.category,
    required this.imgPaths,
    required this.imgTitle,
    required this.updated,
  });

  factory Payslip.fromJson(Map<String, dynamic> json) {
    return Payslip(
      id: json['id'],
      userId: json['u_id'],
      month: json['month'],
      year: json['year'],
      category: json['category'],
      imgPaths: List<String>.from(json['img_path']),
      imgTitle: json['img_title'],
      updated: json['updated'],
    );
  }
}
