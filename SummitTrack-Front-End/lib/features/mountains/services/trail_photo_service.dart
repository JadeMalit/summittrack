import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/trail_photo_model.dart';

class TrailPhotoException implements Exception {
  const TrailPhotoException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TrailPhotoService {
  static const staCruzSibulanTrailId = 'sta_cruz_sibulan';
  static const kapataganTrailId = 'kapatagan';
  static const _mediaCollectionName = 'media';
  static const _legacyTrailPhotosCollectionName = 'trail_photos';
  static const _permissionMessage =
      'You do not have permission to access this media.';

  TrailPhotoService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<TrailPhotoModel> uploadPhoto({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
    String trailId = staCruzSibulanTrailId,
  }) {
    return uploadMedia(
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
      trailId: trailId,
      mediaType: TrailPhotoModel.mediaTypeImage,
    );
  }

  Future<TrailPhotoModel> uploadMedia({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
    String trailId = staCruzSibulanTrailId,
    String mediaType = TrailPhotoModel.mediaTypeImage,
    int? sizeBytes,
    Duration? duration,
  }) async {
    if (bytes.isEmpty) {
      throw const TrailPhotoException('The selected media file is empty.');
    }

    final user = _requireUser();
    final normalizedTrailId = _safeTrailId(trailId);
    final normalizedMediaType = TrailPhotoModel.normalizeMediaType(mediaType);
    final photoDocument = _mediaCollection(user.uid).doc();
    final safeFileName = _safeFileName(
      fileName,
      photoDocument.id,
      normalizedMediaType,
    );
    final fileExtension = _extensionFor(safeFileName, normalizedMediaType);
    final storagePath =
        'users/${user.uid}/media/${photoDocument.id}.$fileExtension';
    final storageRef = _storage.ref(storagePath);
    final resolvedContentType = _contentTypeFor(
      contentType,
      safeFileName,
      normalizedMediaType,
    );
    _debugLog(
      'uploadMedia',
      'uid=${user.uid}, email=${user.email}, trailId=$normalizedTrailId, '
          'firestorePath=${_mediaCollectionPath(user.uid)}/${photoDocument.id}, '
          'storagePath=$storagePath, mediaType=$normalizedMediaType',
    );

    try {
      await storageRef.putData(
        bytes,
        SettableMetadata(
          contentType: resolvedContentType,
          customMetadata: {
            'uid': user.uid,
            'userId': user.uid,
            'mediaId': photoDocument.id,
            if (user.email != null) 'ownerEmail': user.email!,
            'trailId': normalizedTrailId,
            'storagePath': storagePath,
            'originalFileName': safeFileName,
            'mediaType': normalizedMediaType,
            if (duration != null) 'durationSeconds': '${duration.inSeconds}',
          },
        ),
      );

      final photoUrl = await storageRef.getDownloadURL();
      _debugLog(
        'uploadMedia',
        'upload complete uid=${user.uid}, trailId=$normalizedTrailId, '
            'storagePath=$storagePath, mediaType=$normalizedMediaType',
      );
      final now = DateTime.now().toUtc();
      final photo = TrailPhotoModel(
        id: photoDocument.id,
        uid: user.uid,
        trailId: normalizedTrailId,
        downloadUrl: photoUrl,
        storagePath: storagePath,
        createdAt: now,
        updatedAt: now,
        fileName: safeFileName,
        ownerEmail: user.email,
        mediaType: normalizedMediaType,
        contentType: resolvedContentType,
        sizeBytes: sizeBytes ?? bytes.length,
        durationSeconds: duration?.inSeconds,
      );

      await savePhotoMetadata(
        photo,
        userId: user.uid,
        trailId: normalizedTrailId,
      );

      return photo;
    } catch (error) {
      _logFirebaseError('uploadMedia', error);
      await _deleteStorageObjectQuietly(storagePath);

      if (error is TrailPhotoException) {
        rethrow;
      }

      throw TrailPhotoException(
        _firebaseMessage(
          error,
          fallback: 'Unable to save media right now. Please try again.',
        ),
      );
    }
  }

  Future<void> savePhotoMetadata(
    TrailPhotoModel photo, {
    String? userId,
    String? trailId,
  }) async {
    final uid = _requireOwnedUserId(userId);
    final normalizedTrailId = _safeTrailId(trailId ?? photo.trailId);
    _debugLog(
      'savePhotoMetadata',
      'uid=$uid, trailId=$normalizedTrailId, '
          'firestorePath=${_mediaCollectionPath(uid)}/${photo.id}, '
          'storagePath=${photo.storagePath}',
    );
    if (photo.uid.isNotEmpty && photo.uid != uid) {
      throw const TrailPhotoException(_permissionMessage);
    }
    final normalizedStoragePath = _normalizeStoragePath(photo.storagePath);
    if (normalizedStoragePath.isNotEmpty &&
        !_storagePathBelongsToUser(normalizedStoragePath, uid)) {
      throw const TrailPhotoException(_permissionMessage);
    }

    await _mediaCollection(uid)
        .doc(photo.id)
        .set(
          photo
              .copyWith(
                uid: uid,
                trailId: normalizedTrailId,
                storagePath: normalizedStoragePath,
                ownerEmail: _auth.currentUser?.email,
              )
              .toFirestore(),
        );
  }

  Future<List<TrailPhotoModel>> fetchUserPhotos({
    String? userId,
    String trailId = staCruzSibulanTrailId,
  }) async {
    final uid = userId ?? currentUserId;
    if (uid == null) {
      _debugLog(
        'fetchUserPhotos',
        'skip load because currentUser.uid is null; trailId=$trailId',
      );
      return <TrailPhotoModel>[];
    }

    final currentUid = currentUserId;
    if (currentUid == null) {
      _debugLog(
        'fetchUserPhotos',
        'skip load because FirebaseAuth.currentUser is null; requestedUid=$uid, trailId=$trailId',
      );
      return <TrailPhotoModel>[];
    }
    if (uid != currentUid) {
      _debugLog(
        'fetchUserPhotos',
        'blocked mismatched uid requestedUid=$uid, currentUid=$currentUid, trailId=$trailId',
      );
      throw const TrailPhotoException(_permissionMessage);
    }

    final normalizedTrailId = _safeTrailId(trailId);
    final firestorePath = _mediaCollectionPath(uid);
    final legacyFirestorePath = _photoCollectionPath(uid, normalizedTrailId);
    _debugLog(
      'fetchUserPhotos',
      'query start uid=$uid, email=${_auth.currentUser?.email}, trailId=$normalizedTrailId, '
          'firestorePath=$firestorePath, legacyFirestorePath=$legacyFirestorePath',
    );

    try {
      final mediaSnapshot = await _mediaCollection(
        uid,
      ).where('trailId', isEqualTo: normalizedTrailId).get();
      final legacySnapshot = await _photoCollection(
        uid,
        normalizedTrailId,
      ).get();

      final photos =
          <QueryDocumentSnapshot<Map<String, dynamic>>>[
                ...mediaSnapshot.docs,
                ...legacySnapshot.docs,
              ]
              .map(TrailPhotoModel.fromFirestore)
              .map(
                (photo) => photo.copyWith(
                  uid: photo.uid.isEmpty ? uid : photo.uid,
                  trailId: photo.trailId.isEmpty
                      ? normalizedTrailId
                      : photo.trailId,
                  storagePath: _normalizeStoragePath(photo.storagePath),
                  mediaType: TrailPhotoModel.normalizeMediaType(
                    photo.mediaType,
                  ),
                ),
              )
              .where(
                (photo) =>
                    photo.downloadUrl.isNotEmpty &&
                    photo.uid == uid &&
                    photo.trailId == normalizedTrailId &&
                    (photo.storagePath.isEmpty ||
                        _storagePathBelongsToUser(photo.storagePath, uid)),
              )
              .toList();
      photos.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _debugLog(
        'fetchUserPhotos',
        'query complete uid=$uid, trailId=$normalizedTrailId, '
            'rawCount=${mediaSnapshot.docs.length}, legacyRawCount=${legacySnapshot.docs.length}, '
            'resultCount=${photos.length}',
      );

      return photos;
    } catch (error) {
      _logFirebaseError('fetchUserPhotos', error);
      throw TrailPhotoException(
        _firebaseMessage(
          error,
          fallback: 'Unable to load saved media right now.',
        ),
      );
    }
  }

  Future<void> deletePhoto(
    TrailPhotoModel photo, {
    String? userId,
    String? trailId,
  }) async {
    final uid = _requireOwnedUserId(userId);
    final normalizedTrailId = _safeTrailId(trailId ?? photo.trailId);
    _debugLog(
      'deletePhoto',
      'uid=$uid, trailId=$normalizedTrailId, '
          'firestorePath=${_usesLegacyTrailPhotoCollection(photo.storagePath) ? _photoCollectionPath(uid, normalizedTrailId) : _mediaCollectionPath(uid)}/${photo.id}, '
          'storagePath=${photo.storagePath}',
    );
    if (photo.uid.isNotEmpty && photo.uid != uid) {
      throw const TrailPhotoException(_permissionMessage);
    }

    await deletePhotoFromStorage(
      _normalizeStoragePath(photo.storagePath),
      userId: uid,
    );
    await deletePhotoFromFirestore(
      photo.id,
      userId: uid,
      trailId: normalizedTrailId,
      storagePath: photo.storagePath,
    );
  }

  Future<void> deletePhotoFromStorage(
    String storagePath, {
    String? userId,
  }) async {
    final normalizedStoragePath = _normalizeStoragePath(storagePath);
    if (normalizedStoragePath.isEmpty) {
      return;
    }
    final uid = userId ?? currentUserId;
    if (uid != null && !_storagePathBelongsToUser(normalizedStoragePath, uid)) {
      _debugLog(
        'deletePhotoFromStorage',
        'blocked mismatched storage path uid=$uid, storagePath=$normalizedStoragePath',
      );
      throw const TrailPhotoException(_permissionMessage);
    }
    _debugLog(
      'deletePhotoFromStorage',
      'delete start uid=$uid, storagePath=$normalizedStoragePath',
    );

    try {
      await _storage.ref(normalizedStoragePath).delete();
    } on FirebaseException catch (error) {
      _logFirebaseError('deletePhotoFromStorage', error);
      if (error.code == 'object-not-found') {
        return;
      }

      throw TrailPhotoException(
        _firebaseMessage(
          error,
          fallback: 'Unable to delete that media file from storage.',
        ),
      );
    }
  }

  Future<void> deletePhotoFromFirestore(
    String photoId, {
    String? userId,
    String trailId = staCruzSibulanTrailId,
    String storagePath = '',
  }) async {
    final uid = _requireOwnedUserId(userId);
    final normalizedTrailId = _safeTrailId(trailId);
    final normalizedStoragePath = _normalizeStoragePath(storagePath);
    final isLegacyPhoto = _usesLegacyTrailPhotoCollection(
      normalizedStoragePath,
    );
    final collection = isLegacyPhoto
        ? _photoCollection(uid, normalizedTrailId)
        : _mediaCollection(uid);
    final collectionPath = isLegacyPhoto
        ? _photoCollectionPath(uid, normalizedTrailId)
        : _mediaCollectionPath(uid);
    _debugLog(
      'deletePhotoFromFirestore',
      'delete start uid=$uid, trailId=$normalizedTrailId, '
          'firestorePath=$collectionPath/$photoId',
    );

    try {
      await collection.doc(photoId).delete();
    } catch (error) {
      _logFirebaseError('deletePhotoFromFirestore', error);
      throw TrailPhotoException(
        _firebaseMessage(
          error,
          fallback: 'Unable to delete that media file from your account.',
        ),
      );
    }
  }

  CollectionReference<Map<String, dynamic>> _photoCollection(
    String userId,
    String trailId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_legacyTrailPhotosCollectionName)
        .doc(trailId)
        .collection('photos');
  }

  String _photoCollectionPath(String userId, String trailId) {
    return 'users/$userId/$_legacyTrailPhotosCollectionName/$trailId/photos';
  }

  CollectionReference<Map<String, dynamic>> _mediaCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_mediaCollectionName);
  }

  String _mediaCollectionPath(String userId) {
    return 'users/$userId/$_mediaCollectionName';
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const TrailPhotoException(
        'Please sign in first before saving media.',
      );
    }

    return user;
  }

  String _requireOwnedUserId(String? requestedUserId) {
    final user = _requireUser();
    final uid = requestedUserId ?? user.uid;
    if (uid != user.uid) {
      throw const TrailPhotoException(_permissionMessage);
    }

    return uid;
  }

  Future<void> _deleteStorageObjectQuietly(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') {
        return;
      }
    } catch (_) {
      return;
    }
  }

  String _safeFileName(String fileName, String photoId, String mediaType) {
    final trimmedName = fileName.trim();
    final fallback = mediaType == TrailPhotoModel.mediaTypeVideo
        ? 'trail-video-$photoId.mp4'
        : 'trail-photo-$photoId.jpg';
    final candidate = trimmedName.isEmpty ? fallback : trimmedName;

    return candidate.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-');
  }

  String _safeTrailId(String trailId) {
    final normalized = trailId
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    return normalized.isEmpty ? staCruzSibulanTrailId : normalized;
  }

  bool _storagePathBelongsToUser(String storagePath, String userId) {
    final normalizedStoragePath = _normalizeStoragePath(storagePath);
    return normalizedStoragePath == 'users/$userId/media' ||
        normalizedStoragePath.startsWith('users/$userId/media/') ||
        normalizedStoragePath == 'trail_photos/$userId' ||
        normalizedStoragePath.startsWith('trail_photos/$userId/');
  }

  String _normalizeStoragePath(String storagePath) {
    final trimmedPath = _decodePath(
      storagePath.trim().replaceAll(r'\', '/'),
    ).split('?').first;
    if (trimmedPath.isEmpty) {
      return '';
    }

    for (final storageRoot in ['users/', 'trail_photos/']) {
      final storageRootIndex = trimmedPath.indexOf(storageRoot);
      if (storageRootIndex != -1) {
        return trimmedPath.substring(storageRootIndex);
      }
    }

    return trimmedPath.replaceFirst(RegExp(r'^/+'), '');
  }

  bool _usesLegacyTrailPhotoCollection(String storagePath) {
    return _normalizeStoragePath(storagePath).startsWith('trail_photos/');
  }

  String _decodePath(String path) {
    try {
      return Uri.decodeFull(path);
    } on FormatException {
      return path;
    }
  }

  String _extensionFor(String fileName, String mediaType) {
    final lowerName = fileName.toLowerCase();
    final dotIndex = lowerName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == lowerName.length - 1) {
      return mediaType == TrailPhotoModel.mediaTypeVideo ? 'mp4' : 'jpg';
    }

    final extension = lowerName.substring(dotIndex + 1);
    if (mediaType == TrailPhotoModel.mediaTypeVideo) {
      const supportedVideoExtensions = {'mp4', 'mov', 'm4v'};
      return supportedVideoExtensions.contains(extension) ? extension : 'mp4';
    }

    const supportedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};

    return supportedExtensions.contains(extension) ? extension : 'jpg';
  }

  String _contentTypeFor(
    String? contentType,
    String fileName,
    String mediaType,
  ) {
    final normalizedContentType = contentType?.toLowerCase();
    if (normalizedContentType != null &&
        normalizedContentType.startsWith('$mediaType/')) {
      return normalizedContentType;
    }

    final extension = _extensionFor(fileName, mediaType);
    if (mediaType == TrailPhotoModel.mediaTypeVideo) {
      return switch (extension) {
        'mov' => 'video/quicktime',
        'm4v' => 'video/x-m4v',
        _ => 'video/mp4',
      };
    }

    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }

  String _firebaseMessage(Object error, {required String fallback}) {
    if (error is TrailPhotoException) {
      return error.message;
    }

    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' =>
          'You do not have permission to access this media.',
        'unauthorized' => 'You do not have permission to access this media.',
        'unavailable' => 'Network connection is unavailable. Please try again.',
        'network-request-failed' =>
          'Network connection is unavailable. Please try again.',
        'deadline-exceeded' =>
          'Network connection is unavailable. Please try again.',
        'unauthenticated' => 'Please sign in first before saving media.',
        _ => fallback,
      };
    }

    return fallback;
  }

  void _debugLog(String functionName, String message) {
    developer.log(message, name: 'TrailPhotoService.$functionName');
  }

  void _logFirebaseError(String functionName, Object error) {
    if (error is FirebaseException) {
      _debugLog(
        functionName,
        'FirebaseException code=${error.code}, message=${error.message}, plugin=${error.plugin}',
      );
      return;
    }

    _debugLog(functionName, 'errorType=${error.runtimeType}, error=$error');
  }
}
