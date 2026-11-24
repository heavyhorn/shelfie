import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../services/notification_service.dart';
import '../widgets/write_off_dialog.dart';

class UseProductsScreen extends StatefulWidget {
  final List<Product> products;

  const UseProductsScreen({super.key, required this.products});

  @override
  State<UseProductsScreen> createState() => _UseProductsScreenState();
}

class _UseProductsScreenState extends State<UseProductsScreen> {
  final _repo = ProductRepository();
  final Set<String> _selectedIds = {};
  bool _processing = false;

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _writeOff() async {
    if (_selectedIds.isEmpty || _processing) return;

    final selected = widget.products
        .where((p) => _selectedIds.contains(p.id))
        .toList();

    final Map<String, double> amounts = {};
    for (final p in selected) {
      final amount = await showWriteOffDialog(context, p);
      if (amount == null) return;
      amounts[p.id] = amount;
    }

    setState(() => _processing = true);
    try {
      for (final p in selected) {
        final deleted = await _repo.writeOff(p, amounts[p.id]!);
        if (deleted) {
          await NotificationService.instance.cancelForProduct(p.id);
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIds.isEmpty
              ? 'Выберите продукты'
              : 'Выбрано: ${_selectedIds.length}',
        ),
      ),
      body: widget.products.isEmpty
          ? const Center(child: Text('Нет продуктов для списания'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: widget.products.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = widget.products[i];
                final selected = _selectedIds.contains(p.id);
                return CheckboxListTile(
                  value: selected,
                  onChanged: _processing ? null : (_) => _toggle(p.id),
                  title: Text(p.name),
                  subtitle: Text(
                    '${_formatQty(p.quantity)} ${p.unit.label} • ${p.category.label}',
                  ),
                  secondary: const Icon(Icons.inventory_2_outlined),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _selectedIds.isEmpty || _processing ? null : _writeOff,
            icon: _processing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.remove_circle_outline),
            label: Text(
              _selectedIds.isEmpty
                  ? 'Выберите продукты'
                  : 'Списать (${_selectedIds.length})',
            ),
          ),
        ),
      ),
    );
  }

  String _formatQty(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}