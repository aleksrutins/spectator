import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spectator/pages/scan.dart';
import 'package:worker_manager/worker_manager.dart';

void main() async {
  workerManager.log = true;
  await workerManager.init();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      builder: (context, child) =>
          FTheme(data: FThemes.zinc.light, child: child!),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool _agreedToTerms = false;

  StatefulWidget Function({Key? key}) page = ScanPage.new;

  @override
  void initState() {
    super.initState();
    loadTerms();
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  Future<void> loadTerms() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _agreedToTerms = prefs.getBool("agreedToTerms") ?? false;
    });
    if (!_agreedToTerms && mounted) {
      showFDialog(
        context: context,
        style: context.theme.dialogStyle
            .copyWith(
              barrierFilter: (animation) => ImageFilter.compose(
                outer: ImageFilter.blur(
                  sigmaX: animation * 5,
                  sigmaY: animation * 5,
                ),
                inner: ColorFilter.mode(
                  context.theme.colors.barrier,
                  BlendMode.srcOver,
                ),
              ),
            )
            .call,
        builder: (context, style, animation) => FDialog(
          style: style.call,
          animation: animation,
          direction: Axis.horizontal,
          title: const Text("Terms of Use"),
          body: const Text(
            "By using this software, you agree to use it for legitimate purposes only. The developers of this software shall not be held liable for any disagreements resulting from the use of this software.",
          ),
          actions: [
            FButton(
              onPress: () {
                agreeToTerms();
                Navigator.of(context).pop();
              },
              child: Text("Agree"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> agreeToTerms() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _agreedToTerms = true;
      prefs.setBool("agreedToTerms", true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return FScaffold(
      sidebar: FSidebar(
        children: [
          FSidebarGroup(
            label: const Text("Tools"),
            children: [
              FSidebarItem(
                icon: const Icon(FIcons.wifiHigh),
                label: const Text("Network Scan"),
                onPress: () {
                  setState(() {
                    page = ScanPage.new;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      child: Padding(padding: EdgeInsets.all(10), child: page()),
      //iling comma makes auto-formatting nicer for build methods.
    );
  }
}
