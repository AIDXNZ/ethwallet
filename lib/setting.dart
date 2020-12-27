import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_beautiful_popup/main.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share/share.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: Hive.box('myBox').listenable(),
        builder: (context, box, widget) {
          return Scaffold(
            backgroundColor: box.get('darkMode') ? Colors.black : Colors.white,
            body: SafeArea(
                child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color:
                            box.get('darkMode') ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text(
                        'Dark Mode',
                        style: TextStyle(
                            color: box.get('darkMode')
                                ? Colors.white
                                : Colors.black),
                      ),
                      ValueListenableBuilder(
                          valueListenable: Hive.box('myBox').listenable(),
                          builder: (context, box, widget) {
                            return Center(
                              child: Switch(
                                  value:
                                      box.get('darkMode', defaultValue: false),
                                  onChanged: (val) {
                                    box.put('darkMode', val);
                                  }),
                            );
                          }),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text('Show login code',
                          style: TextStyle(
                              color: box.get('darkMode')
                                  ? Colors.white
                                  : Colors.black)),
                      IconButton(
                          icon: Icon(Icons.qr_code,
                              color: box.get('darkMode')
                                  ? Colors.white
                                  : Colors.black),
                          onPressed: () async {
                            var box = await Hive.openBox('myBox');
                            final popup = BeautifulPopup(
                              context: context,
                              template: TemplateAuthentication,
                            );
                            popup.show(
                              title: 'Scan to Login',
                              content: Center(
                                child: QrImage(
                                  data: box.get('wallet'),
                                ),
                              ),
                              actions: [
                                popup.button(
                                  label: 'Close',
                                  onPressed: Navigator.of(context).pop,
                                ),
                              ],
                              // bool barrierDismissible = false,
                              // Widget close,
                            );
                          })
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text('Back Up Wallet',
                          style: TextStyle(
                              color: box.get('darkMode')
                                  ? Colors.white
                                  : Colors.black)),
                      IconButton(
                          icon: Icon(Icons.download_rounded,
                              color: box.get('darkMode')
                                  ? Colors.white
                                  : Colors.black),
                          onPressed: () async {
                            var box = await Hive.openBox('myBox');
                            Share.share(box.get('wallet'));
                          })
                    ],
                  ),
                )
              ],
            )),
          );
        });
  }
}
