import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../services/notification_service.dart';
import '../widgets/product_list_tile.dart';
import 'product_detail_screen.dart';
import 'add_product_screen.dart';
import 'use_products_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = ProductRepository();
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _openAddScreen() async {
    final newProduct = await Navigator.of(context).push<Product>(
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (newProduct != null) {
      await _repo.add(newProduct);
      await NotificationService.instance.scheduleExpiryReminder(newProduct);
      await NotificationService.instance.scheduleStaleReminder(newProduct);
      await _load();  // обязательно ждём завершения
    }
  }

  Future<void> _openDetail(Product product) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
    if (changed == true) {
      await _load();
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shelfie'),
        actions: [
          IconButton(
            tooltip: 'Использовать продукты',
            icon: const Icon(Icons.playlist_remove),
            onPressed: _openUseScreen,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('Пока пусто. Добавь продукт!'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final p = _products[index];
                      return ProductListTile(
                        product: p,
                        onTap: () => _openDetail(p),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddScreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}