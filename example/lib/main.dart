import 'package:flutter/material.dart';
import 'package:ready_draggable_sheet/ready_draggable_sheet.dart';

void main() {
  runApp(const Root());
}

class Root extends StatelessWidget {
  const Root({super.key});

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
      home: const Example(),
    );
  }
}

class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  ReadyDraggableScrollableSheetContainer? _favoriteSheet;
  final ReadyDraggableScrollableSheetController _favoriteSheetController = ReadyDraggableScrollableSheetController(
    label: 'Favorite',
    routeName: 'RDS_Favorite',
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Favorite
      _favoriteSheet = ReadyDraggableScrollableSheetContainer(
        context: context,
        controller: _favoriteSheetController,
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
                        physics: NeverScrollableScrollPhysics(),
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
    });
  }

  @override
  void dispose() {
    super.dispose();

    _favoriteSheet?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('RDS Sheet'),
        ),
        body: Container(
          child: Column(
            children: [
              // Favorites
              ElevatedButton(
                onPressed: () => (!_favoriteSheetController.open_ ? _favoriteSheetController.open() : _favoriteSheetController.close(context)),
                child: Text('Favorites sheet'),
              ),

              // Open Settings route.
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) => Settings(),
                  ),
                ),
                child: Text('Open Settings route'),
              ),
            ],
          ),
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
        context: context,
        controller: _settingsSheetController,
        withBarrier: false,
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
                        physics: NeverScrollableScrollPhysics(),
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
          title: Text('Settings'),
        ),
        body: Container(
          child: Column(
            children: [
              // Favorites
              ElevatedButton(
                onPressed: () => (!_settingsSheetController.open_ ? _settingsSheetController.open() : _settingsSheetController.close(context)),
                child: Text('Settings sheet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
