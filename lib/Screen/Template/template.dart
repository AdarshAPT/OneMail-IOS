import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:oneMail/Model/template_model.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/custom_glow_behaviour.dart';

class TemplateScreen extends StatefulWidget {
  final List<TemplateModel> templates;
  const TemplateScreen({Key? key, required this.templates}) : super(key: key);

  @override
  _TemplateScreenState createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen> {
  final Themes themes = Get.find(tag: "theme");

  Widget templateUI(int index) {
    String title = widget.templates[index].templateHeader;
    String body = widget.templates[index].templateBody;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: ExpandablePanel(
            theme: ExpandableThemeData(
              headerAlignment: ExpandablePanelHeaderAlignment.center,
              hasIcon: true,
              iconColor: themes.isDark.value
                  ? Colors.white
                  : ColorPallete.primaryColor,
              tapBodyToCollapse: true,
              tapHeaderToExpand: true,
              tapBodyToExpand: true,
              useInkWell: false,
            ),
            header: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.5,
                      color:
                          themes.isDark.value ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: "$title\n$body"))
                        .then(
                      (_) {
                        Fluttertoast.showToast(msg: "Copied to clipboard");
                      },
                    );
                  },
                  icon: Icon(
                    Feather.copy,
                    color: themes.isDark.value
                        ? Colors.white
                        : ColorPallete.primaryColor,
                  ),
                )
              ],
            ),
            expanded: Text(
              body,
              style: TextStyle(
                fontSize: 15.5,
                color: themes.isDark.value ? Colors.white70 : Colors.black87,
              ),
            ),
            collapsed: Text(
              body,
              softWrap: true,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.5,
                color: themes.isDark.value ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
      appBar: AppBar(
        backgroundColor: themes.isDark.value
            ? themes.isDark.value
                ? ColorPallete.darkModeColor
                : Colors.white
            : ColorPallete.primaryColor,
        elevation: 0.5,
        title: const Text(
          "Templates",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
        child: ScrollConfiguration(
          behavior: CustomBehavior(),
          child: CupertinoScrollbar(
            child: ListView.builder(
              itemCount: widget.templates.length,
              itemBuilder: (context, index) {
                return templateUI(index);
              },
            ),
          ),
        ),
      ),
    );
  }
}
