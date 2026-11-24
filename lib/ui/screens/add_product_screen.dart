import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../data/product_suggestions.dart';

class AddProductScreen extends StatefulWidget {
  /// Если передан — экран работает в режиме редактирования.
  /// При сохранении возвращает обновлённый [Product] с тем же id.
  final Product? initialProduct;

  const AddProductScreen({super.key, this.initialProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  int _step = 0;

  ProductCategory? _category;

  late final TextEditingController _nameController;
  late final TextEditingController _qtyController;
  late QuantityUnit _unit;
  DateTime? _expiryDate;
  late DateTime _addedAt;

  final _nameFocusNode = FocusNode();

  ProductSuggestion? _matchedSuggestion;

  bool get _isEditing => widget.initialProduct != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialProduct;

    if (initial != null) {
      // Режим редактирования: сразу на шаг деталей, всё предзаполнено.
      _step = 1;
      _category = initial.category;
      _nameController = TextEditingController(text: initial.name);
      _qtyController = TextEditingController(
        text: _formatQty(initial.quantity),
      );
      _unit = initial.unit;
      _expiryDate = initial.expiryDate;
      _addedAt = initial.addedAt;
    } else {
      _nameController = TextEditingController();
      _qtyController = TextEditingController(text: '1');
      _unit = QuantityUnit.pieces;
      _addedAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  String _formatQty(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  void _next() => setState(() => _step++);

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      // В режиме редактирования назад на шаг 0 нельзя — сохраняем категорию как есть.
      if (_isEditing) {
        Navigator.of(context).pop();
      } else {
        setState(() => _step--);
      }
    }
  }

  bool get _canGoNext {
    switch (_step) {
      case 0:
        return _category != null;
      case 1:
        return _nameController.text.trim().isNotEmpty &&
            (double.tryParse(_qtyController.text.replaceAll(',', '.')) ?? 0) >
                0;
      default:
        return false;
    }
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _pickAddedAt() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _addedAt,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now,
    );
    if (picked != null) setState(() => _addedAt = picked);
  }

  ProductSuggestion? _findSuggestionByName(String raw) {
    final needle = raw.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final s in kProductSuggestions) {
      if (s.name.toLowerCase() == needle) return s;
    }
    return null;
  }

  void _onNameChanged(String value) {
    final match = _findSuggestionByName(value);
    if (match != null) {
      setState(() {
        _matchedSuggestion = match;
        _unit = match.defaultUnit;
      });
    } else {
      if (_matchedSuggestion != null) {
        setState(() => _matchedSuggestion = null);
      }
    }
  }

  void _submit() {
    final baseId =
        widget.initialProduct?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    final product = Product(
      id: baseId,
      name: _nameController.text.trim(),
      quantity: double.parse(_qtyController.text.replaceAll(',', '.')),
      unit: _unit,
      category: _category!,
      addedAt: _addedAt,
      expiryDate: _expiryDate,
    );
    Navigator.of(context).pop(product);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing
        ? 'Редактирование'
        : (_step == 0 ? 'Категория' : 'Детали');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
      ),
      body: Column(
        children: [
          if (!_isEditing) _StepIndicator(step: _step),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildStep(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: _step == 0
                    ? FilledButton(
                        onPressed: _canGoNext ? _next : null,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Далее'),
                        ),
                      )
                    : FilledButton(
                        onPressed: _canGoNext ? _submit : null,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Сохранить'),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _CategoryStep(
          key: const ValueKey(0),
          selected: _category,
          onSelect: (c) => setState(() => _category = c),
        );
      case 1:
        return _DetailsStep(
          key: const ValueKey(1),
          category: _category!,
          nameController: _nameController,
          nameFocusNode: _nameFocusNode,
          qtyController: _qtyController,
          unit: _unit,
          onUnitChanged: (u) => setState(() => _unit = u),
          expiryDate: _expiryDate,
          onPickExpiry: _pickExpiryDate,
          onClearExpiry: () => setState(() => _expiryDate = null),
          addedAt: _addedAt,
          onPickAddedAt: _pickAddedAt,
          onClearAddedAt: () => setState(() => _addedAt = DateTime.now()),
          onNameChanged: _onNameChanged,
          onQtyChanged: () => setState(() {}),
          matchedSuggestion: _matchedSuggestion,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ==== Шаг 0: выбор категории ====

class _CategoryStep extends StatelessWidget {
  final ProductCategory? selected;
  final ValueChanged<ProductCategory> onSelect;

  const _CategoryStep({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Выберите категорию продукта'),
        const SizedBox(height: 12),
        ...ProductCategory.values.map((c) {
          final isSelected = c == selected;
          return Card(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: ListTile(
              title: Text(c.label),
              trailing: isSelected ? const Icon(Icons.check) : null,
              onTap: () => onSelect(c),
            ),
          );
        }),
      ],
    );
  }
}

// ==== Шаг 1: детали ====

class _DetailsStep extends StatelessWidget {
  final ProductCategory category;
  final TextEditingController nameController;
  final FocusNode nameFocusNode;
  final TextEditingController qtyController;
  final QuantityUnit unit;
  final ValueChanged<QuantityUnit> onUnitChanged;
  final DateTime? expiryDate;
  final VoidCallback onPickExpiry;
  final VoidCallback onClearExpiry;
  final DateTime addedAt;
  final VoidCallback onPickAddedAt;
  final VoidCallback onClearAddedAt;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onQtyChanged;
  final ProductSuggestion? matchedSuggestion;

  const _DetailsStep({
    super.key,
    required this.category,
    required this.nameController,
    required this.nameFocusNode,
    required this.qtyController,
    required this.unit,
    required this.onUnitChanged,
    required this.expiryDate,
    required this.onPickExpiry,
    required this.onClearExpiry,
    required this.addedAt,
    required this.onPickAddedAt,
    required this.onClearAddedAt,
    required this.onNameChanged,
    required this.onQtyChanged,
    required this.matchedSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    final showCategoryMismatch = matchedSuggestion != null &&
        matchedSuggestion!.category != category;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(category.label),
        const SizedBox(height: 16),
        RawAutocomplete<ProductSuggestion>(
          textEditingController: nameController,
          focusNode: nameFocusNode,
          optionsBuilder: (TextEditingValue textEditingValue) {
            final q = textEditingValue.text.trim().toLowerCase();
            if (q.isEmpty) return const Iterable<ProductSuggestion>.empty();
            return kProductSuggestions.where(
              (s) => s.name.toLowerCase().contains(q),
            );
          },
          displayStringForOption: (s) => s.name,
          onSelected: (s) {
            nameController.text = s.name;
            nameController.selection = TextSelection.fromPosition(
              TextPosition(offset: s.name.length),
            );
            onNameChanged(s.name);
          },
          fieldViewBuilder:
              (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onNameChanged,
              onSubmitted: (_) => onFieldSubmitted(),
              decoration: const InputDecoration(
                labelText: 'Название продукта',
                border: OutlineInputBorder(),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        title: Text(option.name),
                        subtitle: Text(
                          '${option.category.label} • ${option.defaultUnit.label}',
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        if (showCategoryMismatch)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'В справочнике «${matchedSuggestion!.name}» относится '
                    'к категории «${matchedSuggestion!.category.label}». '
                    'Оставить выбранную?',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: qtyController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => onQtyChanged(),
                decoration: const InputDecoration(
                  labelText: 'Количество',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<QuantityUnit>(
                value: unit,
                decoration: const InputDecoration(
                  labelText: 'Ед. изм.',
                  border: OutlineInputBorder(),
                ),
                items: QuantityUnit.values
                    .map((u) =>
                        DropdownMenuItem(value: u, child: Text(u.label)))
                    .toList(),
                onChanged: (v) => onUnitChanged(v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Дата добавления'),
          subtitle: Text('${addedAt.day}.${addedAt.month}.${addedAt.year}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isSameDay(addedAt, DateTime.now()))
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClearAddedAt,
                ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: onPickAddedAt,
              ),
            ],
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Срок годности (опционально)'),
          subtitle: Text(
            expiryDate == null
                ? 'Не указан'
                : '${expiryDate!.day}.${expiryDate!.month}.${expiryDate!.year}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (expiryDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClearExpiry,
                ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: onPickExpiry,
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ==== Индикатор шагов ====

class _StepIndicator extends StatelessWidget {
  final int step;

  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(2, (i) {
          final active = i <= step;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}