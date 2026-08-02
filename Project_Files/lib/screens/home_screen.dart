import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../state/product_store.dart';
import '../theme/app_theme.dart';
import 'product_detail_screen.dart';
import 'add_product_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  List<String> _orderedCategories(
    ProductStore store,
    Map<String, List<Product>> grouped,
  ) {
    final present = grouped.keys.toSet();
    final saved =
        store.categoryOrder.where(present.contains).toList();
    final remaining = present.difference(saved.toSet()).toList()
      ..sort((a, b) => grouped[a]!.first.daysUntilExpiry
          .compareTo(grouped[b]!.first.daysUntilExpiry));
    return [...saved, ...remaining];
  }

  Future<void> _copyStockToClipboard(BuildContext context, ProductStore store) async {
    if (store.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kopyalanacak ürün bulunamadı.')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('📋 GÜNCEL STOK DURUMU VE SKT LİSTESİ\n');

    final Map<String, List<Product>> grouped = {};
    for (final product in store.products) {
      grouped.putIfAbsent(product.category, () => []).add(product);
    }
    
    final categories = _orderedCategories(store, grouped);

    for (final category in categories) {
      buffer.writeln('📦 $category');
      final products = grouped[category]!;
      products.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
      
      for (final p in products) {
        final dateStr = '${p.expiryDate.day.toString().padLeft(2, '0')}.${p.expiryDate.month.toString().padLeft(2, '0')}.${p.expiryDate.year}';
        
        final qtyStr = p.quantity == p.quantity.roundToDouble() 
            ? p.quantity.toInt().toString() 
            : p.quantity.toString();
        
        buffer.writeln('  • ${p.name}: $qtyStr ${p.unit} (SKT: $dateStr | ${p.statusLabel})');
      }
      buffer.writeln('');
    }

    // Panoya yaz
    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm stok listesi panoya kopyalandı! 📋')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProductStore>();

    final Map<String, List<Product>> grouped = {};
    for (final product in store.products) {
      grouped.putIfAbsent(product.category, () => []).add(product);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    }

    final categories = _orderedCategories(store, grouped);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stoklarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Tüm Stok ve SKT Listesini Kopyala',
            onPressed: () => _copyStockToClipboard(context, store),
          ),
        ],
      ),
      body: store.products.isEmpty
          ? const Center(child: Text('Henüz ürün eklenmedi'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: categories.length,
              onReorderItem: (oldIndex, newIndex) {
                final newOrder = [...categories];
                if (newIndex > oldIndex) newIndex -= 1;
                final moved = newOrder.removeAt(oldIndex);
                newOrder.insert(newIndex, moved);
                store.reorderCategories(newOrder);
              },
              itemBuilder: (context, index) {
                final category = categories[index];
                final products = grouped[category]!;
                return _CategorySection(
                  key: ValueKey(category),
                  category: category,
                  products: products,
                  categoryColor: store.colorForCategory(category),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<Product> products;
  final Color categoryColor;

  const _CategorySection({
    super.key,
    required this.category,
    required this.products,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final expiredCount =
        products.where((p) => p.status == ExpiryStatus.expired).length;
    final soonCount =
        products.where((p) => p.status == ExpiryStatus.soon).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: CircleAvatar(
            backgroundColor: categoryColor,
            child: Text(
              category.isNotEmpty ? category.substring(0, 1) : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(category,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Row(
            children: [
              Text('${products.length} ürün'),
              if (expiredCount > 0) ...[
                const SizedBox(width: 8),
                _CountBadge(
                  count: expiredCount,
                  color: AppTheme.statusExpired,
                  label: 'geçti',
                ),
              ],
              if (soonCount > 0) ...[
                const SizedBox(width: 8),
                _CountBadge(
                  count: soonCount,
                  color: AppTheme.statusSoon,
                  label: 'yaklaşıyor',
                ),
              ],
            ],
          ),
          children: products
              .map((product) => _ProductTile(product: product))
              .toList(),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  final String label;

  const _CountBadge({
    required this.count,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;

  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      contentPadding: const EdgeInsets.only(left: 24, right: 8),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: product.statusColor.withValues(alpha: 0.15),
        child: Icon(Icons.circle, size: 10, color: product.statusColor),
      ),
      title: Text(product.name),
      subtitle: Text('${product.quantity} ${product.unit}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            product.statusLabel,
            style: TextStyle(
              color: product.statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        ],
      ),
    );
  }
}