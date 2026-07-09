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
  });

  factory ScheduledHike.create({
    required String mountainId,
    required String mountainName,
    required String trailId,
    required String trailName,
    required DateTime hikeDate,
    DateTime? createdAt,
    String? ownerUid,
  }) {
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

  ScheduledHike copyWith({String? ownerUid, DateTime? updatedAt}) {
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
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore({
    required String ownerUid,
    String? ownerEmail,
  }) {
    final normalizedOwnerUid = ownerUid.trim();
    final normalizedOwnerEmail = ownerEmail?.trim();
    final normalizedHikeDate = dateOnly(hikeDate);

    return {
      'id': id,
      'ownerUid': normalizedOwnerUid,
      'userId': normalizedOwnerUid,
      if (normalizedOwnerEmail != null && normalizedOwnerEmail.isNotEmpty)
        'ownerEmail': normalizedOwnerEmail,
      'mountainId': mountainId,
      'mountainName': mountainName,
      'trailId': trailId,
      'trailName': trailName,
      'hikeDate': Timestamp.fromDate(
        DateTime.utc(
          normalizedHikeDate.year,
          normalizedHikeDate.month,
          normalizedHikeDate.day,
        ),
      ),
      'hikeDateKey': dateKey(normalizedHikeDate),
      'createdAt': Timestamp.fromDate(createdAt.toUtc()),
      'updatedAt': Timestamp.fromDate((updatedAt ?? DateTime.now()).toUtc()),
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

  static DateTime _readDate(Object? value) {
    return _readOptionalDate(value) ?? dateOnly(DateTime.now());
  }

  static DateTime? _readOptionalDate(Object? value) {
    if (value is Timestamp) {
      final utcDate = value.toDate().toUtc();
      return DateTime(utcDate.year, utcDate.month, utcDate.day);
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
