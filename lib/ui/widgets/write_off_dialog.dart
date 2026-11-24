import 'package:flutter/material.dart';
import '../../data/models/product.dart';

/// Показывает диалог «сколько списать» для одного продукта.
/// Возвращает введённое количество (может быть больше остатка — трактуется как «списать всё»),
/// либо null, если пользователь отменил.
Future<double?> showWriteOffDialog(
  BuildContext context,
  Product product, {
  double? initialValue,
}) {
  final controller = TextEditingController(
    text: initialValue?.toString() ?? product.quantity.toString(),
  );
  final formKey = GlobalKey<FormState>();

  return showDialog<double>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text('Списать «${product.name}»'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'В наличии: ${_fmt(product.quantity)} ${product.unit.label}',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Сколько списать',
                  suffixText: product.unit.label,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final parsed =
                      double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) {
                    return 'Введите положительное число';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Если списать всё или больше — продукт будет удалён.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final value = double.parse(
                  controller.text.replaceAll(',', '.'),
                );
                Navigator.pop(ctx, value);
              }
            },
            child: const Text('Списать'),
          ),
        ],
      );
    },
  );
}

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();