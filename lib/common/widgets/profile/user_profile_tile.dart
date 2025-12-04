import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../constants/colors.dart';
import 't_circular_image.dart';

class TUserProfileTile extends StatelessWidget {
  const TUserProfileTile({
    super.key,
    required this.onPressed,
    required this.fullName,
    required this.email,
    required this.avatar,
    required this.isNetworkImage,
  });

  final VoidCallback onPressed;
  final String fullName;
  final String email;
  final String avatar;
  final bool isNetworkImage;

  @override
  Widget build(BuildContext context) {

    return ListTile(
      leading: TCircularImage(
        image: avatar,
        width: 50,
        height: 50,
        padding: 0,
        isNetworkImage: isNetworkImage,
      ),
      title: Text(
        fullName,
        style: Theme.of(context).textTheme.headlineSmall!.apply(color: TColors.white),
      ),
      subtitle: Text(
        email,
        style: Theme.of(context).textTheme.bodyMedium!.apply(color: TColors.white, overflow: TextOverflow.ellipsis),
        maxLines: 1,
      ),
      trailing: IconButton(
        onPressed: onPressed,
        icon: const Icon(
          Iconsax.edit,
          color: TColors.white,
        ),
      ),
    );
  }
}
