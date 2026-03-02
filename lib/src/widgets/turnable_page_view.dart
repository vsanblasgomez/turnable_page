import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../turnable_page.dart';
import '../page/page_flip.dart';
import '../page/page_host.dart';
import 'paper_widget.dart';
import 'turnable_book_render_object_widget.dart';

class TurnablePageView extends StatefulWidget {
  final PageFlipController? controller;
  final PageWidgetBuilder builder;
  final int pageCount;
  final TurnablePageCallback? onPageChanged;
  final FlipSettings settings;
  final double aspectRatio;
  final Size bookSize;
  final PaperBoundaryDecoration paperBoundaryDecoration;
  final bool pagesBoundaryIsEnabled;
  final bool enableZoom;
  final PageCacheManager? cacheManager;

  const TurnablePageView({
    super.key,
    this.controller,
    this.onPageChanged,
    required this.builder,
    required this.pageCount,
    required this.aspectRatio,
    required this.bookSize,
    required this.settings,
    required this.paperBoundaryDecoration,
    this.pagesBoundaryIsEnabled = true,
    this.enableZoom = true,
    this.cacheManager,
  });

  @override
  State<TurnablePageView> createState() => _TurnablePageViewState();
}

class _TurnablePageViewState extends State<TurnablePageView>
    with SingleTickerProviderStateMixin {
  late PageFlip _pageFlip;
  bool _isZooming = false;
  int _pointerCount = 0;
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  /// Index of the currently visible (left) page, used to compute the
  /// rendering window.
  late int _currentPageIndex;

  FlipSettings get _settings => widget.settings.copyWith(
    width: widget.bookSize.width,
    height: widget.bookSize.height,
    startPage: widget.settings.startPageIndex,
  );

  @override
  void initState() {
    _currentPageIndex = widget.settings.startPageIndex;
    _pageFlip = PageFlip(_settings);
    _setupPageFlipEventsAndController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    super.initState();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    widget.cacheManager?.dispose();
    super.dispose();
  }

  int get pointerCount => _pointerCount;

  // ---------------------------------------------------------------
  //  Windowed rendering helpers
  // ---------------------------------------------------------------

  /// Compute page indices that must be in the widget tree.
  Set<int> _computeActiveIndices() {
    final isPortrait = _settings.usePortrait;
    final total = widget.pageCount;
    final current = _currentPageIndex.clamp(0, total - 1);
    final indices = <int>{};

    if (isPortrait) {
      // Single mode: current page ± 1 = max 3 pages.
      if (current > 0) indices.add(current - 1);
      indices.add(current);
      if (current < total - 1) indices.add(current + 1);
    } else {
      // Double mode: current spread + 1 prev spread + 1 next spread.
      // A generous window of current-3 .. current+4 covers any spread
      // arrangement (including covers).
      final start = (current - 3).clamp(0, total - 1);
      final end = (current + 4).clamp(0, total - 1);
      for (int i = start; i <= end; i++) {
        indices.add(i);
      }
    }
    return indices;
  }

  /// Build [PageHost] widgets for the current window.
  ///
  /// Each widget carries a [ValueKey] so that Flutter matches elements
  /// correctly across rebuilds — unchanged pages are **not** rebuilt.
  List<Widget> _buildWindowedChildren(BuildContext context) {
    final indices = _computeActiveIndices();
    final sorted = indices.toList()..sort();
    return sorted
        .map(
          (i) => PageHost(
            key: ValueKey<int>(i),
            index: i,
            child: widget.builder(context, i),
          ),
        )
        .toList();
  }

  Future<void> _setupPageFlipEventsAndController() async {
    widget.controller?.initializeController(pageFlip: _pageFlip);
    _pageFlip.on('flip', (_) {
      if (mounted) {
        final newIndex = _pageFlip.getCurrentPageIndex();
        final left = newIndex.clamp(0, widget.pageCount - 1);
        final right = (newIndex + 1 < widget.pageCount) ? newIndex + 1 : -1;
        widget.settings.startPageIndex = left;
        _pageFlip.updateSetting(_settings);

        // Shift the rendering window when the page changes.
        if (_currentPageIndex != left) {
          setState(() {
            _currentPageIndex = left;
          });
          // Evict images outside the cache window.
          widget.cacheManager?.onPageChanged(left, widget.pageCount);
        }

        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onPageChanged?.call(left, right);
          }
        });
      }
    });
  }

  void _onInteractionStart(ScaleStartDetails details) {
    if (widget.enableZoom) {
      _isZooming = true;
    }
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    if (widget.enableZoom && _isZooming) {
      _isZooming = false;
      _animateResetZoom();
    }
  }

  void _animateResetZoom() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 1.01) {
      final Matrix4 startMatrix = _transformationController.value.clone();
      final Matrix4 endMatrix = Matrix4.identity();

      _animation = Matrix4Tween(begin: startMatrix, end: endMatrix).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );

      _animation!.addListener(() {
        _transformationController.value = _animation!.value;
      });

      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final windowedChildren = _buildWindowedChildren(context);

    final bookContent = PaperWidget(
      size: widget.bookSize,
      isSinglePage: widget.settings.usePortrait,
      paperBoundaryDecoration: widget.paperBoundaryDecoration,
      isEnabled: widget.pagesBoundaryIsEnabled,
      child: TurnableBookRenderObjectWidget(
        totalPageCount: widget.pageCount,
        children: windowedChildren,
        settings: _settings,
        pageFlip: _pageFlip,
        isZooming: _isZooming || _pointerCount > 1,
      ),
    );

    if (!widget.enableZoom) {
      return bookContent;
    }

    return Listener(
      onPointerDown: (event) {
        setState(() {
          _pointerCount++;
          if (_pointerCount > 1) {
            _isZooming = true;
          }
        });
      },
      onPointerUp: (event) {
        if (_pointerCount <= 0) return;
        final wasZooming = _pointerCount > 1;
        setState(() {
          _pointerCount--;
          if (_pointerCount <= 1) {
            _isZooming = false;
          }
        });
        if (_pointerCount <= 1) {
          _animateResetZoom();
        }
        if (wasZooming) {
          _pageFlip.cancelCurrentFlip();
        }
      },
      onPointerCancel: (event) {
        if (_pointerCount <= 0) return;
        final wasZooming = _pointerCount > 1;
        setState(() {
          _pointerCount--;
          if (_pointerCount <= 1) {
            _isZooming = false;
          }
        });
        if (wasZooming) {
          _pageFlip.cancelCurrentFlip();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: GestureDetector(
        onScaleStart: _onInteractionStart,
        onScaleEnd: _onInteractionEnd,
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1.0,
          maxScale: 3.0,
          panEnabled: false,
          scaleEnabled: true,
          onInteractionStart: (details) {
            if (details.pointerCount > 1) {
              setState(() {
                _isZooming = true;
              });
            }
          },
          onInteractionEnd: (details) {
            setState(() {
              _isZooming = false;
            });
            _animateResetZoom();
          },
          child: bookContent,
        ),
      ),
    );
  }
}
