class Leave {
  final String id;
  final String userId;
  final String companyId;
  final DateTime fromDate;
  final DateTime toDate;
  final LeaveType leaveType; // Changed to LeaveType instead of String
  final String days;
  final String status;
  final String statusDesc;
  final String? reason;
  final String? remark;
  final String? imgPath;

  Leave({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.fromDate,
    required this.toDate,
    required this.leaveType,
    required this.days,
    required this.status,
    required this.statusDesc,
    this.remark,
    this.reason,
    this.imgPath,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
        id: json['id'],
        userId: json['u_id'],
        companyId: json['c_id'],
        fromDate: DateTime.parse(json['from_date']),
        toDate: DateTime.parse(json['to_date']),
        leaveType: LeaveType.fromJson({
          'id': json['leave_type'],
          'name': json['leave_type_desc'],
        }),
        days: json['days'],
        status: json['status'],
        statusDesc: json['status_desc'],
        reason: json['reason'],
        imgPath: json['img_path'],
        remark: json['remark']);
  }
}

class LeaveType {
  final String id;
  final String name;

  LeaveType({required this.id, required this.name});

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: json['id'],
      name: json['name'],
    );
  }
}
