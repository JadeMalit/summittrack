import 'package:cloud_firestore/cloud_firestore.dart';

class TrailPhotoModel {
  const TrailPhotoModel({
    required this.id,
    required this.uid,
    required this.trailId,
    required this.downloadUrl,
    required this.storagePath,
    required this.createdAt,
    required this.updatedAt,
    required this.fileName,
    this.ownerEmail,
  });

  final String id;
  final String uid;
  final String trailId;
  final String downloadUrl;
  final String storagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String fileName;
  final String? ownerEmail;

  String get photoUrl => downloadUrl;

  factory TrailPhotoModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final referenceParts = document.reference.path.split('/');
    final createdAt =
        _readDate(data['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final updatedAt = _readDate(data['updatedAt']) ?? createdAt;

    return TrailPhotoModel(
      id: _readString(data['id']) ?? document.id,
      uid:
          _readString(data['uid']) ??
          _readString(data['ownerUid']) ??
          _readString(data['userId']) ??
          _pathSegmentAfter(referenceParts, 'users'),
      trailId:
          _readString(data['trailId']) ??
          _pathSegmentAfter(referenceParts, 'trail_photos'),
      downloadUrl:
          _readString(data['downloadUrl']) ??
          _readString(data['photoUrl']) ??
          _readString(data['url']) ??
          '',
      storagePath:
          _readString(data['storagePath']) ?? _readString(data['path']) ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      fileName: _readString(data['fileName']) ?? 'trail-photo.jpg',
      ownerEmail: _readString(data['ownerEmail']) ?? _readString(data['email']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'uid': uid,
      'trailId': trailId,
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'fileName': fileName,
      if (ownerEmail != null && ownerEmail!.trim().isNotEmpty)
        'ownerEmail': ownerEmail!.trim(),
    };
  }

  TrailPhotoModel copyWith({
    String? id,
    String? uid,
    String? trailId,
    String? downloadUrl,
    String? storagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fileName,
    String? ownerEmail,
  }) {
    return TrailPhotoModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      trailId: trailId ?? this.trailId,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      storagePath: storagePath ?? this.storagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fileName: fileName ?? this.fileName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static String? _readString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return null;
  }

  static String _pathSegmentAfter(List<String> parts, String segment) {
    final index = parts.indexOf(segment);
    if (index == -1 || index + 1 >= parts.length) {
      return '';
    }

    return parts[index + 1];
  }
}
