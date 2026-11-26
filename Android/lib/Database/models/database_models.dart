/// Shared immutable data models returned by `Android/lib/Database/` wrappers.

enum UserRole {
  user('user'),
  admin('admin'),
  superAdmin('super_admin');

  const UserRole(this.value);
  final String value;

  static UserRole fromValue(String raw) => switch (raw) {
    'admin' => UserRole.admin,
    'super_admin' => UserRole.superAdmin,
    _ => UserRole.user,
  };
}

/// Fixed 4 admin departments supported by the Campus Safety system.
enum AdminDepartment {
  facilities('facilities', 'Facilities'),
  cleaner('cleaner', 'Cleaner'),
  parking('parking', 'Parking'),
  security('security', 'Security');

  const AdminDepartment(this.value, this.label);
  final String value;
  final String label;

  static AdminDepartment? fromNullable(String? raw) => switch (raw) {
    'facilities' => AdminDepartment.facilities,
    'cleaner' => AdminDepartment.cleaner,
    'parking' => AdminDepartment.parking,
    'security' => AdminDepartment.security,
    _ => null,
  };
}

enum DbReportStatus {
  pending('pending'),
  inProgress('in_progress'),
  resolved('resolved'),
  rejected('rejected');

  const DbReportStatus(this.value);
  final String value;

  static DbReportStatus fromValue(String raw) => switch (raw) {
    'in_progress' => DbReportStatus.inProgress,
    'resolved' => DbReportStatus.resolved,
    'rejected' => DbReportStatus.rejected,
    _ => DbReportStatus.pending,
  };
}

enum DbRankingPeriod {
  monthly('monthly'),
  allTime('all_time');

  const DbRankingPeriod(this.value);
  final String value;
}

enum ChatChannelType {
  community('community'),
  userAdmin('user_admin'),
  adminSuperAdmin('admin_super_admin');

  const ChatChannelType(this.value);
  final String value;

  static ChatChannelType fromValue(String raw) => switch (raw) {
    'user_admin' => ChatChannelType.userAdmin,
    'admin_super_admin' => ChatChannelType.adminSuperAdmin,
    _ => ChatChannelType.community,
  };
}

class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.publicAlias,
    required this.role,
    this.department,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String publicAlias;
  final UserRole role;
  final AdminDepartment? department;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['display_name'] as String,
    publicAlias: json['public_alias'] as String,
    role: UserRole.fromValue(json['role'] as String? ?? 'user'),
    department: AdminDepartment.fromNullable(json['department'] as String?),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

class CampusBoundsModel {
  const CampusBoundsModel({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    required this.updatedAt,
  });

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;
  final DateTime updatedAt;

  /// Client-side helper matching the server-side `campus_settings` GPS check.
  bool contains(double lat, double lng) =>
      lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;

  factory CampusBoundsModel.fromJson(Map<String, dynamic> json) =>
      CampusBoundsModel(
        minLat: (json['min_lat'] as num).toDouble(),
        maxLat: (json['max_lat'] as num).toDouble(),
        minLng: (json['min_lng'] as num).toDouble(),
        maxLng: (json['max_lng'] as num).toDouble(),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class CategoryMappingModel {
  const CategoryMappingModel({
    required this.categoryKey,
    required this.displayLabel,
    required this.department,
    required this.isActive,
    required this.createdAt,
  });

  final String categoryKey;
  final String displayLabel;
  final AdminDepartment department;
  final bool isActive;
  final DateTime createdAt;

  factory CategoryMappingModel.fromJson(Map<String, dynamic> json) =>
      CategoryMappingModel(
        categoryKey: json['category_key'] as String,
        displayLabel: json['display_label'] as String,
        department:
            AdminDepartment.fromNullable(json['department'] as String?) ??
            AdminDepartment.facilities,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class PresetPinRecord {
  const PresetPinRecord({
    required this.id,
    required this.blockName,
    required this.sectionTitle,
    required this.description,
    required this.lat,
    required this.lng,
    required this.imageUrls,
  });

  final String id;
  final String blockName;
  final String sectionTitle;
  final String description;
  final double lat;
  final double lng;
  final List<String> imageUrls;

  factory PresetPinRecord.fromJson(Map<String, dynamic> json) => PresetPinRecord(
    id: json['id'] as String,
    blockName: json['block_name'] as String,
    sectionTitle: json['section_title'] as String,
    description: json['description'] as String,
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    imageUrls: List<String>.from(json['image_urls'] as List? ?? const []),
  );
}

class PinReportSummaryRecord {
  const PinReportSummaryRecord({
    required this.id,
    required this.pinId,
    required this.title,
    required this.reportedAt,
    required this.isSolved,
    this.resolvedAt,
  });

  final String id;
  final String pinId;
  final String title;
  final DateTime reportedAt;
  final bool isSolved;
  final DateTime? resolvedAt;

  factory PinReportSummaryRecord.fromJson(Map<String, dynamic> json) =>
      PinReportSummaryRecord(
        id: json['id'] as String,
        pinId: json['pin_id'] as String,
        title: json['title'] as String,
        reportedAt: DateTime.parse(json['reported_at'] as String),
        isSolved: json['is_solved'] as bool? ?? false,
        resolvedAt: json['resolved_at'] != null
            ? DateTime.parse(json['resolved_at'] as String)
            : null,
      );
}

class ReportUpdateRecord {
  const ReportUpdateRecord({
    required this.id,
    required this.reportId,
    this.actorId,
    required this.status,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String reportId;
  final String? actorId;
  final DbReportStatus status;
  final String note;
  final DateTime createdAt;

  factory ReportUpdateRecord.fromJson(Map<String, dynamic> json) =>
      ReportUpdateRecord(
        id: json['id'] as String,
        reportId: json['report_id'] as String,
        actorId: json['actor_id'] as String?,
        status: DbReportStatus.fromValue(json['status'] as String),
        note: json['note'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class IncidentReportModel {
  const IncidentReportModel({
    required this.id,
    required this.reportCode,
    this.reporterId,
    this.pinId,
    required this.categoryKey,
    required this.title,
    required this.location,
    required this.description,
    required this.status,
    this.reporterLat,
    this.reporterLng,
    required this.isGpsVerified,
    required this.attachmentPaths,
    this.resolvedBy,
    required this.createdAt,
    required this.submittedAt,
    this.resolvedAt,
    required this.updatedAt,
    this.updates = const [],
  });

  final String id;
  final String reportCode;
  final String? reporterId;
  final String? pinId;
  final String categoryKey;
  final String title;
  final String location;
  final String description;
  final DbReportStatus status;
  final double? reporterLat;
  final double? reporterLng;
  final bool isGpsVerified;
  final List<String> attachmentPaths;
  final String? resolvedBy;
  final DateTime createdAt;
  final DateTime submittedAt;
  final DateTime? resolvedAt;
  final DateTime updatedAt;
  final List<ReportUpdateRecord> updates;

  bool get hasAttachment => attachmentPaths.isNotEmpty;

  factory IncidentReportModel.fromJson(Map<String, dynamic> json) {
    final rawUpdates = json['report_updates'] as List?;
    final parsedUpdates = rawUpdates == null
        ? const <ReportUpdateRecord>[]
        : rawUpdates
            .map((e) => ReportUpdateRecord.fromJson(e as Map<String, dynamic>))
            .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return IncidentReportModel(
      id: json['id'] as String,
      reportCode: json['report_code'] as String,
      reporterId: json['reporter_id'] as String?,
      pinId: json['pin_id'] as String?,
      categoryKey: json['category_key'] as String,
      title: json['title'] as String,
      location: json['location'] as String,
      description: json['description'] as String,
      status: DbReportStatus.fromValue(json['status'] as String),
      reporterLat: (json['reporter_lat'] as num?)?.toDouble(),
      reporterLng: (json['reporter_lng'] as num?)?.toDouble(),
      isGpsVerified: json['is_gps_verified'] as bool? ?? false,
      attachmentPaths: List<String>.from(
        json['attachment_paths'] as List? ?? const [],
      ),
      resolvedBy: json['resolved_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      updates: List.unmodifiable(parsedUpdates),
    );
  }
}

class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.hasMore,
    required this.limit,
    required this.offset,
  });

  final List<T> items;
  final int totalCount;
  final bool hasMore;
  final int limit;
  final int offset;
}

class LeaderboardRecord {
  const LeaderboardRecord({
    required this.profileId,
    required this.rank,
    required this.publicAlias,
    this.department,
    required this.points,
    required this.verifiedContributions,
  });

  final String profileId;
  final int rank;
  final String publicAlias;
  final AdminDepartment? department;
  final int points;
  final int verifiedContributions;

  factory LeaderboardRecord.fromJson(Map<String, dynamic> json) =>
      LeaderboardRecord(
        profileId: json['profile_id'] as String,
        rank: (json['rank'] as num).toInt(),
        publicAlias: json['public_alias'] as String,
        department: AdminDepartment.fromNullable(json['department'] as String?),
        points: (json['points'] as num).toInt(),
        verifiedContributions: (json['verified_contributions'] as num).toInt(),
      );
}

class ChatChannelModel {
  const ChatChannelModel({
    required this.id,
    required this.type,
    this.name,
    this.department,
    this.studentId,
    required this.createdAt,
  });

  final String id;
  final ChatChannelType type;
  final String? name;
  final AdminDepartment? department;
  final String? studentId;
  final DateTime createdAt;

  factory ChatChannelModel.fromJson(Map<String, dynamic> json) =>
      ChatChannelModel(
        id: json['id'] as String,
        type: ChatChannelType.fromValue(json['type'] as String),
        name: json['name'] as String?,
        department: AdminDepartment.fromNullable(json['department'] as String?),
        studentId: json['student_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class ChatMessageRecord {
  const ChatMessageRecord({
    required this.id,
    required this.channelId,
    this.senderId,
    required this.senderAlias,
    required this.senderRole,
    required this.body,
    required this.sentAt,
  });

  final String id;
  final String channelId;
  final String? senderId;
  final String senderAlias;
  final UserRole senderRole;
  final String body;
  final DateTime sentAt;

  bool get isStaff =>
      senderRole == UserRole.admin || senderRole == UserRole.superAdmin;

  factory ChatMessageRecord.fromJson(Map<String, dynamic> json) =>
      ChatMessageRecord(
        id: json['id'] as String,
        channelId: json['channel_id'] as String,
        senderId: json['sender_id'] as String?,
        senderAlias: json['sender_alias_snapshot'] as String? ?? 'Deleted User',
        senderRole: UserRole.fromValue(
          json['sender_role_snapshot'] as String? ?? 'user',
        ),
        body: json['body'] as String,
        sentAt: DateTime.parse(json['sent_at'] as String),
      );
}
