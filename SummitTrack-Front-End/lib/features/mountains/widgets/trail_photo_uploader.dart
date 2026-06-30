import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../models/trail_photo_model.dart';
import '../services/trail_photo_service.dart';

class TrailPhotoUploader extends StatefulWidget {
  const TrailPhotoUploader({
    super.key,
    this.service,
    this.trailId = TrailPhotoService.staCruzSibulanTrailId,
  });

  final TrailPhotoService? service;
  final String trailId;

  @override
  State<TrailPhotoUploader> createState() => _TrailPhotoUploaderState();
}

class _TrailPhotoUploaderState extends State<TrailPhotoUploader> {
  final ImagePicker _picker = ImagePicker();
  final List<TrailPhotoModel> _savedPhotos = <TrailPhotoModel>[];
  final List<_PendingTrailPhoto> _pendingPhotos = <_PendingTrailPhoto>[];

  late final TrailPhotoService _service;
  StreamSubscription<User?>? _authSubscription;

  int _currentIndex = 0;
  bool _isPickingPhoto = false;
  bool _isLoadingSavedPhotos = false;
  bool _isSavingPhotos = false;
  bool _isDeletingPhoto = false;
  String? _activeUserId;
  String? _activeTrailId;
  String? _lastSnackBarKey;

  int get _photoCount => _savedPhotos.length + _pendingPhotos.length;

  bool get _hasMultiplePhotos => _photoCount > 1;

  bool get _hasUnsavedPhotos => _pendingPhotos.isNotEmpty;

  List<_DisplayTrailPhoto> get _photos {
    return <_DisplayTrailPhoto>[
      for (final photo in _savedPhotos) _DisplayTrailPhoto.saved(photo),
      for (final photo in _pendingPhotos) _DisplayTrailPhoto.pending(photo),
    ];
  }

  _DisplayTrailPhoto? get _currentPhoto {
    final photos = _photos;
    if (photos.isEmpty || _currentIndex >= photos.length) {
      return null;
    }

    return photos[_currentIndex];
  }

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? TrailPhotoService();
    debugPrint(
      '[TrailPhotoUploader.initState] trailId=${widget.trailId}, '
      'currentUser.uid=${FirebaseAuth.instance.currentUser?.uid}, '
      'currentUser.email=${FirebaseAuth.instance.currentUser?.email}',
    );
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _handleAuthChanged,
    );
    _handleAuthChanged(FirebaseAuth.instance.currentUser);
    unawaited(_recoverLostGalleryPhoto());
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TrailPhotoUploader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trailId != widget.trailId) {
      unawaited(_handleAuthChanged(FirebaseAuth.instance.currentUser));
    }
  }

  Future<void> _handleAuthChanged(User? user) async {
    final currentUser = FirebaseAuth.instance.currentUser ?? user;
    final userId = currentUser?.uid;
    final trailId = widget.trailId;
    debugPrint(
      '[TrailPhotoUploader._handleAuthChanged] incomingUser.uid=${user?.uid}, '
      'currentUser.uid=$userId, currentUser.email=${currentUser?.email}, '
      'trailId=$trailId, activeUserId=$_activeUserId, activeTrailId=$_activeTrailId',
    );
    if (_activeUserId == userId && _activeTrailId == trailId) {
      debugPrint(
        '[TrailPhotoUploader._handleAuthChanged] skip duplicate auth/trail event '
        'uid=$userId, trailId=$trailId',
      );
      return;
    }

    _activeUserId = userId;
    _activeTrailId = trailId;

    if (mounted) {
      setState(() {
        _pendingPhotos.clear();
        _savedPhotos.clear();
        _currentIndex = 0;
        _isLoadingSavedPhotos = userId != null;
      });
    }

    if (userId == null) {
      debugPrint(
        '[TrailPhotoUploader._handleAuthChanged] skip Firebase photo load because currentUser.uid is null; '
        'trailId=$trailId',
      );
      return;
    }

    try {
      debugPrint(
        '[TrailPhotoUploader._handleAuthChanged] loading photos uid=$userId, '
        'email=${currentUser?.email}, trailId=$trailId',
      );
      final photos = await _service.fetchUserPhotos(
        userId: userId,
        trailId: trailId,
      );
      if (!mounted || _activeUserId != userId || _activeTrailId != trailId) {
        return;
      }

      setState(() {
        _savedPhotos
          ..clear()
          ..addAll(photos);
        _isLoadingSavedPhotos = false;
        _normalizeCurrentIndex();
      });
      debugPrint(
        '[TrailPhotoUploader._handleAuthChanged] load complete uid=$userId, '
        'trailId=$trailId, resultCount=${photos.length}',
      );
      _lastSnackBarKey = null;
    } catch (error) {
      if (!mounted || _activeUserId != userId || _activeTrailId != trailId) {
        return;
      }

      debugPrint(
        '[TrailPhotoUploader._handleAuthChanged] load error uid=$userId, '
        'trailId=$trailId, errorType=${error.runtimeType}, error=$error',
      );
      setState(() {
        _isLoadingSavedPhotos = false;
      });
      _showSnackBar(_messageForError(error), isError: true, dedupe: true);
    }
  }

  Future<void> _pickPhoto() async {
    if (_isPickingPhoto || _isSavingPhotos || _isDeletingPhoto) {
      return;
    }

    setState(() {
      _isPickingPhoto = true;
    });

    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1800,
        requestFullMetadata: false,
      );

      if (image == null) {
        return;
      }

      await _addPickedImageToPreview(image);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar('Unable to load that image right now.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  Future<void> _recoverLostGalleryPhoto() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      final response = await _picker.retrieveLostData();
      if (!mounted || response.isEmpty) {
        return;
      }

      if (response.exception != null) {
        debugPrint(
          '[TrailPhotoUploader._recoverLostGalleryPhoto] error=${response.exception}',
        );
        _showSnackBar('Unable to load that image right now.', isError: true);
        return;
      }

      if (response.type != null && response.type != RetrieveType.image) {
        return;
      }

      final images =
          response.files ?? <XFile>[if (response.file != null) response.file!];
      for (final image in images) {
        await _addPickedImageToPreview(image);
      }
    } on UnimplementedError {
      return;
    } catch (error) {
      debugPrint(
        '[TrailPhotoUploader._recoverLostGalleryPhoto] errorType=${error.runtimeType}, error=$error',
      );
    }
  }

  Future<void> _addPickedImageToPreview(XFile image) async {
    if (!_isSupportedImage(image)) {
      _showSnackBar('Please choose an image file.', isError: true);
      return;
    }

    final sourcePath = image.path.trim();
    final alreadyAdded =
        sourcePath.isNotEmpty &&
        _pendingPhotos.any((photo) => photo.sourcePath == sourcePath);

    if (alreadyAdded) {
      _showSnackBar('That photo has already been added.');
      return;
    }

    final bytes = await image.readAsBytes();
    if (bytes.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _pendingPhotos.add(
        _PendingTrailPhoto(
          bytes: bytes,
          sourcePath: sourcePath,
          id: '${DateTime.now().microsecondsSinceEpoch}-${bytes.length}-${sourcePath.hashCode}',
          fileName: _fileNameFor(image),
          contentType: image.mimeType,
        ),
      );
      _currentIndex = _photoCount - 1;
    });
  }

  Future<void> _savePhotos() async {
    if (_isSavingPhotos || !_hasUnsavedPhotos) {
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      _showSnackBar(
        'Please sign in first before saving photos.',
        isError: true,
      );
      return;
    }

    final photosToSave = List<_PendingTrailPhoto>.of(_pendingPhotos);
    final savedPairs = <_SavedPhotoPair>[];
    debugPrint(
      '[TrailPhotoUploader._savePhotos] start uid=${FirebaseAuth.instance.currentUser?.uid}, '
      'email=${FirebaseAuth.instance.currentUser?.email}, trailId=${widget.trailId}, '
      'pendingCount=${photosToSave.length}',
    );

    setState(() {
      _isSavingPhotos = true;
    });

    try {
      for (final photo in photosToSave) {
        final savedPhoto = await _service.uploadPhoto(
          bytes: photo.bytes,
          fileName: photo.fileName,
          contentType: photo.contentType,
          trailId: widget.trailId,
        );
        savedPairs.add(_SavedPhotoPair(pending: photo, saved: savedPhoto));
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _applySavedPhotoPairs(savedPairs);
        _isSavingPhotos = false;
      });
      _lastSnackBarKey = null;
      _showSnackBar('Photos saved successfully.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _applySavedPhotoPairs(savedPairs);
        _isSavingPhotos = false;
      });
      debugPrint(
        '[TrailPhotoUploader._savePhotos] save error uid=${FirebaseAuth.instance.currentUser?.uid}, '
        'trailId=${widget.trailId}, savedBeforeError=${savedPairs.length}, '
        'errorType=${error.runtimeType}, error=$error',
      );
      _showSnackBar(_messageForError(error), isError: true, dedupe: true);
    }
  }

  void _applySavedPhotoPairs(List<_SavedPhotoPair> savedPairs) {
    if (savedPairs.isEmpty) {
      return;
    }

    final savedPendingIds = savedPairs.map((pair) => pair.pending.id).toSet();
    _pendingPhotos.removeWhere((photo) => savedPendingIds.contains(photo.id));
    _savedPhotos.addAll(savedPairs.map((pair) => pair.saved));
    _normalizeCurrentIndex();
  }

  void _showPreviousPhoto() {
    if (!_hasMultiplePhotos || _isDeletingPhoto) {
      return;
    }

    setState(() {
      _currentIndex = (_currentIndex - 1 + _photoCount) % _photoCount;
    });
  }

  void _showNextPhoto() {
    if (!_hasMultiplePhotos || _isDeletingPhoto) {
      return;
    }

    setState(() {
      _currentIndex = (_currentIndex + 1) % _photoCount;
    });
  }

  Future<void> _confirmDeletePhoto() async {
    final photo = _currentPhoto;
    if (photo == null || _isDeletingPhoto) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.appColors;

        return AlertDialog(
          backgroundColor: dialogContext.isDarkMode
              ? colors.surfaceHigh
              : Colors.white,
          title: Text(
            'Delete Photo?',
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this photo? This action cannot be undone.',
            style: GoogleFonts.poppins(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: colors.danger),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await _deletePhoto(photo);
  }

  Future<void> _deletePhoto(_DisplayTrailPhoto photo) async {
    if (photo.pendingPhoto != null) {
      setState(() {
        _removePhotoFromState(photo);
      });
      return;
    }

    final savedPhoto = photo.savedPhoto;
    final activeUserId = _activeUserId;
    if (savedPhoto == null || activeUserId == null) {
      return;
    }
    debugPrint(
      '[TrailPhotoUploader._deletePhoto] start uid=$activeUserId, '
      'trailId=${widget.trailId}, photoId=${savedPhoto.id}, '
      'storagePath=${savedPhoto.storagePath}',
    );

    setState(() {
      _isDeletingPhoto = true;
    });

    try {
      await _service.deletePhoto(
        savedPhoto,
        userId: activeUserId,
        trailId: widget.trailId,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _removePhotoFromState(photo);
        _isDeletingPhoto = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDeletingPhoto = false;
      });
      debugPrint(
        '[TrailPhotoUploader._deletePhoto] delete error uid=$activeUserId, '
        'trailId=${widget.trailId}, photoId=${savedPhoto.id}, '
        'errorType=${error.runtimeType}, error=$error',
      );
      _showSnackBar(_messageForError(error), isError: true, dedupe: true);
    }
  }

  void _removePhotoFromState(_DisplayTrailPhoto photo) {
    if (photo.pendingPhoto != null) {
      _pendingPhotos.removeWhere((item) => item.id == photo.id);
    } else if (photo.savedPhoto != null) {
      _savedPhotos.removeWhere((item) => item.id == photo.id);
    }

    _normalizeCurrentIndex();
  }

  Future<bool> _confirmLeaveWithoutSaving() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.appColors;

        return AlertDialog(
          backgroundColor: dialogContext.isDarkMode
              ? colors.surfaceHigh
              : Colors.white,
          title: Text(
            'Unsaved Photos',
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          content: Text(
            'You have unsaved photos. Do you want to leave without saving?',
            style: GoogleFonts.poppins(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: colors.primary),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    return shouldLeave == true;
  }

  Future<void> _handleBlockedPop(Object? result) async {
    if (!_hasUnsavedPhotos) {
      return;
    }

    final shouldLeave = await _confirmLeaveWithoutSaving();
    if (!mounted || !shouldLeave) {
      return;
    }

    setState(() {
      _pendingPhotos.clear();
      _normalizeCurrentIndex();
    });

    await Navigator.of(context).maybePop(result);
  }

  void _normalizeCurrentIndex() {
    if (_photoCount == 0) {
      _currentIndex = 0;
      return;
    }

    if (_currentIndex >= _photoCount) {
      _currentIndex = _photoCount - 1;
    }

    if (_currentIndex < 0) {
      _currentIndex = 0;
    }
  }

  bool _isSupportedImage(XFile image) {
    final mimeType = image.mimeType?.toLowerCase();
    if (mimeType != null && mimeType.startsWith('image/')) {
      return true;
    }

    final fileName = _fileNameFor(image).toLowerCase();
    const allowedExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
      '.heic',
      '.heif',
    ];

    return allowedExtensions.any(fileName.endsWith);
  }

  String _fileNameFor(XFile image) {
    final imageName = image.name.trim();
    if (imageName.isNotEmpty) {
      return imageName;
    }

    final normalizedPath = image.path.replaceAll(r'\', '/');
    final slashIndex = normalizedPath.lastIndexOf('/');
    if (slashIndex == -1 || slashIndex == normalizedPath.length - 1) {
      return 'trail-photo.jpg';
    }

    return normalizedPath.substring(slashIndex + 1);
  }

  String _messageForError(Object error) {
    if (error is TrailPhotoException) {
      return error.message;
    }

    return 'Something went wrong. Please try again.';
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool dedupe = false,
  }) {
    if (!mounted) {
      return;
    }

    final snackBarKey = '$isError|$message';
    if (dedupe && _lastSnackBarKey == snackBarKey) {
      debugPrint(
        '[TrailPhotoUploader._showSnackBar] suppressed duplicate message="$message"',
      );
      return;
    }
    _lastSnackBarKey = snackBarKey;
    debugPrint(
      '[TrailPhotoUploader._showSnackBar] show isError=$isError, message="$message"',
    );

    final colors = context.appColors;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? colors.danger : colors.primary,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final canAddPhoto =
        !_isPickingPhoto && !_isSavingPhotos && !_isDeletingPhoto;

    return PopScope<Object?>(
      canPop: !_hasUnsavedPhotos,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        unawaited(_handleBlockedPop(result));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton(
            onPressed: canAddPhoto ? _pickPhoto : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textPrimary,
              disabledForegroundColor: colors.textSecondary,
              side: BorderSide(color: colors.border, width: 1.6),
              backgroundColor: context.isDarkMode
                  ? colors.surfaceHigh
                  : Colors.white.withValues(alpha: 0.7),
              disabledBackgroundColor: context.isDarkMode
                  ? colors.surfaceMuted
                  : Colors.white.withValues(alpha: 0.46),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              children: [
                if (_isPickingPhoto)
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: colors.primary,
                    ),
                  )
                else
                  const Icon(Icons.add_rounded, size: 34),
                const SizedBox(width: 10),
                Text(
                  'Add your photo',
                  style: GoogleFonts.fredoka(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _TrailPhotoPreview(
            currentIndex: _currentIndex,
            currentPhoto: _currentPhoto,
            photoCount: _photoCount,
            isDeletingPhoto: _isDeletingPhoto,
            isLoadingSavedPhotos: _isLoadingSavedPhotos,
            onDelete: _confirmDeletePhoto,
          ),
          if (_hasMultiplePhotos) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PhotoNavigationButton(
                  icon: Icons.chevron_left_rounded,
                  label: 'Previous',
                  onPressed: _showPreviousPhoto,
                ),
                const SizedBox(width: 10),
                _PhotoNavigationButton(
                  icon: Icons.chevron_right_rounded,
                  label: 'Next',
                  onPressed: _showNextPhoto,
                  isIconAfterLabel: true,
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          _SavePhotosButton(
            isSaving: _isSavingPhotos,
            unsavedCount: _pendingPhotos.length,
            onPressed:
                _hasUnsavedPhotos && !_isSavingPhotos && !_isDeletingPhoto
                ? _savePhotos
                : null,
          ),
        ],
      ),
    );
  }
}

class _TrailPhotoPreview extends StatelessWidget {
  const _TrailPhotoPreview({
    required this.currentIndex,
    required this.currentPhoto,
    required this.photoCount,
    required this.isDeletingPhoto,
    required this.isLoadingSavedPhotos,
    required this.onDelete,
  });

  final int currentIndex;
  final _DisplayTrailPhoto? currentPhoto;
  final int photoCount;
  final bool isDeletingPhoto;
  final bool isLoadingSavedPhotos;
  final VoidCallback onDelete;

  bool get _hasPhoto => currentPhoto != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? colors.surfaceMuted
            : const Color(0xFFD7D7D7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.isDarkMode ? colors.border : const Color(0xFF7A766F),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );

              return FadeTransition(
                opacity: curvedAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.035, 0),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                ),
              );
            },
            child: _hasPhoto
                ? _TrailPhotoImage(photo: currentPhoto!)
                : isLoadingSavedPhotos
                ? const _TrailPhotoLoadingState()
                : const _TrailPhotoEmptyState(),
          ),
          if (_hasPhoto) ...[
            Positioned(
              top: 10,
              right: 10,
              child: _DeletePhotoButton(
                isBusy: isDeletingPhoto,
                onPressed: isDeletingPhoto ? null : onDelete,
              ),
            ),
            if (photoCount > 0)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: _PhotoCounter(
                    currentIndex: currentIndex,
                    photoCount: photoCount,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TrailPhotoImage extends StatelessWidget {
  _TrailPhotoImage({required this.photo}) : super(key: ValueKey(photo.id));

  final _DisplayTrailPhoto photo;

  @override
  Widget build(BuildContext context) {
    final pendingPhoto = photo.pendingPhoto;
    if (pendingPhoto != null) {
      return Image.memory(
        pendingPhoto.bytes,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
      );
    }

    return Image.network(
      photo.savedPhoto!.photoUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        final totalBytes = loadingProgress.expectedTotalBytes;
        final loadedBytes = loadingProgress.cumulativeBytesLoaded;
        final progress = totalBytes == null ? null : loadedBytes / totalBytes;

        return _TrailPhotoProgress(progress: progress);
      },
      errorBuilder: (context, error, stackTrace) {
        return const _TrailPhotoErrorState();
      },
    );
  }
}

class _TrailPhotoProgress extends StatelessWidget {
  const _TrailPhotoProgress({this.progress})
    : super(key: const ValueKey('photo-loading-progress'));

  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ColoredBox(
      color: context.isDarkMode ? colors.surfaceMuted : const Color(0xFFE5E2DA),
      child: Center(
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 2.8,
          color: colors.primary,
        ),
      ),
    );
  }
}

class _TrailPhotoLoadingState extends StatelessWidget {
  const _TrailPhotoLoadingState()
    : super(key: const ValueKey('loading-photo-state'));

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: CircularProgressIndicator(strokeWidth: 2.8, color: colors.primary),
    );
  }
}

class _TrailPhotoEmptyState extends StatelessWidget {
  const _TrailPhotoEmptyState()
    : super(key: const ValueKey('empty-photo-state'));

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, size: 54, color: colors.textSecondary),
            const SizedBox(height: 10),
            Text(
              'Your uploaded trail photo will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrailPhotoErrorState extends StatelessWidget {
  const _TrailPhotoErrorState()
    : super(key: const ValueKey('photo-error-state'));

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ColoredBox(
      color: context.isDarkMode ? colors.surfaceMuted : const Color(0xFFE5E2DA),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 46,
              color: colors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              'Photo unavailable',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoNavigationButton extends StatelessWidget {
  const _PhotoNavigationButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isIconAfterLabel = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isIconAfterLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final iconWidget = Icon(icon, size: 21);
    final labelWidget = Text(
      label,
      style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600),
    );

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        backgroundColor: context.isDarkMode
            ? colors.surfaceHigh
            : Colors.white.withValues(alpha: 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isIconAfterLabel
            ? [labelWidget, const SizedBox(width: 4), iconWidget]
            : [iconWidget, const SizedBox(width: 4), labelWidget],
      ),
    );
  }
}

class _DeletePhotoButton extends StatelessWidget {
  const _DeletePhotoButton({required this.isBusy, required this.onPressed});

  final bool isBusy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Tooltip(
      message: 'Delete photo',
      child: Material(
        color: colors.danger.withValues(alpha: isBusy ? 0.74 : 0.92),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            width: 38,
            height: 38,
            child: isBusy
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
          ),
        ),
      ),
    );
  }
}

class _SavePhotosButton extends StatelessWidget {
  const _SavePhotosButton({
    required this.isSaving,
    required this.unsavedCount,
    required this.onPressed,
  });

  final bool isSaving;
  final int unsavedCount;
  final VoidCallback? onPressed;

  bool get _isEnabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final borderRadius = BorderRadius.circular(14);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _isEnabled
            ? null
            : context.isDarkMode
            ? colors.surfaceMuted
            : Colors.white.withValues(alpha: 0.52),
        gradient: _isEnabled
            ? LinearGradient(colors: [colors.primary, colors.accent])
            : null,
        borderRadius: borderRadius,
        border: Border.all(
          color: _isEnabled ? Colors.transparent : colors.border,
        ),
        boxShadow: _isEnabled
            ? [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: colors.textSecondary,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSaving)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.cloud_upload_outlined, size: 21),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                isSaving
                    ? 'Saving Photos...'
                    : unsavedCount > 0
                    ? 'Save Photos ($unsavedCount)'
                    : 'Save Photos',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.fredoka(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoCounter extends StatelessWidget {
  const _PhotoCounter({required this.currentIndex, required this.photoCount});

  final int currentIndex;
  final int photoCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          '${currentIndex + 1} / $photoCount',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _DisplayTrailPhoto {
  _DisplayTrailPhoto.saved(TrailPhotoModel photo)
    : id = 'saved-${photo.id}',
      savedPhoto = photo,
      pendingPhoto = null;

  _DisplayTrailPhoto.pending(_PendingTrailPhoto photo)
    : id = 'pending-${photo.id}',
      savedPhoto = null,
      pendingPhoto = photo;

  final String id;
  final TrailPhotoModel? savedPhoto;
  final _PendingTrailPhoto? pendingPhoto;
}

class _PendingTrailPhoto {
  const _PendingTrailPhoto({
    required this.bytes,
    required this.id,
    required this.sourcePath,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String id;
  final String sourcePath;
  final String fileName;
  final String? contentType;
}

class _SavedPhotoPair {
  const _SavedPhotoPair({required this.pending, required this.saved});

  final _PendingTrailPhoto pending;
  final TrailPhotoModel saved;
}
