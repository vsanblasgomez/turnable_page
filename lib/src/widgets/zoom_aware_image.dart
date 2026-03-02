import 'package:flutter/widgets.dart';

/// A widget that swaps between a low-resolution and a high-resolution image
/// based on the current zoom state exposed by a [ValueListenable<bool>].
///
/// **Why use this instead of a plain [ValueListenableBuilder]?**
///
/// * Uses [gaplessPlayback] so the previous frame stays visible while the new
///   resolution loads — no white flash.
/// * Only *this* widget rebuilds when the zoom state changes; the rest of the
///   page tree is untouched.
/// * Keeps image-swap logic inside the library, so the page builder stays
///   simple.
///
/// ### Example
///
/// ```dart
/// TurnablePage(
///   pageCount: pages.length,
///   zoomNotifier: _zoomNotifier,
///   builder: (context, index, constraints) {
///     return ZoomAwareImage(
///       zoomNotifier: _zoomNotifier,
///       lowResImage: Image.asset('assets/low/page_$index.webp'),
///       highResImage: Image.asset('assets/high/page_$index.webp'),
///       fit: BoxFit.contain,
///     );
///   },
/// );
/// ```
class ZoomAwareImage extends StatelessWidget {
  /// Notifier that indicates whether the book is currently being zoomed.
  ///
  /// When `true`, [highResImage] is shown; otherwise [lowResImage] is shown.
  /// If **null**, [lowResImage] is always shown.
  final ValueNotifier<bool>? zoomNotifier;

  /// The image displayed at normal (1×) scale.
  final ImageProvider lowResImage;

  /// The image displayed when the user zooms in.
  ///
  /// If **null**, [lowResImage] is always used regardless of zoom state.
  final ImageProvider? highResImage;

  /// How the image should be inscribed into the space allocated to it.
  final BoxFit fit;

  /// Alignment of the image within its layout bounds.
  final Alignment alignment;

  /// Optional width constraint forwarded to [Image].
  final double? width;

  /// Optional height constraint forwarded to [Image].
  final double? height;

  const ZoomAwareImage({
    super.key,
    this.zoomNotifier,
    required this.lowResImage,
    this.highResImage,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Fast path: nothing to swap — just show the low-res image.
    if (zoomNotifier == null || highResImage == null) {
      return Image(
        image: lowResImage,
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        gaplessPlayback: true,
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: zoomNotifier!,
      builder: (context, isZooming, _) {
        final provider = isZooming ? highResImage! : lowResImage;
        return Image(
          image: provider,
          fit: fit,
          alignment: alignment,
          width: width,
          height: height,
          // Keep the old frame painted while the new resolution decodes.
          gaplessPlayback: true,
        );
      },
    );
  }
}
