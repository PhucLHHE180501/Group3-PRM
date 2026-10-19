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
}
