import 'package:chefd_app/social/feed.dart';
import 'package:chefd_app/theme/colors.dart';
import 'package:chefd_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:chefd_app/discover.dart';
import 'package:chefd_app/social/my_profile.dart';
import 'package:chefd_app/cookbook.dart';
import 'package:chefd_app/shopping_list.dart';

// Our stateful widget that is basically the skeleton
//of the UI that holds the Nav Bar
class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: BotNavBar());
  }
}

// The Bottom Navigation bar
class BotNavBar extends StatefulWidget {
  const BotNavBar({super.key});

  @override
  State<BotNavBar> createState() => _BotNavBarState();
}

int currenBotNavIndex = 0;
@override
void initState() {
  currenBotNavIndex = 0;
}

// Bot Nav bar currently redirects to Discover, MyProfile, and The Shopping Widgets.
class _BotNavBarState extends State<BotNavBar> {
  final List<Widget> children = [
    const DiscoverWidget(),
    const ShoppingList(),
    CookbookWidget(),
    const MyProfileWidget(),
    const FeedWidget(),
    //const SocialFeedWidget(),
  ];

  // When a Navigation Element is tapped, Update the selected index
  void onNavTapped(int index) {
    setState(() {
      currentBotNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: children[
          currentBotNavIndex], // The children are the buttons, Tapping reloads the state widget and changes the selection
      bottomNavigationBar: BottomNavigationBar(
        onTap: onNavTapped,
        currentIndex: currentBotNavIndex,
        backgroundColor: primaryOrange,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Discover"),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag), label: "Shopping List"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Cookbook"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "My Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: "Social"),
        ],
      ),
    );
  }
}
