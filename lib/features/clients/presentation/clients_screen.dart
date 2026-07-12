import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/app_controller.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    return ListView(
      key: const PageStorageKey('clients-scroll'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Perfil del cliente',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          state.selectedClient?.nombre ??
              'Seleccione un cliente para comenzar.',
        ),
      ],
    );
  }
}
