class Claim {
  final String id;
  final String category;
  final String visitDate;
  final String receiptNo;
  final String providerName;
  final double amount;
  final double amountApproved;
  final String remark;
  final String status;
  final String isPaid;
  final String created;
  final String updated;
  final String claimTypeDesc;
  final String statusDesc;
  final String imgPath;

  Claim({
    required this.id,
    required this.category,
    required this.visitDate,
    required this.receiptNo,
    required this.providerName,
    required this.amount,
    required this.amountApproved,
    required this.remark,
    required this.status,
    required this.isPaid,
    required this.created,
    required this.updated,
    required this.claimTypeDesc,
    required this.statusDesc,
    required this.imgPath,
  });

  factory Claim.fromJson(Map<String, dynamic> json) {
    return Claim(
      id: json['id'],
      category: json['category'],
      visitDate: json['visit_date'],
      receiptNo: json['receipt_no'],
      providerName: json['provider_name'],
      amount: double.parse(json['amount']),
      amountApproved: double.parse(json['amount_approved']),
      remark: json['remark'] ?? '',
      status: json['status'],
      isPaid: json['is_paid'],
      created: json['created'],
      updated: json['updated'],
      claimTypeDesc: json['claim_type_desc'],
      statusDesc: json['status_desc'],
      imgPath: json['img_path'],
    );
  }

  static List<Claim> fromJsonArray(List<dynamic> jsonArray) {
    print(jsonArray);
    return jsonArray.map((jsonItem) => Claim.fromJson(jsonItem)).toList();
  }
}
