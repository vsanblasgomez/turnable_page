import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../turnable_page.dart';
import '../page/page_flip.dart';
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

  FlipSettings get _settings => widget.settings.copyWith(
    width: widget.bookSize.width,
    height: widget.bookSize.height,
    startPage: widget.settings.startPageIndex,
  );

  @override
  void initState() {
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
    super.dispose();
  }

  int get pointerCount => _pointerCount;

  Future<void> _setupPageFlipEventsAndController() async {
    widget.controller?.initializeController(pageFlip: _pageFlip);
    _pageFlip.on('flip', (_) {
      if (mounted) {
        final newIndex = _pageFlip.getCurrentPageIndex();
        final left = newIndex.clamp(0, widget.pageCount - 1);
        final right = (newIndex + 1 < widget.pageCount) ? newIndex + 1 : -1;
        widget.settings.startPageIndex = left;
        _pageFlip.updateSetting(_settings);
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
    final bookContent = PaperWidget(
      size: widget.bookSize,
      isSinglePage: widget.settings.usePortrait,
      paperBoundaryDecoration: widget.paperBoundaryDecoration,
      isEnabled: widget.pagesBoundaryIsEnabled,
      child: TurnableBookRenderObjectWidget(
        pageCount: widget.pageCount,
        builder: (ctx, index) => widget.builder(ctx, index),
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
