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
            child:
                map ??
                (mapBuilder != null
                    ? Builder(builder: mapBuilder!)
                    : Container(
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
                      )),
          ),
        ],
      ),
    );
  }
}
