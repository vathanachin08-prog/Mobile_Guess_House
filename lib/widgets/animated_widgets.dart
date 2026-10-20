import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../core/services/language_service.dart';
import 'app_colors.dart';

/// 1. Rolling Number Animation (Counts up smoothly e.g. 0 -> 12, $0.00 -> $1,450.00)
class AnimatedCountText extends StatelessWidget {
  final num value;
  final String prefix;
  final String suffix;
  final int decimalPlaces;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  const AnimatedCountText({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.decimalPlaces = 0,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, animValue, child) {
        final formattedNumber = decimalPlaces > 0
            ? animValue.toStringAsFixed(decimalPlaces)
            : animValue.toInt().toString();

        return Text(
          "$prefix$formattedNumber$suffix",
          style: style ?? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        );
      },
    );
  }
}

/// 2. Smooth Expanding Progress Bar
class AnimatedProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Color backgroundColor;
  final Color foregroundColor;
  final BorderRadius? borderRadius;
  final Duration duration;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 8.0,
    this.backgroundColor = AppColors.border,
    this.foregroundColor = AppColors.primary,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(height / 2);

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: Container(
        height: height,
        color: backgroundColor,
        width: double.infinity,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: value.clamp(0.0, 1.0)),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (context, animVal, child) {
            return FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: animVal,
              child: Container(
                decoration: BoxDecoration(
                  color: foregroundColor,
                  borderRadius: effectiveRadius,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 3. Pulsing / Breathing Badge for Notifications & Urgent Alerts
class PulsingBadge extends StatefulWidget {
  final Widget child;
  final bool isPulsing;
  final Color? glowColor;

  const PulsingBadge({
    super.key,
    required this.child,
    this.isPulsing = true,
    this.glowColor,
  });

  @override
  State<PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<PulsingBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulsingBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPulsing && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPulsing) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 4. Micro-interaction: Bouncing scale on touch
class BouncingWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  const BouncingWidget({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.95,
  });

  @override
  State<BouncingWidget> createState() => _BouncingWidgetState();
}

class _BouncingWidgetState extends State<BouncingWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// 5. Smooth Fade & Slide-In Animation for list items and cards
class FadeSlideEntrance extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  const FadeSlideEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.offset = const Offset(0, 0.08),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration + delay,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              offset.dx * (1 - value) * 100,
              offset.dy * (1 - value) * 100,
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// 6. Bouncy Favorite Heart Animation with Pop & Expanding Ripple Ring
class FavoriteHeartButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback? onTap;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final Color? backgroundColor;
  final EdgeInsets padding;

  const FavoriteHeartButton({
    super.key,
    required this.isFavorite,
    this.onTap,
    this.size = 20,
    this.activeColor = const Color(0xFFE53935),
    this.inactiveColor = AppColors.textSecondary,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(4.0),
  });

  @override
  State<FavoriteHeartButton> createState() => _FavoriteHeartButtonState();
}

class _FavoriteHeartButtonState extends State<FavoriteHeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rippleAnimation;
  late final Animation<double> _rippleOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Elastic pop sequence: 1.0 -> 0.7 -> 1.45 -> 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.7)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.7, end: 1.45)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.45, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
    ]).animate(_controller);

    // Expanding ripple ring
    _rippleAnimation = Tween<double>(begin: 0.6, end: 2.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _rippleOpacity = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant FavoriteHeartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite != oldWidget.isFavorite && widget.isFavorite) {
      _controller.forward(from: 0.0);
    }
  }

  void _handleTap() {
    _controller.forward(from: 0.0);
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Exploding ripple ring
            if (_controller.isAnimating && widget.isFavorite)
              Transform.scale(
                scale: _rippleAnimation.value,
                child: Opacity(
                  opacity: _rippleOpacity.value,
                  child: Container(
                    width: widget.size + 4,
                    height: widget.size + 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.activeColor,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              ),
            // Bouncing Heart Icon
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                size: widget.size,
                color: widget.isFavorite ? widget.activeColor : widget.inactiveColor,
              ),
            ),
          ],
        );
      },
    );

    if (widget.backgroundColor != null) {
      content = Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          shape: BoxShape.circle,
        ),
        child: content,
      );
    } else {
      content = Padding(
        padding: widget.padding,
        child: content,
      );
    }

    return InkWell(
      onTap: widget.onTap != null ? _handleTap : null,
      borderRadius: BorderRadius.circular(30),
      child: content,
    );
  }
}

/// 7. Interactive Ultra-Smooth Sliding Language Toggle
/// Dual-capsule sliding switch with physical spring glide, zero layout shifts,
/// and decoupled thread execution for locked 60/120 FPS smoothness.
class AnimatedLanguageToggle extends StatefulWidget {
  final bool compact;
  final VoidCallback? onToggled;

  const AnimatedLanguageToggle({
    super.key,
    this.compact = true,
    this.onToggled,
  });

  @override
  State<AnimatedLanguageToggle> createState() => _AnimatedLanguageToggleState();
}

class _AnimatedLanguageToggleState extends State<AnimatedLanguageToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnimation;
  bool _isToggling = false;
  late bool _localIsKhmer;

  @override
  void initState() {
    super.initState();
    _localIsKhmer = LanguageService.isKhmer;

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Subtle press-down & spring bounce: 1.0 -> 0.94 -> 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.94)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.94, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap([bool? targetIsKhmer]) async {
    if (_isToggling) return;
    _isToggling = true;

    final currentIsKm = _localIsKhmer;
    final nextIsKm = targetIsKhmer ?? !currentIsKm;
    if (nextIsKm == currentIsKm && targetIsKhmer != null) {
      _isToggling = false;
      return;
    }

    try {
      HapticFeedback.selectionClick();
    } catch (_) {}

    _bounceController.forward(from: 0.0);

    // 1. Instant local state update ensures the glide animation starts immediately at 60/120fps
    setState(() {
      _localIsKhmer = nextIsKm;
    });

    // 2. Wait 130ms so the thumb glides smoothly before heavy global widget tree rebuilds
    await Future.delayed(const Duration(milliseconds: 130));

    // 3. Trigger global app-wide locale update
    await LanguageService.switchLanguage(nextIsKm ? 'km' : 'en');

    _isToggling = false;
    widget.onToggled?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Sync with global locale if changed externally
      final globalIsKm = LanguageService.isKhmer;
      if (!_isToggling && _localIsKhmer != globalIsKm) {
        _localIsKhmer = globalIsKm;
      }

      final isKm = _localIsKhmer;
      final totalWidth = widget.compact ? 84.0 : 100.0;
      final totalHeight = widget.compact ? 29.0 : 33.0;
      final thumbWidth = (totalWidth - 6) / 2;
      final thumbHeight = totalHeight - 6;

      return RepaintBoundary(
        child: Tooltip(
          message: isKm ? "ប្តូរទៅ English" : "Switch to ភាសាខ្មែរ",
          child: AnimatedBuilder(
            animation: _bounceController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: GestureDetector(
              onTap: () => _handleTap(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: totalWidth,
                height: totalHeight,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(totalHeight / 2),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Sliding white capsule thumb
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.fastOutSlowIn,
                      alignment: isKm ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        width: thumbWidth,
                        height: thumbHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(thumbHeight / 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            ),
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 2,
                              offset: const Offset(0, 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Two clickable labels: 🇰🇭 KH and 🇺🇸 EN
                    Row(
                      children: [
                        // Left: Khmer
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _handleTap(true),
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: widget.compact ? 10.5 : 12.0,
                                  fontWeight: isKm ? FontWeight.bold : FontWeight.w500,
                                  color: isKm
                                      ? AppColors.primary
                                      : AppColors.textSecondary.withValues(alpha: 0.7),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('🇰🇭', style: TextStyle(fontSize: 11)),
                                    SizedBox(width: 2.5),
                                    Text('KH'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Right: English
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _handleTap(false),
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: widget.compact ? 10.5 : 12.0,
                                  fontWeight: !isKm ? FontWeight.bold : FontWeight.w500,
                                  color: !isKm
                                      ? AppColors.primary
                                      : AppColors.textSecondary.withValues(alpha: 0.7),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('🇺🇸', style: TextStyle(fontSize: 11)),
                                    SizedBox(width: 2.5),
                                    Text('EN'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}


