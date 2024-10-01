class Memo {
  final String id;
  final String subject;
  final String message;
  final String corpcode;
  final String category;
  final String extra;
  final String status;
  final String creator;
  final String created;
  final String updated;
  final String? attachment;

  Memo({
    required this.id,
    required this.subject,
    required this.message,
    required this.corpcode,
    required this.category,
    required this.extra,
    required this.status,
    required this.creator,
    required this.created,
    required this.updated,
    this.attachment,
  });

  factory Memo.fromJson(Map<String, dynamic> json) {
    return Memo(
      id: json['id'],
      subject: json['subject'],
      message: json['message'],
      corpcode: json['corpcode'],
      category: json['category'],
      attachment: json['attachment'],
      extra: json['extra'],
      status: json['status'],
      creator: json['creator'],
      created: json['created'],
      updated: json['updated'],
    );
  }
}
