import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../services/notification_service.dart';
import '../widgets/product_list_tile.dart';
import 'product_detail_screen.dart';
import 'add_product_screen.dart';
import 'use_products_screen.dart';

/// Режимы сортировки списка продуктов.
enum SortMode {
  nameAsc('По названию (А-Я)'),
  nameDesc('По названию (Я-А)'),
  addedNewest('По дате добавления (сначала новые)'),
  addedOldest('По дате добавления (сначала старые)'),
  expirySoon('По сроку годности (сначала истекающие)'),
  expiryLate('По сроку годности (сначала поздние)');

  final String label;
  const SortMode(this.label);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _repo = ProductRepository();
  final _searchController = TextEditingController();

  List<Product> _products = [];
  bool _loading = true;

  /// Текущий режим сортировки. Один на всё приложение — применяется в обеих вкладках.
  SortMode _sortMode = SortMode.addedNewest;

  /// Текущий поисковый запрос (в нижнем регистре, обрезанный).
  String _query = '';

  /// Сколько дней до истечения считается «скоро» и попадает в папку «Истекает скоро».
  static const int _expiringSoonDays = 3;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    if (q == _query) return;
    setState(() => _query = q);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _repo.getAll();
    if (!mounted) return;
    setState(() {
      _products = items;
      _loading = false;
    });
  }

  // ===== Действия =====

  Future<void> _openAddScreen() async {
    final newProduct = await Navigator.of(context).push<Product>(
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (newProduct != null) {
      await _repo.add(newProduct);
      await NotificationService.instance.scheduleExpiryReminder(newProduct);
      await NotificationService.instance.scheduleStaleReminder(newProduct);
      await _load();
    }
  }

  Future<void> _openDetail(Product product) async {
  await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
  );
  await _load();
}

  Future<void> _openUseScreen() async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет продуктов для списания')),
      );
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UseProductsScreen(products: _products),
      ),
    );
    if (changed == true) {
      await _load();
    }
  }

  // ===== Логика фильтрации и сортировки =====

  /// Возвращает список продуктов, отфильтрованный по [query] и отсортированный по [_sortMode].
  List<Product> _applyQueryAndSort(List<Product> source) {
    final list = source.where((p) {
      if (_query.isEmpty) return true;
      return p.name.toLowerCase().contains(_query) ||
          p.category.label.toLowerCase().contains(_query);
    }).toList();

    list.sort(_compare);
    return list;
  }

  int _compare(Product a, Product b) {
    switch (_sortMode) {
      case SortMode.nameAsc:
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case SortMode.nameDesc:
        return b.name.toLowerCase().compareTo(a.name.toLowerCase());
      case SortMode.addedNewest:
        return b.addedAt.compareTo(a.addedAt);
      case SortMode.addedOldest:
        return a.addedAt.compareTo(b.addedAt);
      case SortMode.expirySoon:
        return _compareExpiry(a, b, soonFirst: true);
      case SortMode.expiryLate:
        return _compareExpiry(a, b, soonFirst: false);
    }
  }

  int _compareExpiry(Product a, Product b, {required bool soonFirst}) {
    // Продукты без срока годности — в конце списка.
    final aDate = a.expiryDate;
    final bDate = b.expiryDate;
    if (aDate == null && bDate == null) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return soonFirst ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
  }

  /// Продукты, у которых срок годности истекает через [_expiringSoonDays] дней или уже истёк.
  /// Продукты без срока годности сюда не попадают.
  List<Product> _expiringSoon() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final threshold = today.add(const Duration(days: _expiringSoonDays));

    return _products.where((p) {
      final d = p.expiryDate;
      if (d == null) return false;
      final expiryDay = DateTime(d.year, d.month, d.day);
      // Истекает сегодня, просрочен, либо истекает не позже threshold.
      return !expiryDay.isAfter(threshold);
    }).toList();
  }

  // ===== UI =====

  @override
  Widget build(BuildContext context) {
    final allProducts = _applyQueryAndSort(_products);
    final soonProducts = _applyQueryAndSort(_expiringSoon());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shelfie'),
        actions: [
          IconButton(
            tooltip: 'Использовать продукты',
            icon: const Icon(Icons.playlist_remove),
            onPressed: _openUseScreen,
          ),
          PopupMenuButton<SortMode>(
            tooltip: 'Сортировка',
            icon: const Icon(Icons.sort),
            initialValue: _sortMode,
            onSelected: (m) => setState(() => _sortMode = m),
            itemBuilder: (ctx) => SortMode.values
                .map(
                  (m) => PopupMenuItem<SortMode>(
                    value: m,
                    child: Row(
                      children: [
                        if (m == _sortMode)
                          const Icon(Icons.check, size: 18)
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(m.label)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Поиск по названию или категории',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Очистить',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              FocusScope.of(context).unfocus();
                            },
                          ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Все продукты'),
                  Tab(text: 'Истекает скоро'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(
                  allProducts,
                  emptyMessage: _query.isEmpty
                      ? 'Пока пусто. Добавь продукт!'
                      : 'Ничего не найдено',
                ),
                _buildProductsTab(
                  soonProducts,
                  emptyMessage: _query.isEmpty
                      ? 'Нет продуктов с истекающим сроком'
                      : 'Ничего не найдено',
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddScreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductsTab(
    List<Product> items, {
    required String emptyMessage,
  }) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final p = items[index];
          return ProductListTile(
            product: p,
            onTap: () => _openDetail(p),
          );
        },
      ),
    );
  }
}