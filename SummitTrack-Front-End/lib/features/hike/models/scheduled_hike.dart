import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduledHike {
  const ScheduledHike({
    required this.id,
    required this.mountainId,
    required this.mountainName,
    required this.trailId,
    required this.trailName,
    required this.hikeDate,
    required this.createdAt,
    this.ownerUid,
    this.updatedAt,
    this.status = activeStatus,
  });

  static const activeStatus = 'scheduled';

  factory ScheduledHike.create({
    required String mountainId,
    required String mountainName,
    required String trailId,
    required String trailName,
    required DateTime hikeDate,
    DateTime? createdAt,
    String? ownerUid,
  }) {
    if (mountainId.trim().isEmpty || mountainName.trim().isEmpty) {
      throw ArgumentError('A valid mountain must be selected.');
    }
    if (trailId.trim().isEmpty || trailName.trim().isEmpty) {
      throw ArgumentError('A valid trail must be selected.');
    }
    final date = dateOnly(hikeDate);
    final normalizedMountainId = _normalizedId(
      mountainId,
      fallback: 'unknown-mountain',
    );
    final normalizedTrailId = _normalizedId(trailId, fallback: 'unknown-trail');

    return ScheduledHike(
      id: '${_safeId(normalizedMountainId)}_${_safeId(normalizedTrailId)}_${dateKey(date)}',
      mountainId: normalizedMountainId,
      mountainName: mountainName.trim(),
      trailId: normalizedTrailId,
      trailName: trailName.trim(),
      hikeDate: date,
      createdAt: createdAt ?? DateTime.now(),
      ownerUid: _normalizedOptional(ownerUid),
    );
  }

  factory ScheduledHike.fromJson(Map<String, dynamic> json) {
    final hikeDate = _readDate(json['hikeDateKey'] ?? json['hikeDate']);
    final createdAt = _readOptionalDate(json['createdAt']);
    final updatedAt = _readOptionalDate(json['updatedAt']);

    return ScheduledHike(
      id: _readString(json['id'], fallback: 'scheduled_hike'),
      mountainId: _normalizedId(
        _readString(json['mountainId'], fallback: ''),
        fallback: 'unknown-mountain',
      ),
      mountainName: _readString(json['mountainName'], fallback: 'Unknown'),
      trailId: _normalizedId(
        _readString(json['trailId'], fallback: ''),
        fallback: 'unknown-trail',
      ),
      trailName: _readString(json['trailName'], fallback: 'Unknown Trail'),
      hikeDate: hikeDate,
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      ownerUid: _normalizedOptional(json['ownerUid'] ?? json['userId']),
      updatedAt: updatedAt,
      status: _readStatus(json['status']),
    );
  }

  factory ScheduledHike.fromFirestore({
    required String documentId,
    required Map<String, dynamic> data,
    required String ownerUid,
  }) {
    final hikeDate = _readDate(data['hikeDateKey'] ?? data['hikeDate']);
    final createdAt = _readOptionalDate(data['createdAt']);
    final updatedAt = _readOptionalDate(data['updatedAt']);

    return ScheduledHike(
      id: _readString(data['id'], fallback: documentId),
      mountainId: _normalizedId(
        _readString(data['mountainId'], fallback: ''),
        fallback: 'unknown-mountain',
      ),
      mountainName: _readString(data['mountainName'], fallback: 'Unknown'),
      trailId: _normalizedId(
        _readString(data['trailId'], fallback: ''),
        fallback: 'unknown-trail',
      ),
      trailName: _readString(data['trailName'], fallback: 'Unknown Trail'),
      hikeDate: hikeDate,
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      ownerUid:
          _normalizedOptional(data['ownerUid'] ?? data['userId']) ?? ownerUid,
      updatedAt: updatedAt,
      status: _readStatus(data['status']),
    );
  }

  final String id;
  final String mountainId;
  final String mountainName;
  final String trailId;
  final String trailName;
  final DateTime hikeDate;
  final DateTime createdAt;
  final String? ownerUid;
  final DateTime? updatedAt;
  final String status;

  /// Helper Getter: Nagre-return ng `true` kapag ang araw ngayon ay tumutugma sa nakaplanong `hikeDate`.
  bool get isHikeToday {
    final today = dateOnly(DateTime.now());
    final target = dateOnly(hikeDate);
    return today.year == target.year &&
        today.month == target.month &&
        today.day == target.day;
  }

  /// Helper Getter: Nagre-return ng `true` kapag ngayon o nakalipas na ang petsa ng hike.
  bool get isHikeDayOrPast {
    final today = dateOnly(DateTime.now());
    final target = dateOnly(hikeDate);
    return !target.isAfter(today);
  }

  bool get isActive => status == activeStatus;

  ScheduledHike copyWith({
    String? ownerUid,
    DateTime? updatedAt,
    String? status,
  }) {
    return ScheduledHike(
      id: id,
      mountainId: mountainId,
      mountainName: mountainName,
      trailId: trailId,
      trailName: trailName,
      hikeDate: hikeDate,
      createdAt: createdAt,
      ownerUid: ownerUid ?? this.ownerUid,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (ownerUid != null) 'ownerUid': ownerUid,
      'mountainId': mountainId,
      'mountainName': mountainName,
      'trailId': trailId,
      'trailName': trailName,
      'hikeDate': dateKey(hikeDate),
      'hikeDateKey': dateKey(hikeDate),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore({
    required String ownerUid,
    bool includeCreatedAt = true,
  }) {
    final normalizedOwnerUid = ownerUid.trim();
    final normalizedHikeDate = dateOnly(hikeDate);

    return {
      'id': id,
      'ownerUid': normalizedOwnerUid,
      'userId': normalizedOwnerUid,
      'mountainId': mountainId,
      'mountainName': mountainName,
      'trailId': trailId,
      'trailName': trailName,
      'hikeDate': Timestamp.fromDate(manilaMidnightUtc(normalizedHikeDate)),
      'hikeDateKey': dateKey(normalizedHikeDate),
      'status': activeStatus,
      'notificationEnabled': true,
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  bool isUpcomingFrom(DateTime today) {
    return !hikeDate.isBefore(dateOnly(today));
  }

  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String dateKey(DateTime date) {
    final normalized = dateOnly(date);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  static DateTime manilaMidnightUtc(DateTime date) {
    final normalized = dateOnly(date);
    return DateTime.utc(
      normalized.year,
      normalized.month,
      normalized.day,
    ).subtract(const Duration(hours: 8));
  }

  static DateTime manilaDateForInstant(DateTime instant) {
    final manila = instant.toUtc().add(const Duration(hours: 8));
    return DateTime(manila.year, manila.month, manila.day);
  }

  static String _safeId(String value) {
    final trimmed = value.trim().toLowerCase();
    final safe = trimmed
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return safe.isEmpty ? 'scheduled_hike' : safe;
  }

  static String _normalizedId(String value, {required String fallback}) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty ? fallback : normalized;
  }

  static String _readString(Object? value, {required String fallback}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  static String _readStatus(Object? value) {
    final text = value?.toString().trim().toLowerCase();
    return text == null || text.isEmpty ? activeStatus : text;
  }

  static DateTime _readDate(Object? value) {
    return _readOptionalDate(value) ?? dateOnly(DateTime.now());
  }

  static DateTime? _readOptionalDate(Object? value) {
    if (value is Timestamp) {
      final manilaDate = value.toDate().toUtc().add(const Duration(hours: 8));
      return DateTime(manilaDate.year, manilaDate.month, manilaDate.day);
    }

    if (value is DateTime) {
      return dateOnly(value);
    }

    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed == null ? null : dateOnly(parsed);
    }

    return null;
  }

  static String? _normalizedOptional(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
