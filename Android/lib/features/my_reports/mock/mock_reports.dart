import '../models/report_ui_model.dart';

const demoStudentId = 'demo-student';

/// Fictional incidents and locations. No real student records are used.
List<ReportUiModel> mockReports() {
  final seeds = [
    (
      'DEMO-106',
      'Dim walkway near the learning centre',
      'lighting',
      'Demo Learning Centre · East path',
      ReportStatus.pending,
      'Two walkway lights appear dim after sunset. Please check visibility along this public path.',
      true,
    ),
    (
      'DEMO-105',
      'Loose handrail at the library steps',
      'facilities',
      'Demo Library · South steps',
      ReportStatus.inProgress,
      'The lower section of the handrail feels loose. The walkway remains open.',
      true,
    ),
    (
      'DEMO-104',
      'Obstructed accessible entrance',
      'access',
      'Demo Student Hall · Entrance B',
      ReportStatus.resolved,
      'Movable furniture was partially blocking the accessible entrance.',
      false,
    ),
    (
      'DEMO-103',
      'Overflowing recycling station',
      'environment',
      'Demo Courtyard · North corner',
      ReportStatus.resolved,
      'The recycling area needs collection and a routine cleaning check.',
      false,
    ),
    (
      'DEMO-102',
      'Walkway light follow-up',
      'lighting',
      'Demo Learning Centre · West path',
      ReportStatus.rejected,
      'A follow-up observation about the same walkway light already being handled in an existing case.',
      false,
    ),
    (
      'DEMO-101',
      'Uneven paving by the dining area',
      'facilities',
      'Demo Dining Hall · Public path',
      ReportStatus.resolved,
      'A paving tile is raised above the surrounding path and may present a trip hazard.',
      true,
    ),
  ];
  return [
    for (var i = 0; i < seeds.length; i++)
      ReportUiModel(
        id: seeds[i].$1,
        studentId: demoStudentId,
        title: seeds[i].$2,
        categoryKey: seeds[i].$3,
        location: seeds[i].$4,
        description: seeds[i].$6,
        createdAt: DateTime(2026, 11, 21 - i * 2, 9 + i, 15),
        submittedAt: DateTime(2026, 11, 21 - i * 2, 9 + i, 15),
        status: seeds[i].$5,
        hasAttachment: seeds[i].$7,
        updates: [
          ReportUpdate(
            at: DateTime(2026, 11, 21 - i * 2, 9 + i, 15),
            status: ReportStatus.pending,
            note: 'Fictional report received for review.',
          ),
          if (seeds[i].$5 != ReportStatus.pending)
            ReportUpdate(
              at: DateTime(2026, 11, 22 - i * 2, 10),
              status: seeds[i].$5,
              note: switch (seeds[i].$5) {
                ReportStatus.inProgress =>
                  'Demo facilities team is reviewing the issue.',
                ReportStatus.resolved =>
                  'Demo corrective work completed and checked.',
                ReportStatus.rejected =>
                  'Duplicate of an existing demo case; no new case required.',
                ReportStatus.pending => 'Awaiting demo review.',
              },
            ),
        ],
      ),
  ];
}
