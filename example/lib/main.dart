import 'package:example/screen_breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:ready_draggable_sheet/ready_draggable_sheet.dart';

void main() {
  runApp(const Root());
}

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> with ScreenBreakpoints {
  late final ValueNotifier<BuildContext> _contextReference = ValueNotifier<BuildContext>(context);

  /*@override
  void initState() {
    super.initState();
  }*/

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ready Draggable Scrollable Sheet',
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ),
        useMaterial3: true,
      ),
      home: Builder(
        builder: (BuildContext context) {
          ReadyDraggableScrollablePreferences.context = context;
          ReadyDraggableScrollablePreferences.getWidth = () => super.getMainContentWidth(context);

          return const Example();
        },
      ),
    );
  }
}

class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  final ReadyDraggableScrollableSheetController _favoriteSheetController = ReadyDraggableScrollableSheetController(
    label: 'Favorite',
    routeName: 'RDS_Favorite',
  );
  late final ReadyDraggableScrollableSheetContainer _favoriteSheet;

  @override
  void initState() {
    super.initState();

    _favoriteSheet = ReadyDraggableScrollableSheetContainer(
      // context: context,
      controller: _favoriteSheetController,
      openFromTop: true,
      content: <Flexible>[
        Flexible(
          child: Builder(
            builder: (BuildContext context) {
              final List<int> numbers = List.generate(
                11,
                (int index) => (index + 1),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: numbers.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          title: Text('Favorite item no. ${numbers[index]}'),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();

    _favoriteSheet.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('RDS Sheet'),
        ),
        body: Column(
          children: [
            // Favorites
            ElevatedButton(
              onPressed: () {
                _favoriteSheetController.toggle();
              },
              child: const Text('Favorites sheet'),
            ),

            // Open Settings route.
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => const Settings(),
                ),
              ),
              child: const Text('Open Settings route'),
            ),
          ],
        ),
      ),
    );
  }
}

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  ReadyDraggableScrollableSheetContainer? _settingsSheet;
  final ReadyDraggableScrollableSheetController _settingsSheetController = ReadyDraggableScrollableSheetController(
    label: 'Settings',
    routeName: 'RDS_Settings',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Settings
      _settingsSheet = ReadyDraggableScrollableSheetContainer(
        // context: context,
        controller: _settingsSheetController,
        withBarrier: false,
        fixedHeight: MediaQuery.of(context).size.height,
        header: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Header'),
          ],
        ),
        content: <Flexible>[
          Flexible(
            child: Builder(
              builder: (BuildContext context) {
                final List<int> numbers = List.generate(
                  5,
                  (int index) => (index + 1),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: numbers.length,
                        itemBuilder: (BuildContext context, int index) {
                          return ListTile(
                            title: Text('Settings item no. ${numbers[index]}'),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      );
    });
  }

  @override
  void dispose() {
    super.dispose();

    _settingsSheet?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: Column(
          children: [
            // Favorites
            ElevatedButton(
              onPressed: () => (!_settingsSheetController.open_ ? _settingsSheetController.open() : _settingsSheetController.close()),
              child: const Text('Settings sheet'),
            ),
          ],
        ),
      ),
    );
  }
}
