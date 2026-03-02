import 'package:flutter/painting.dart';

/// Callback that returns the [ImageProvider] used by a given page index.
///
/// The returned provider is used to call [ImageProvider.evict] when the page
/// falls outside the retained cache window.
typedef PageImageProviderBuilder = ImageProvider? Function(int pageIndex);

/// Manages Flutter's [ImageCache] so that only a bounded number of decoded
/// page images are kept in memory at any time.
///
/// ### Usage
///
/// Create an instance and pass it to [TurnablePage] (or [TurnablePageView]):
///
/// ```dart
/// final cacheManager = PageCacheManager(
///   maxCachedPages: 8,
///   imageProviderForPage: (index) => AssetImage('assets/page_$index.webp'),
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

  /// Optional builder that maps a page index to its [ImageProvider].
  ///
  /// When **null**, no explicit eviction is performed and memory is controlled
  /// only by the windowed rendering (fewer widgets → fewer live images).
  final PageImageProviderBuilder? imageProviderForPage;

  /// Pages currently tracked as cached.
  final Set<int> _trackedPages = {};

  PageCacheManager({
    this.maxCachedPages = 8,
    this.imageProviderForPage,
  });

  /// Called when the current visible page changes.
  ///
  /// [currentPageIndex] – 0-based index of the current (left) page.
  /// [totalPages]       – total number of pages in the book.
  void onPageChanged(int currentPageIndex, int totalPages) {
    if (imageProviderForPage == null) return;

    final half = maxCachedPages ~/ 2;
    final keepStart = (currentPageIndex - half).clamp(0, totalPages - 1);
    final keepEnd =
        (currentPageIndex + half - 1).clamp(0, totalPages - 1);

    final keepSet = <int>{};
    for (int i = keepStart; i <= keepEnd; i++) {
      keepSet.add(i);
    }

    // Evict pages that left the window.
    final toEvict = _trackedPages.difference(keepSet);
    for (final pageIndex in toEvict) {
      final provider = imageProviderForPage!(pageIndex);
      provider?.evict();
    }

    _trackedPages
      ..removeAll(toEvict)
      ..addAll(keepSet);
  }

  /// Evict all tracked pages from the cache.
  void dispose() {
    if (imageProviderForPage == null) return;
    for (final pageIndex in _trackedPages) {
      imageProviderForPage!(pageIndex)?.evict();
    }
    _trackedPages.clear();
  }
}
