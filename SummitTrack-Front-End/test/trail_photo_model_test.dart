import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summittrack/features/mountains/models/trail_photo_model.dart';

void main() {
  test('serializes user-owned media metadata for Firebase persistence', () {
    final createdAt = DateTime.utc(2026, 8, 17, 9, 30);
    final updatedAt = DateTime.utc(2026, 8, 17, 9, 31);
    final media = TrailPhotoModel(
      id: 'media123',
      uid: 'uid123',
      trailId: 'sta_cruz_sibulan',
      downloadUrl: 'https://example.com/media.jpg',
      storagePath: 'users/uid123/media/media123.jpg',
      createdAt: createdAt,
      updatedAt: updatedAt,
      fileName: 'trail-photo.jpg',
      mediaType: TrailPhotoModel.mediaTypeImage,
      contentType: 'image/jpeg',
      sizeBytes: 42,
      ownerEmail: 'test123@gmail.com',
    );

    final data = media.toFirestore();

    expect(data['id'], 'media123');
    expect(data['mediaId'], 'media123');
    expect(data['uid'], 'uid123');
    expect(data['userId'], 'uid123');
    expect(data['trailId'], 'sta_cruz_sibulan');
    expect(data['storagePath'], 'users/uid123/media/media123.jpg');
    expect(data['downloadUrl'], 'https://example.com/media.jpg');
    expect(data['mediaUrl'], 'https://example.com/media.jpg');
    expect(data['mediaType'], TrailPhotoModel.mediaTypeImage);
    expect(data['type'], TrailPhotoModel.mediaTypeImage);
    expect(data['createdAt'], isA<Timestamp>());
    expect(data['updatedAt'], isA<Timestamp>());
  });
}
