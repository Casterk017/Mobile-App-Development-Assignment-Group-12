import 'package:flutter/material.dart';

import '../../../app/locale_controller.dart';

/// The dashboard owns the frame; the map teammate owns everything inside it.
/// Builders receive finite layout constraints. No location logic lives here.
class CampusMapFrame extends StatelessWidget {
  const CampusMapFrame({super.key, this.map, this.mapBuilder})
    : assert(map == null || mapBuilder == null);
  final Widget? map;
  final WidgetBuilder? mapBuilder;

  @override
  Widget build(BuildContext context) {
    final s = CampusStrings.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.map_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.t('map'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Call the static entry method from your map feature
                // We use dynamic navigation so we don't need a hard import here.
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) {
                      // Retrieve the full Map screen if it was injected
                      if (map != null) return map!;
                      if (mapBuilder != null) return Builder(builder: mapBuilder!);
                      return const Scaffold(body: Center(child: Text("Map Feature Not Found")));
                    }
                  ),
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // MAP PREVIEW (Read-only, non-interactive visual representation)
                  if (map != null || mapBuilder != null)
                    AbsorbPointer(
                      child: map ?? Builder(builder: mapBuilder!),
                    ),
                  
                  // THE PLACEHOLDER OVERLAY (If map isn't provided or we want the UI overlay)
                  if (map == null && mapBuilder == null)
                    Container(
                        key: const ValueKey('campus-map-placeholder'),
                        color: Theme.of(context).colorScheme.primaryContainer,
                        alignment: Alignment.center,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surface,
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: Icon(
                                    Icons.map_outlined,
                                    size: 54,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  s.t('mapPlaceholder'),
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  s.t('mapDescription'),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
