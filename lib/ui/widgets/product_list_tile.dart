import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../theme/app_theme.dart';
import 'write_off_dialog.dart';

class ProductListTile extends StatelessWidget { // Возвращаем StatelessWidget!
  final Product product;
  final VoidCallback onTap;
  final Future<void> Function(double amount)? onWriteOff;
  final Future<void> Function()? onDelete;

  const ProductListTile({
    super.key,
    required this.product,
    required this.onTap,
    this.onWriteOff,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final qtyColor = QuantityColor.of(product);
    final expiryInfo = _expiryInfo(context);

    final tile = Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image_outlined, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (expiryInfo != null) ...[
                          const SizedBox(width: 8),
                          _ExpiryBadge(info: expiryInfo),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: qtyColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_formatQty(product.quantity)} ${product.unit.label}',
                  style:
                      TextStyle(color: qtyColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onWriteOff == null && onDelete == null) {
      return tile;
    }

    return Dismissible(
      key: ValueKey('product-dismissible-${product.id}'),
      background: _buildBackground(
        context,
        alignment: Alignment.centerLeft,
        color: Colors.orange.shade600,
        icon: Icons.remove_circle_outline,
        label: 'Списать',
      ),
      secondaryBackground: _buildBackground(
        context,
        alignment: Alignment.centerRight,
        color: Theme.of(context).colorScheme.error,
        icon: Icons.delete_outline,
        label: 'Удалить',
      ),
      direction: (onWriteOff != null && onDelete != null)
          ? DismissDirection.horizontal
          : (onWriteOff != null
              ? DismissDirection.startToEnd
              : DismissDirection.endToStart),
      
      // ХИТРОСТЬ: Мы перехватываем свайп, делаем всё сами и ВСЕГДА возвращаем false.
      // Это заставляет Dismissible вернуть карточку на место, а мы удаляем её
      // из списка через setState. Никаких ошибок дерева.
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (onWriteOff == null) return false;
          final amount = await showWriteOffDialog(context, product);
          if (amount != null) {
            onWriteOff!(amount); // Вызываем обновление в родителе
          }
        } else {
          if (onDelete == null) return false;
          final confirmed = await _confirmDelete(context, product);
          if (confirmed) {
            onDelete!(); // Вызываем обновление в родителе
          }
        }
        return false; // ВСЕГДА false! Dismissible не будет удалять сам себя.
      },
      child: tile,
    );
  }

  Widget _buildBackground(
    BuildContext context, {
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Product product) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить продукт?'),
        content: Text(
          '«${product.name}» будет удалён без возможности восстановления.',
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
    return result == true;
  }

  _ExpiryInfo? _expiryInfo(BuildContext context) {
    final expiry = product.expiryDate;
    if (expiry == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    final diffDays = expiryDay.difference(today).inDays;

    final dateText =
        '${expiry.day.toString().padLeft(2, '0')}.${expiry.month.toString().padLeft(2, '0')}.${expiry.year}';

    if (diffDays < 0) {
      return _ExpiryInfo(
        text: 'Просрочен $dateText',
        color: const Color(0xFFC62828),
      );
    }
    if (diffDays == 0) {
      return _ExpiryInfo(
        text: 'Истекает сегодня',
        color: const Color(0xFFC62828),
      );
    }
    if (diffDays <= 3) {
      return _ExpiryInfo(
        text: 'До $dateText',
        color: const Color(0xFFEF6C00),
      );
    }
    return _ExpiryInfo(
      text: 'До $dateText',
      color: Colors.grey.shade600,
    );
  }

  String _formatQty(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class _ExpiryInfo {
  final String text;
  final Color color;
  const _ExpiryInfo({required this.text, required this.color});
}

class _ExpiryBadge extends StatelessWidget {
  final _ExpiryInfo info;

  const _ExpiryBadge({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        info.text,
        style: TextStyle(
          color: info.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}