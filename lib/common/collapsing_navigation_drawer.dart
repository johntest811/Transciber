import 'package:flutter/material.dart';
import '../model/navigation_model.dart';
import 'collapsing_list_tile.dart';
import '../theme.dart';

class CollapsingNavigationDrawer extends StatefulWidget {
  const CollapsingNavigationDrawer({super.key});

  @override
  State<CollapsingNavigationDrawer> createState() => _CollapsingNavigationDrawerState();
}

class _CollapsingNavigationDrawerState extends State<CollapsingNavigationDrawer> with SingleTickerProviderStateMixin {
  double maxWidth = 250;
  double minWidth = 70;
  bool isCollapsed = false;
  late AnimationController _animationController;
  late Animation<double> widthAnimation;
  int currentSelectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    widthAnimation = Tween<double>(begin: maxWidth, end: minWidth).animate(_animationController);
  }

  void toggleDrawer() {
    setState(() {
      isCollapsed = !isCollapsed;
      isCollapsed ? _animationController.forward() : _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        // Detect swipe direction: Expand on right swipe, Collapse on left swipe
        if (details.primaryDelta! > 5) {
          if (isCollapsed) toggleDrawer();
        } else if (details.primaryDelta! < -5) {
          if (!isCollapsed) toggleDrawer();
        }
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, widget) => getWidget(context, widget),
      ),
    );
  }

  Widget getWidget(context, widget) {
    return Container(
      width: widthAnimation.value,
      color: drawerBackgroundColor,
      child: Column(
        children: <Widget>[
          SizedBox(height: 50.0),
          Expanded(
            child: ListView.builder(
              itemCount: navigationItems.length,
              itemBuilder: (context, counter) {
                return CollapsingListTile(
                  title: navigationItems[counter].title,
                  icon: navigationItems[counter].icon,
                  isSelected: currentSelectedIndex == counter,
                  onTap: () {
                    setState(() {
                      currentSelectedIndex = counter;
                    });

                    // Navigate to the selected page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => navigationItems[counter].page),
                    );
                  },
                  animationController: _animationController,
                );
              },
            ),
          ),
          InkWell(
            onTap: toggleDrawer,
            child: Icon(isCollapsed ? Icons.chevron_right : Icons.chevron_left, color: Colors.white, size: 50.0),
          ),
          SizedBox(height: 50.0),
        ],
      ),
    );
  }
}
