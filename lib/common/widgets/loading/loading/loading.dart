import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../../constants/colors.dart';


class TLoadingSpinkit {
  //Loading Page
  static const loadingPage = SpinKitFadingCube(
    color: TColors.primary,
    size: 30,
  );

  //Loading Image
  static const loadingImage = SpinKitFadingCircle(
    color: TColors.primary,
    size: 25.0,
  );

  //Loading Button
  static const loadingButton = SpinKitRing(
    color: TColors.primary,
    size: 30.0,
    lineWidth: 5,
  );
}
