import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../render/turnable_parent_data.dart';

class PageHost extends SingleChildRenderObjectWidget {
  final int index;

  const PageHost({super.key, required this.index, required Widget child})
    : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => _PageRender(index);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as _PageRender).index = index;
  }
}

class _PageRender extends RenderProxyBox {
  _PageRender(int index) : _index = index;

  int _index;
  int get index => _index;
  set index(int value) {
    if (_index != value) {
      _index = value;
      _syncPageIndex();
      markParentNeedsLayout();
    }
  }

  void _syncPageIndex() {
    if (parentData is TurnableParentData) {
      (parentData as TurnableParentData).pageIndex = _index;
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _syncPageIndex();
  }

  @override
  void setupParentData(RenderObject child) {
    // Side-effect: also keep our own parentData.pageIndex in sync.
    _syncPageIndex();
  }
}
