import 'package:cloud_firestore/cloud_firestore.dart';

class TrailPhotoModel {
  static const mediaTypeImage = 'image';
  static const mediaTypeVideo = 'video';

  const TrailPhotoModel({
    required this.id,
    required this.uid,
    required this.trailId,
    required this.downloadUrl,
    required this.storagePath,
    required this.createdAt,
    required this.updatedAt,
    required this.fileName,
    this.mediaType = mediaTypeImage,
    this.contentType,
    this.sizeBytes,
    this.durationSeconds,
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
  final String mediaType;
  final String? contentType;
  final int? sizeBytes;
  final int? durationSeconds;
  final String? ownerEmail;

  String get photoUrl => downloadUrl;

  String get videoUrl => isVideo ? downloadUrl : '';

  bool get isVideo => mediaType == mediaTypeVideo;

  factory TrailPhotoModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final referenceParts = document.reference.path.split('/');
    final createdAt =
        _readDate(data['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final updatedAt = _readDate(data['updatedAt']) ?? createdAt;
    final fileName = _readString(data['fileName']) ?? 'trail-photo.jpg';
    final contentType = _readString(data['contentType']);
    final videoUrl = _readString(data['videoUrl']);
    final downloadUrl =
        _readString(data['downloadUrl']) ??
        _readString(data['mediaUrl']) ??
        videoUrl ??
        _readString(data['photoUrl']) ??
        _readString(data['url']) ??
        '';
    final mediaType = _mediaTypeFor(
      value: _readString(data['mediaType']) ?? _readString(data['type']),
      fileName: fileName,
      contentType: contentType,
      hasVideoUrl: videoUrl != null,
    );

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
      downloadUrl: downloadUrl,
      storagePath:
          _readString(data['storagePath']) ?? _readString(data['path']) ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      fileName: fileName,
      mediaType: mediaType,
      contentType: contentType,
      sizeBytes: _readInt(data['sizeBytes']),
      durationSeconds: _readInt(data['durationSeconds']),
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
      'mediaType': mediaType,
      'mediaUrl': downloadUrl,
      if (isVideo) 'videoUrl': downloadUrl,
      if (!isVideo) 'photoUrl': downloadUrl,
      if (contentType != null && contentType!.trim().isNotEmpty)
        'contentType': contentType!.trim(),
      if (sizeBytes != null) 'sizeBytes': sizeBytes,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
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
    String? mediaType,
    String? contentType,
    int? sizeBytes,
    int? durationSeconds,
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
      mediaType: mediaType ?? this.mediaType,
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      ownerEmail: ownerEmail ?? this.ownerEmail,
    );
  }

  static String normalizeMediaType(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == mediaTypeVideo || normalized == 'movie') {
      return mediaTypeVideo;
    }

    return mediaTypeImage;
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

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  static String _mediaTypeFor({
    required String? value,
    required String fileName,
    required String? contentType,
    required bool hasVideoUrl,
  }) {
    if (value != null && value.trim().isNotEmpty) {
      return normalizeMediaType(value);
    }

    if (hasVideoUrl) {
      return mediaTypeVideo;
    }

    final normalizedContentType = contentType?.trim().toLowerCase();
    if (normalizedContentType != null &&
        normalizedContentType.startsWith('video/')) {
      return mediaTypeVideo;
    }

    final lowerFileName = fileName.toLowerCase();
    const videoExtensions = ['.mp4', '.mov', '.m4v'];
    if (videoExtensions.any(lowerFileName.endsWith)) {
      return mediaTypeVideo;
    }

    return mediaTypeImage;
  }

  static String _pathSegmentAfter(List<String> parts, String segment) {
    final index = parts.indexOf(segment);
    if (index == -1 || index + 1 >= parts.length) {
      return '';
    }

    return parts[index + 1];
  }
}
