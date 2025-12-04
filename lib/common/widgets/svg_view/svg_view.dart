import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgView extends StatelessWidget {
  final String path;
  final Color? color;
  final BlendMode? blendMode;
  final BoxFit fit;
  final double? height;
  final double? width;
  final double? dimension;

  const SvgView(
    this.path, {
    super.key,
    this.color,
    this.blendMode,
    this.fit = BoxFit.contain,
    this.height,
    this.width,
    this.dimension,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: dimension,
      child: SvgPicture.asset(
        path,
        fit: fit,
        height: height,
        width: width,
        colorFilter: color != null
            ? ColorFilter.mode(color!, blendMode ?? BlendMode.srcIn)
            : null,
      ),
    );
  }
}
