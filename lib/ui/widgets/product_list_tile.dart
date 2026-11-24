import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../theme/app_theme.dart';

class ProductListTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductListTile({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final qtyColor = QuantityColor.of(product);
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
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: qtyColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_formatQty(product.quantity)} ${product.unit.label}',
                  style: TextStyle(color: qtyColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatQty(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}