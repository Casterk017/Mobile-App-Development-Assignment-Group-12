import 'package:flutter/material.dart';

enum ReportStatus {
  pending('pending', Color(0xFF825500)),
  inProgress('inProgress', Color(0xFF235BA0)),
  resolved('resolved', Color(0xFF176C50)),
  rejected('rejected', Color(0xFFA7343D));

  const ReportStatus(this.labelKey, this.color);
  final String labelKey;
  final Color color;
  Color displayColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? switch (this) {
          ReportStatus.pending => const Color(0xFFF0CF87),
          ReportStatus.inProgress => const Color(0xFFA8CEFF),
          ReportStatus.resolved => const Color(0xFF9BDDBD),
          ReportStatus.rejected => const Color(0xFFFFB4B6),
        }
      : color;
}

/// Technical delivery and incident processing are deliberately independent.
enum SubmissionState { submitted, failed, draft }

class ReportUpdate {
  const ReportUpdate({
    required this.at,
    required this.status,
    required this.note,
  });
  final DateTime at;
  final ReportStatus status;
  final String note;
}

/// Read-only presentation contract. The host must supply authorized records.
class ReportUiModel {
  ReportUiModel({
    required this.id,
    required this.studentId,
    required this.title,
    required this.categoryKey,
    required this.location,
    required this.description,
    required this.createdAt,
    this.submittedAt,
    this.status,
    this.submissionState = SubmissionState.submitted,
    this.hasAttachment = false,
    List<ReportUpdate> updates = const [],
  }) : updates = List.unmodifiable(updates) {
    if (submissionState == SubmissionState.submitted &&
        (status == null || submittedAt == null)) {
      throw ArgumentError(
        'Successfully submitted reports require a status and submission time.',
      );
    }
    if (submissionState != SubmissionState.submitted &&
        (status != null || submittedAt != null)) {
      throw ArgumentError(
        'Unsubmitted attempts cannot have processing status or submission time.',
      );
    }
  }

  final String id;
  final String studentId;
  final String title;
  final String categoryKey;
  final String location;
  final String description;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final ReportStatus? status;
  final SubmissionState submissionState;
  final bool hasAttachment;
  final List<ReportUpdate> updates;

  DateTime get displayDate => submittedAt ?? createdAt;
  ReportUpdate? get latestUpdate => updates.isEmpty
      ? null
      : updates.reduce((a, b) => a.at.isAfter(b.at) ? a : b);
}
