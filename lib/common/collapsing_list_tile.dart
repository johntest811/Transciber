import 'package:flutter/material.dart';
import '../theme.dart';

class CollapsingListTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final Function onTap;
  final AnimationController animationController;

  CollapsingListTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.animationController,
  });

  @override
  State<CollapsingListTile> createState() => _CollapsingListTileState();
}

class _CollapsingListTileState extends State<CollapsingListTile> {
  late Animation<double> widthAnimation;

  @override
  void initState() {
    super.initState();
    widthAnimation = Tween<double>(begin: 250, end: 70).animate(widget.animationController);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => widget.onTap(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
          color: widget.isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
        ),
        width: widthAnimation.value,
        margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          children: <Widget>[
            Icon(widget.icon, color: widget.isSelected ? Colors.white : Colors.white30),
            SizedBox(width: 10.0),
            if (widthAnimation.value >= 200)
              Text(widget.title, style: listTitleDefaultTextStyle),
          ],
        ),
      ),
    );
  }
}
