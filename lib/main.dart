import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'disclaimer.dart';
import 'screens/cabinet_screen.dart';
import 'screens/members_screen.dart';
import 'screens/more_screen.dart';
import 'screens/news_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyMpApp());
}

class MyMpApp extends StatelessWidget {
  const MyMpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'আমার এমপি',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const Shell(),
      builder: (context, child) {
        // A reader who has made the system font large gets it, up to a point:
        // past 1.3 the Bengali headlines start breaking mid-word inside cards.
        final scale = MediaQuery.textScalerOf(
          context,
        ).clamp(minScaleFactor: 0.9, maxScaleFactor: 1.3);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scale),
          child: child!,
        );
      },
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  // Held in an IndexedStack, so a reader who scrolled the member list halfway
  // down and went to look at the news comes back to where they were.
  final _screens = const [
    MembersScreen(),
    NewsScreen(),
    CabinetScreen(),
    MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Once, on first launch: this is not a government app, and where its information comes from.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => showDisclaimerOnce(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.rule)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded),
              label: 'সংসদ সদস্য',
            ),
            NavigationDestination(
              icon: Icon(Icons.article_outlined),
              selectedIcon: Icon(Icons.article_rounded),
              label: 'সংবাদ',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_outlined),
              selectedIcon: Icon(Icons.account_balance_rounded),
              label: 'মন্ত্রিসভা',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz_rounded),
              selectedIcon: Icon(Icons.more_horiz_rounded),
              label: 'আরও',
            ),
          ],
        ),
      ),
    );
  }
}
