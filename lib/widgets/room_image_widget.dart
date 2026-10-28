import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/constant_uri.dart';
import 'app_colors.dart';

class RoomImageWidget extends StatelessWidget {
  final String? image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;
  final String? heroTag;
  final bool enableFullScreenViewer;
  final String? roomNumber;

  const RoomImageWidget({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
    this.heroTag,
    this.enableFullScreenViewer = false,
    this.roomNumber,
  });

  Widget _buildFallback() {
    if (fallback != null) return fallback!;
    return Container(
      width: width,
      height: height,
      color: AppColors.primarySoft,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.meeting_room_rounded,
              size: (height != null && height! < 70) ? 24 : 48,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
            if (roomNumber != null && (height == null || height! >= 90)) ...[
              const SizedBox(height: 6),
              Text(
                "បន្ទប់ $roomNumber",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> get _allImages {
    if (image == null || image!.trim().isEmpty) return [];
    final str = image!.trim();
    if (str.startsWith('[') && str.endsWith(']')) {
      try {
        final decoded = jsonDecode(str);
        if (decoded is List) {
          return decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {}
    }
    if (str.contains(',') && !str.startsWith('data:image')) {
      return str.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return [str];
  }

  Widget _buildImageWidget() {
    String? img = image?.trim();
    if (img == null || img.isEmpty) {
      return _buildFallback();
    }

    if (img.startsWith('[') && img.endsWith(']')) {
      try {
        final decoded = jsonDecode(img);
        if (decoded is List && decoded.isNotEmpty) {
          img = decoded.first?.toString().trim();
        }
      } catch (_) {}
    }
    if (img != null && img.contains(',') && !img.startsWith('data:image')) {
      img = img.split(',').first.trim();
    }
    if (img == null || img.isEmpty) {
      return _buildFallback();
    }

    Widget content;

    // 1. Base64 Data URI
    if (img.startsWith('data:image')) {
      try {
        final commaIdx = img.indexOf(',');
        final base64Str = commaIdx != -1 ? img.substring(commaIdx + 1) : img;
        content = Image.memory(
          base64Decode(base64Str),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => _buildFallback(),
        );
      } catch (_) {
        return _buildFallback();
      }
    }
    // 2. Direct Network URL (http/https) or Browser Blob URL (blob:)
    else if (img.startsWith('http://') || img.startsWith('https://') || img.startsWith('blob:')) {
      content = Image.network(
        img,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _buildFallback(),
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppColors.primarySoft.withValues(alpha: 0.3),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          );
        },
      );
    }
    // 3. Local Asset Image
    else if (img.startsWith('assets/')) {
      content = Image.asset(
        img,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _buildFallback(),
      );
    }
    // 4. Raw Base64 string without data:image prefix
    else if (img.length > 50 &&
        (img.startsWith('/9j/') ||
            img.startsWith('iVBOR') ||
            img.startsWith('R0lGOD') ||
            img.startsWith('UklGR') ||
            (!img.contains(' ') && !img.contains('/') && !img.contains('.')))) {
      try {
        content = Image.memory(
          base64Decode(img),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => _buildFallback(),
        );
      } catch (_) {
        return _buildFallback();
      }
    }
    // 5. Local File Path (non-web)
    else if (!kIsWeb && (img.startsWith('/') || img.contains(':\\') || img.startsWith('file:'))) {
      try {
        final cleanPath = img.replaceFirst('file://', '');
        final file = File(cleanPath);
        if (file.existsSync()) {
          content = Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => _buildFallback(),
          );
        } else {
          return _buildFallback();
        }
      } catch (_) {
        return _buildFallback();
      }
    }
    // 6. Server filename relative to ConstantUri
    else {
      final fullUrl = "${ConstantUri.baseUri}/api/public/view/image?filename=$img";
      content = Image.network(
        fullUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _buildFallback(),
      );
    }

    if (heroTag != null) {
      content = Hero(tag: heroTag!, child: content);
    }

    return content;
  }

  void _openFullScreenViewer(BuildContext context) {
    final imgs = _allImages;
    if (imgs.isEmpty) return;

    if (imgs.length == 1) {
      showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: RoomImageWidget(
                    image: imgs.first,
                    fit: BoxFit.contain,
                    heroTag: heroTag,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              if (roomNumber != null)
                Positioned(
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "បន្ទប់ $roomNumber",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      // Multiple photos swipeable dialog
      showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (ctx) {
          int activeIdx = 0;
          return StatefulBuilder(
            builder: (ctx, setFullState) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: imgs.length,
                    onPageChanged: (i) => setFullState(() => activeIdx = i),
                    itemBuilder: (ctx, i) {
                      return InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Center(
                          child: RoomImageWidget(
                            image: imgs[i],
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: MediaQuery.of(ctx).padding.top + 10,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${activeIdx + 1} / ${imgs.length}",
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  if (roomNumber != null)
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "បន្ទប់ $roomNumber",
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = _buildImageWidget();

    if (borderRadius != null) {
      child = ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }

    if (enableFullScreenViewer && image != null && image!.trim().isNotEmpty) {
      return GestureDetector(
        onTap: () => _openFullScreenViewer(context),
        child: child,
      );
    }

    return child;
  }
}

/// A dedicated multi-image carousel slider widget for rooms with dots, counter and fullscreen viewer
class RoomImageSliderWidget extends StatefulWidget {
  final List<String> images;
  final String? roomNumber;
  final double height;
  final Widget? fallback;
  final String? heroTag;
  final VoidCallback? onAddOrChangePhoto;
  final bool isUploading;

  const RoomImageSliderWidget({
    super.key,
    required this.images,
    this.roomNumber,
    this.height = 230,
    this.fallback,
    this.heroTag,
    this.onAddOrChangePhoto,
    this.isUploading = false,
  });

  static void openFullScreenGallery(
    BuildContext context,
    List<String> images, {
    String? roomNumber,
    int initialIndex = 0,
  }) {
    if (images.isEmpty) return;

    if (images.length == 1) {
      showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: RoomImageWidget(
                    image: images.first,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              if (roomNumber != null)
                Positioned(
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "បន្ទប់ $roomNumber",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        int fullIdx = initialIndex;
        final pageCtrl = PageController(initialPage: initialIndex);
        return StatefulBuilder(
          builder: (ctx, setFullState) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: pageCtrl,
                  itemCount: images.length,
                  onPageChanged: (idx) => setFullState(() => fullIdx = idx),
                  itemBuilder: (ctx, i) {
                    return InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Center(
                        child: RoomImageWidget(
                          image: images[i],
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: MediaQuery.of(ctx).padding.top + 10,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${fullIdx + 1} / ${images.length}",
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                if (roomNumber != null)
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "បន្ទប់ $roomNumber",
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  State<RoomImageSliderWidget> createState() => _RoomImageSliderWidgetState();
}

class _RoomImageSliderWidgetState extends State<RoomImageSliderWidget> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullScreen(int initialIndex) {
    RoomImageSliderWidget.openFullScreenGallery(
      context,
      widget.images,
      roomNumber: widget.roomNumber,
      initialIndex: initialIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      final emptyChild = widget.fallback ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.meeting_room_rounded, size: 60, color: AppColors.primary.withValues(alpha: 0.7)),
                const SizedBox(height: 8),
                Text(
                  widget.roomNumber != null ? "បន្ទប់ ${widget.roomNumber}" : "បន្ទប់",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                ),
                if (widget.onAddOrChangePhoto != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isUploading) ...[
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "កំពុងបញ្ចូលរូបថត...",
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ] else ...[
                          const Icon(Icons.add_a_photo_outlined, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          const Text(
                            "ចុចដើម្បីបញ្ចូលរូបថតបន្ទប់",
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );

      return Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.primarySoft,
          border: widget.onAddOrChangePhoto != null
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5)
              : null,
        ),
        child: widget.onAddOrChangePhoto != null
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: widget.isUploading ? null : widget.onAddOrChangePhoto,
                  child: emptyChild,
                ),
              )
            : emptyChild,
      );
    }

    if (widget.images.length == 1) {
      return Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              RoomImageWidget(
                image: widget.images.first,
                fit: BoxFit.cover,
                heroTag: widget.heroTag,
                enableFullScreenViewer: true,
                roomNumber: widget.roomNumber,
              ),
              if (widget.onAddOrChangePhoto != null)
                Positioned(
                  top: 10,
                  left: 10,
                  child: GestureDetector(
                    onTap: widget.isUploading ? null : widget.onAddOrChangePhoto,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.isUploading) ...[
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              "កំពុងផ្ទុក...",
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ] else ...[
                            const Icon(Icons.camera_alt_outlined, size: 14, color: Colors.white),
                            const SizedBox(width: 5),
                            const Text(
                              "ប្តូររូបថត",
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => _openFullScreen(0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          "ចុចដើម្បីពង្រីក",
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Multiple images
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.images.length,
                  onPageChanged: (idx) => setState(() => _currentIndex = idx),
                  itemBuilder: (ctx, i) {
                    return GestureDetector(
                      onTap: () => _openFullScreen(i),
                      child: RoomImageWidget(
                        image: widget.images[i],
                        fit: BoxFit.cover,
                        heroTag: i == 0 ? widget.heroTag : null,
                      ),
                    );
                  },
                ),
                if (widget.onAddOrChangePhoto != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: GestureDetector(
                      onTap: widget.isUploading ? null : widget.onAddOrChangePhoto,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30, width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.isUploading) ...[
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                "កំពុងផ្ទុក...",
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ] else ...[
                              const Icon(Icons.add_photo_alternate_outlined, size: 14, color: Colors.white),
                              const SizedBox(width: 5),
                              const Text(
                                "ប្តូរ / បន្ថែមរូប",
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_outlined, size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          "${_currentIndex + 1} / ${widget.images.length}",
                          style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.images.length, (idx) {
                      final isActive = idx == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 6,
                        width: isActive ? 22 : 6,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => _openFullScreen(_currentIndex),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.zoom_in_rounded, size: 13, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            "ពង្រីក",
                            style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.images.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final isSelected = i == _currentIndex;
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: RoomImageWidget(
                      image: widget.images[i],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
