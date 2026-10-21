class StaffScheduleModel {
  final int id;
  final int staffId;
  final DateTime workDate;
  final String startTime;
  final String endTime;
  final bool isDayOff;
  final String? note;

  StaffScheduleModel({
    required this.id,
    required this.staffId,
    required this.workDate,
    required this.startTime,
    required this.endTime,
    this.isDayOff = false,
    this.note,
  });

  factory StaffScheduleModel.fromJson(Map<String, dynamic> json) {
    return StaffScheduleModel(
      id: (json['id'] as num).toInt(),
      staffId: (json['staffId'] as num).toInt(),
      workDate: DateTime.parse(json['workDate'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      isDayOff: json['isDayOff'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }
}
