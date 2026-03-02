import 'package:flutter/painting.dart';

/// Callback that returns the [ImageProvider] used by a given page index.
///
/// The returned provider is used to call [ImageProvider.evict] when the page
/// falls outside the retained cache window.
typedef PageImageProviderBuilder = ImageProvider? Function(int pageIndex);

/// Manages Flutter's [ImageCache] so that only a bounded number of decoded
/// page images are kept in memory at any time.
///
/// Supports an optional **high-resolution** provider per page.  When the user
/// stops zooming, high-res entries that are no longer needed are evicted
/// automatically.
///
/// ### Usage
///
/// ```dart
/// final cacheManager = PageCacheManager(
///   maxCachedPages: 8,
///   imageProviderForPage: (i) => AssetImage('assets/low/page_$i.webp'),
///   highResProviderForPage: (i) => AssetImage('assets/high/page_$i.webp'),
/// );
/// ```
///
/// The library calls [onPageChanged] automatically whenever the visible page
/// changes.  Pages that fall outside the window are evicted via
/// [ImageProvider.evict], which removes only the specific decoded entry
/// from [ImageCache] without touching other cached images.
class PageCacheManager {
  /// Maximum number of page images to retain in the decoded cache.
  ///
  /// Defaults to 8.  Pages outside ±[maxCachedPages]~/2 of the current index
  /// are evicted.
  final int maxCachedPages;

  /// Builder that maps a page index to its **low-resolution** [ImageProvider].
  ///
  /// When **null**, no explicit eviction is performed and memory is controlled
  /// only by the windowed rendering (fewer widgets → fewer live images).
  final PageImageProviderBuilder? imageProviderForPage;

  /// Builder that maps a page index to its **high-resolution** [ImageProvider].
  ///
  /// When **null**, only the low-res provider is tracked for eviction.
  final PageImageProviderBuilder? highResProviderForPage;

  /// Pages whose low-res images are currently tracked as cached.
  final Set<int> _trackedPages = {};

  /// Pages whose high-res images are currently tracked as cached.
  final Set<int> _trackedHighRes = {};

  /// The last known current page (used by [onZoomEnd]).
  int _lastCurrentPage = 0;

  /// The last known total page count.
  int _lastTotalPages = 0;

  PageCacheManager({
    this.maxCachedPages = 8,
    this.imageProviderForPage,
    this.highResProviderForPage,
  });

  /// Called when the current visible page changes.
  ///
  /// [currentPageIndex] – 0-based index of the current (left) page.
  /// [totalPages]       – total number of pages in the book.
  void onPageChanged(int currentPageIndex, int totalPages) {
    _lastCurrentPage = currentPageIndex;
    _lastTotalPages = totalPages;

    if (imageProviderForPage == null) return;

    final half = maxCachedPages ~/ 2;
    final keepStart = (currentPageIndex - half).clamp(0, totalPages - 1);
    final keepEnd =
        (currentPageIndex + half - 1).clamp(0, totalPages - 1);

    final keepSet = <int>{};
    for (int i = keepStart; i <= keepEnd; i++) {
      keepSet.add(i);
    }

    // Evict low-res pages that left the window.
    final toEvict = _trackedPages.difference(keepSet);
    for (final pageIndex in toEvict) {
      imageProviderForPage!(pageIndex)?.evict();
    }
    _trackedPages
      ..removeAll(toEvict)
      ..addAll(keepSet);

    // Also evict high-res images that are outside the window.
    if (highResProviderForPage != null) {
      final highResToEvict = _trackedHighRes.difference(keepSet);
      for (final pageIndex in highResToEvict) {
        highResProviderForPage!(pageIndex)?.evict();
      }
      _trackedHighRes.removeAll(highResToEvict);
    }
  }

  /// Called when the user **starts** zooming.
  ///
  /// Marks the currently visible pages as having high-res images loaded so
  /// they can be evicted later.  This is a no-op if [highResProviderForPage]
  /// is null.
  void onZoomStart() {
    if (highResProviderForPage == null) return;
    // The visible spread is current + current+1 (double mode).
    _trackedHighRes.add(_lastCurrentPage);
    if (_lastCurrentPage + 1 < _lastTotalPages) {
      _trackedHighRes.add(_lastCurrentPage + 1);
    }
  }

  /// Called when the user **stops** zooming.
  ///
  /// Evicts high-res images for every tracked page, since only the low-res
  /// versions are needed at 1× scale.
  void onZoomEnd() {
    if (highResProviderForPage == null) return;
    for (final pageIndex in _trackedHighRes) {
      highResProviderForPage!(pageIndex)?.evict();
    }
    _trackedHighRes.clear();
  }

  /// Evict all tracked pages (both resolutions) from the cache.
  void dispose() {
    if (imageProviderForPage != null) {
      for (final pageIndex in _trackedPages) {
        imageProviderForPage!(pageIndex)?.evict();
      }
    }
    if (highResProviderForPage != null) {
      for (final pageIndex in _trackedHighRes) {
        highResProviderForPage!(pageIndex)?.evict();
      }
    }
    _trackedPages.clear();
    _trackedHighRes.clear();
  }
}
