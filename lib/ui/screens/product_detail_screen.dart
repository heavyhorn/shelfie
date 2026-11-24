import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../services/notification_service.dart';
import '../widgets/write_off_dialog.dart';
import 'add_product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _repo = ProductRepository();
  bool _processing = false;

  late Product _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Future<void> _useProduct() async {
    final amount = await showWriteOffDialog(context, _product);
    if (amount == null) return;

    setState(() => _processing = true);
    try {
      final deleted = await _repo.writeOff(_product, amount);
      if (deleted) {
        await NotificationService.instance.cancelForProduct(_product.id);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _editProduct() async {
    final edited = await Navigator.of(context).push<Product>(
      MaterialPageRoute(
        builder: (_) => AddProductScreen(initialProduct: _product),
      ),
    );
    if (edited == null) return;
    if (!mounted) return;

    await _repo.update(edited);
    // Перепланируем уведомления: старые отменяем, новые ставим.
    await NotificationService.instance.cancelForProduct(edited.id);
    await NotificationService.instance.scheduleExpiryReminder(edited);
    await NotificationService.instance.scheduleStaleReminder(edited);

    setState(() => _product = edited);
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить продукт?'),
        content: Text(
          '«${_product.name}» будет удалён без возможности восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _processing = true);
    try {
      await _repo.delete(_product.id);
      await NotificationService.instance.cancelForProduct(_product.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            tooltip: 'Редактировать',
            icon: const Icon(Icons.edit),
            onPressed: _processing ? null : _editProduct,
          ),
          IconButton(
            tooltip: 'Удалить',
            icon: const Icon(Icons.delete_outline),
            onPressed: _processing ? null : _deleteProduct,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.image_outlined,
                size: 48,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _row(context, 'Название', product.name),
          _row(context, 'Категория', product.category.label),
          _row(
            context,
            'Количество',
            '${_fmt(product.quantity)} ${product.unit.label}',
          ),
          _row(context, 'Дата добавления', _formatDate(product.addedAt)),
          if (product.expiryDate != null)
            _row(context, 'Срок годности', _formatDate(product.expiryDate!)),
          const SizedBox(height: 32),
          FilledButton.tonalIcon(
            onPressed: _processing ? null : _useProduct,
            icon: _processing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.remove_circle_outline),
            label: const Text('Использовать продукт'),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}