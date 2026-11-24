import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../theme/app_theme.dart';

class ProductListTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductListTile({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final qtyColor = QuantityColor.of(product);
    final expiryInfo = _expiryInfo(context);

    return Card(
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
  }

  /// Возвращает текст и цвет бейджа о сроке годности, либо null, если срок не указан.
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