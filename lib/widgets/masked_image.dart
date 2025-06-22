import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';

class MaskedImage extends StatefulWidget {
  final ImageProvider image;
  final ImageProvider mask;
  final ImageProvider? stroke;
  final double width;
  final double height;
  final Color? backgroundColor;

  const MaskedImage({
    super.key,
    required this.image,
    required this.mask,
    this.stroke,
    this.width = 130,
    this.height = 130,
    this.backgroundColor,
  });

  @override
  State<MaskedImage> createState() => _MaskedImageState();
}

class _MaskedImageState extends State<MaskedImage> {
  ui.Image? maskImage;

  @override
  void initState() {
    super.initState();
    _loadMask();
  }

  @override
  void didUpdateWidget(covariant MaskedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mask != oldWidget.mask) {
      _loadMask();
    }
  }

  Future<void> _loadMask() async {
    final completer = Completer<ui.Image>();
    final stream = widget.mask.resolve(const ImageConfiguration());
    final listener = ImageStreamListener((info, _) {
      if (!completer.isCompleted) {
        completer.complete(info.image);
      }
    });
    stream.addListener(listener);
    final image = await completer.future;
    stream.removeListener(listener);

    if (mounted) {
      setState(() {
        maskImage = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (maskImage == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Container(color: Colors.grey[200]),
      );
    }

    // 마스크 이미지를 카드 크기에 맞게 스케일링
    final double scaleX = widget.width / maskImage!.width;
    final double scaleY = widget.height / maskImage!.height;
    final Matrix4 matrix = Matrix4.identity()..scale(scaleX, scaleY);

    Widget content = ShaderMask(
      shaderCallback: (Rect bounds) {
        return ImageShader(
          maskImage!,
          TileMode.clamp,
          TileMode.clamp,
          matrix.storage,
        );
      },
      blendMode: BlendMode.dstIn,
      child: Container(
        color: widget.backgroundColor,
        child: Image(
          image: widget.image,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.cover,
        ),
      ),
    );

    if (widget.stroke != null) {
      content = Stack(
        fit: StackFit.passthrough,
        children: [content, Image(image: widget.stroke!, fit: BoxFit.fill)],
      );
    }

    return SizedBox(width: widget.width, height: widget.height, child: content);
  }
}
