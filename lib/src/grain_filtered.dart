import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

/// A widget that applies a grain filter to its child.
/// 
/// The grain filter is animated by default. To disable the animation, set
/// [animated] to false.
/// 
/// The grain filter is applied using a [ShaderMask] widget. The [ShaderMask]
/// widget is applied using a [Shader] that is created from an [ImageShader].
/// The [ImageShader] is created from an [Image] that is loaded from an asset.
/// 
/// [child] is the widget that the grain filter is applied to.
/// [frameDuration] is the duration between each frame of the animation.
/// [scale] is the scale of the grain filter. The default value is 0.3.
/// [animated] is whether the grain filter is animated. The default value is true.
class GrainFiltered extends StatefulWidget {
  final Widget child;
  final bool animated;
  final Duration frameDuration;
  final double scale;

  const GrainFiltered({
    super.key,
    required this.child,
    this.animated = true,
    this.frameDuration = const Duration(milliseconds: 50),
    this.scale = 0.3,
  });

  @override
  State<GrainFiltered> createState() => _GrainFilteredState();
}

class _GrainFilteredState extends State<GrainFiltered> {
  Timer? _timer;
  late Future<ui.Image> _imageFuture;
  final Matrix4 _matrix4 = Matrix4.identity();

  @override
  void didChangeDependencies() {
    _imageFuture = _loadImage();

      _matrix4.scale(widget.scale, widget.scale, 1);
    if (_timer?.isActive ?? false) _timer!.cancel();
    
    _timer = Timer.periodic(widget.frameDuration, (Timer timer) {
      if (!widget.animated) return;
      _matrix4.rotateZ(10);
      setState(() {});
    });

    super.didChangeDependencies();
  }

  @override
  dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<ui.Image> _loadImage() async {
    final imageBytes = await rootBundle.load('packages/grain/assets/grain.png');
    return decodeImageFromList(imageBytes.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _imageFuture,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.child;
        }

        return ShaderMask(
          blendMode: BlendMode.screen,
          shaderCallback: (Rect bounds) {
            return ImageShader(
              snapshot.data,
              TileMode.mirror,
              TileMode.mirror,
              _matrix4.storage,
            );
          },
          child: widget.child,
        );
      },
    );
  }
}
