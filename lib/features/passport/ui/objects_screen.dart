import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/passport_controller.dart';

class ObjectsScreen extends ConsumerWidget {
  const ObjectsScreen({super.key});

  Future<void> _showAddObjectDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Electrónica');
    final brandCtrl = TextEditingController();
    final serialCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo objeto'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del objeto',
                    hintText: 'Ej. Bicicleta gravel o Portátil',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: catCtrl,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: brandCtrl,
                  decoration: const InputDecoration(labelText: 'Marca y modelo'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: serialCtrl,
                  decoration: const InputDecoration(labelText: 'N.º de serie'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notas'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Crear pasaporte'),
          ),
        ],
      ),
    );

    if (saved == true && nameCtrl.text.trim().isNotEmpty) {
      final created =
          await ref.read(passportControllerProvider.notifier).addObject(
                name: nameCtrl.text,
                category: catCtrl.text,
                brandModel: brandCtrl.text,
                serialNumber: serialCtrl.text,
                notes: notesCtrl.text,
              );
      if (context.mounted) {
        context.push('/objects/${created.id}');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(passportControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('RepairPassport')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddObjectDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Objeto'),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (data) {
          final totalRepairs = data.repairs.length;
          final totalCost =
              data.repairs.fold<double>(0, (sum, r) => sum + r.costEur);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'La historia de tus objetos, no otra lista de compras',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.14),
                              theme.colorScheme.primary.withValues(alpha: 0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.22),
                          ),
                        ),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 12,
                          children: [
                            _Metric(
                                label: 'Objetos',
                                value: '${data.objects.length}'),
                            _Metric(
                                label: 'Reparaciones', value: '$totalRepairs'),
                            _Metric(
                              label: 'Invertido',
                              value: '${totalCost.toStringAsFixed(0)} €',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (data.objects.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.build_circle_outlined,
                            size: 52,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sin objetos registrados todavía',
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Crea el pasaporte de un dispositivo, electrodoméstico o bici para conservar sus reparaciones, piezas y QR exportable.',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 92),
                  sliver: SliverList.separated(
                    itemCount: data.objects.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final obj = data.objects[index];
                      final objRepairs = data.repairs
                          .where((r) => r.objectId == obj.id)
                          .toList();
                      return TweenAnimationBuilder<double>(
                        duration: AppMotion.duration(
                          context,
                          Duration(milliseconds: 180 + (index.clamp(0, 6) * 35)),
                        ),
                        curve: AppMotion.curve(context),
                        tween: Tween(begin: 0, end: 1),
                        builder: (context, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1 - t)),
                            child: child,
                          ),
                        ),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              child: Icon(
                                Icons.handyman_outlined,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              obj.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${obj.category}${obj.brandModel.isNotEmpty ? ' · ${obj.brandModel}' : ''} · ${objRepairs.length} arreglos',
                            ),
                            trailing: IconButton(
                              tooltip: 'Eliminar objeto',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => ref
                                  .read(passportControllerProvider.notifier)
                                  .deleteObject(obj.id),
                            ),
                            onTap: () => context.push('/objects/${obj.id}'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

