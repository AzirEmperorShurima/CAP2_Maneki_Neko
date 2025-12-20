import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../constants/colors.dart';
import '../../../constants/image_strings.dart';
import '../../../constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../animations/shimmer.dart';

class TCircularImage extends StatelessWidget {
  final BoxFit? fit;

  final String image;

  final bool isNetworkImage;

  final Color? overlayColor;

  final Color? backgroundColor;

  final double width, height, padding;

  final BorderRadius? borderRadius;

  const TCircularImage({
    super.key,
    this.fit = BoxFit.cover,
    required this.image,
    this.isNetworkImage = false,
    this.overlayColor,
    this.backgroundColor,
    this.width = 50,
    this.height = 50,
    this.padding = TSizes.xs,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor ??
            (THelperFunctions.isDarkMode(context)
                ? TColors.black
                : TColors.white),
        borderRadius: borderRadius ?? BorderRadius.circular(100),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(100),
        child: isNetworkImage
            ? CachedNetworkImage(
                fit: fit,
                imageUrl: image,
                color: overlayColor,
                progressIndicatorBuilder: (context, url, progress) =>
                    TShimmerEffect(
                  width: width,
                  height: height,
                ),
                errorWidget: (context, url, error) => Image(
                  fit: fit,
                  image: const AssetImage(TImages.user),
                  color: overlayColor,
                ),
              )
            : Image(
                fit: fit,
                image: AssetImage(image),
                color: overlayColor,
              ),
      ),
    );
  }
}
