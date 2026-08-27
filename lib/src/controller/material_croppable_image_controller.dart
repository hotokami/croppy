import 'package:croppy/src/src.dart';
import 'package:flutter/material.dart';

class MaterialCroppableImageController
    extends CroppableImageControllerWithMixins with AnimatedControllerMixin {
  MaterialCroppableImageController({
    required TickerProvider vsync,
    required super.imageProvider,
    required super.data,
    super.cropShapeFn,
    super.enabledTransformations,
    super.postProcessFn,
    super.minimumCropDimension,
    List<CropAspectRatio?>? allowedAspectRatios,
  }) : allowedAspectRatios =
            allowedAspectRatios ?? _createDefaultAspectRatios(data.imageSize) {
    initAnimationControllers(vsync);
    maybeSetAspectRatioOnInit();
  }

  @override
  final List<CropAspectRatio?> allowedAspectRatios;

  @override
  void onPanAndScale({
    required double scaleDelta,
    required Offset offsetDelta,
  }) {
    super.onPanAndScale(scaleDelta: scaleDelta, offsetDelta: offsetDelta);

    normalize();
    setViewportScale();
  }

  @override
  CroppableImageData onResizeImpl({
    required CroppableImageData data,
    required Offset offsetDelta,
    required ResizeDirection direction,
  }) {
    var newData = super.onResizeImpl(
      data: data,
      offsetDelta: offsetDelta,
      direction: direction,
    );

    final newAabb = FitPolygonInQuadSolver.solveWithStaticPointsAndAspectRatio(
      newData.cropShape.polygon.shift(newData.cropRect.topLeft.vector2),
      newData.transformedImageQuad,
      staticCorners: direction.staticCorners,
      aspectRatio: currentAspectRatio?.ratio,
    );

    // The solver returns non-finite values when it can't find a solution. In
    // that case, don't adopt the candidate rect: keep the pre-resize data so
    // this drag frame becomes a no-op.
    if (!_isFinite(newAabb)) {
      return data;
    }

    newData = newData.copyWith(
      cropRect: newAabb.rect,
    );

    return newData;
  }

  @override
  void onResize({
    required Offset offsetDelta,
    required ResizeDirection direction,
  }) {
    super.onResize(offsetDelta: offsetDelta, direction: direction);

    computeStaticCropRectDuringResize();
    setViewportScale(overrideCropRect: staticCropRect);
  }

  @override
  void onResizeEnd() {
    super.onResizeEnd();
    setViewportScaleWithAnimation();
  }

  @override
  void onStraighten({
    required double angleRad,
  }) {
    super.onStraighten(angleRad: angleRad);
    normalize();
    setViewportScale();
  }
}

bool _isFinite(Aabb2 aabb) =>
    aabb.min.x.isFinite &&
    aabb.min.y.isFinite &&
    aabb.max.x.isFinite &&
    aabb.max.y.isFinite;

List<CropAspectRatio?> _createDefaultAspectRatios(Size imageSize) {
  return [
    null,
    CropAspectRatio(
      width: imageSize.width.round(),
      height: imageSize.height.round(),
    ),
    CropAspectRatio(
      width: imageSize.height.round(),
      height: imageSize.width.round(),
    ),
    ..._basicAspectRatios,
  ];
}

const _basicAspectRatios = [
  CropAspectRatio(width: 1, height: 1),
  CropAspectRatio(width: 5, height: 4),
  CropAspectRatio(width: 4, height: 5),
  CropAspectRatio(width: 4, height: 3),
  CropAspectRatio(width: 3, height: 4),
  CropAspectRatio(width: 3, height: 2),
  CropAspectRatio(width: 2, height: 3),
  CropAspectRatio(width: 16, height: 9),
  CropAspectRatio(width: 9, height: 16),
];
