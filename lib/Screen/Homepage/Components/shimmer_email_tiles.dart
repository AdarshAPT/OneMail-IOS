import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Utils/color_pallet.dart';

class ShimmerTile extends StatefulWidget {
  const ShimmerTile({Key? key}) : super(key: key);

  @override
  _ShimmerTileState createState() => _ShimmerTileState();
}

class _ShimmerTileState extends State<ShimmerTile>
    with SingleTickerProviderStateMixin {
  final Themes themes = Get.find(tag: 'theme');
  late AnimationController animation;
  late Animation<double> _fadeInFadeOut;

  @override
  initState() {
    animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeInFadeOut = Tween<double>(begin: 0.5, end: 1).animate(animation);

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animation.reverse();
      } else if (status == AnimationStatus.dismissed) {
        animation.forward();
      }
    });
    animation.forward();
    super.initState();
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: ListView.separated(
            itemCount: 10,
            shrinkWrap: true,
            separatorBuilder: (context, index) => const SizedBox(
              height: 10,
            ),
            itemBuilder: (_, idx) => FadeTransition(
              opacity: _fadeInFadeOut,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.withOpacity(0.2),
                ),
                title: Container(
                  height: 20,
                  width: MediaQuery.of(context).size.width / 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    height: 40,
                    width: MediaQuery.of(context).size.width / 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
