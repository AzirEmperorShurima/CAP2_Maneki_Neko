import 'package:finance_management_app/app/navigation_menu/models/rive_model.dart';

class NavItemModel {
  final String title;
  final RiveModel rive;

  NavItemModel({
    required this.title,
    required this.rive,
  });
}

List<NavItemModel> bottomNavItems = [
  NavItemModel(
    title: "Home",
    rive: RiveModel(
      src: "assets/animated-icons.riv",
      artboard: "HOME",
      stateMachineName: "HOME_interactivity",
    ),
  ),
  NavItemModel(
    title: "Chat",
    rive: RiveModel(
      src: "assets/animated-icons.riv",
      artboard: "CHAT",
      stateMachineName: "CHAT_Interactivity",
    ),
  ),
  NavItemModel(
    title: "Transactions",
    rive: RiveModel(
      src: "assets/animated-icons.riv",
      artboard: "REFRESH/RELOAD",
      stateMachineName: "RELOAD_Interactivity",
    ),
  ),
  NavItemModel(
    title: "Bell",
    rive: RiveModel(
      src: "assets/animated-icons.riv",
      artboard: "BELL",
      stateMachineName: "BELL_Interactivity",
    ),
  ),
  NavItemModel(
    title: "Profile",
    rive: RiveModel(
      src: "assets/animated-icons.riv",
      artboard: "USER",
      stateMachineName: "USER_Interactivity",
    ),
  ),
];
