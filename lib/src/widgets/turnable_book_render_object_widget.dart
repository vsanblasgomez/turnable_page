import 'package:flutter/widgets.dart';

import '../../turnable_page.dart';
import '../page/page_flip.dart';
import '../render/render_turnable_book.dart';

/// Render-object widget that holds only the *windowed* subset of pages.
///
/// [children] must already be wrapped in `PageHost` widgets carrying the
/// correct page indices.  The [totalPageCount] tells the render object
/// how many pages exist in the entire book (needed for white-page logic
/// and collection initialisation).
class TurnableBookRenderObjectWidget extends MultiChildRenderObjectWidget {
  final int totalPageCount;
  final FlipSettings settings;
  final PageFlip pageFlip;
  final bool isZooming;

  const TurnableBookRenderObjectWidget({
    super.key,
    required this.totalPageCount,
    required super.children,
    required this.settings,
    required this.pageFlip,
    this.isZooming = false,
  });

  @override
  RenderTurnableBook createRenderObject(BuildContext context) {
    final render = RenderTurnableBook(settings, pageFlip, totalPageCount);
    render.isZooming = isZooming;
    return render;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTurnableBook renderObject,
  ) {
    renderObject.totalPageCount = totalPageCount;
    renderObject.updateSettings(settings);
    renderObject.isZooming = isZooming;
  }
}
