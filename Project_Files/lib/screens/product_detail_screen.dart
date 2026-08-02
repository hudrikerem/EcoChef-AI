import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../state/product_store.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _daysText(int days) {
    if (days < 0) {
      return 'SKT ${days.abs()} gün önce geçti';
    } else if (days == 0) {
      return 'SKT\'si Bugün Doluyor';
    } else {
      return 'SKT\'ye $days gün kaldı';
    }
  }

  Future<void> _editQuantity(
      BuildContext context, ProductStore store, Product current) async {
    final controller =
        TextEditingController(text: _trimTrailingZero(current.quantity));

    final newQuantity = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Miktarı düzenle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(suffixText: current.unit),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.replaceAll(',', '.'));
              Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (newQuantity == null || newQuantity <= 0) return;
    await store.updateProduct(current.id, quantity: newQuantity);
  }

  Future<void> _editExpiry(
      BuildContext context, ProductStore store, Product current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current.expiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    await store.updateProduct(current.id, expiryDate: picked);
  }

  Future<void> _decide(
    BuildContext context,
    ProductStore store,
    Product current, {
    required bool wasted,
  }) async {
    try {
      if (wasted) {
        await store.markWasted(current.id);
      } else {
        await store.markConsumed(current.id);
      }
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Geçmişe kaydedilemedi: $e')),
      );
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, ProductStore store, Product current) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ürünü sil'),
        content: Text(
            '"${current.name}" ürününü listeden silmek istediğine emin misin? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await store.deleteProduct(current.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  static String _trimTrailingZero(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProductStore>();
    final current = store.products.firstWhere(
      (p) => p.id == product.id,
      orElse: () => product,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(current.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Ürünü sil',
            onPressed: () => _confirmDelete(context, store, current),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: current.statusColor,
                  child: Text(
                    current.name.substring(0, 1),
                    style: const TextStyle(color: Colors.white, fontSize: 22),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(current.name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 5,
                            backgroundColor: store.colorForCategory(current.category),
                          ),
                          const SizedBox(width: 6),
                          Text(current.category,
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _InfoRow(
              label: 'Miktar',
              value: '${_trimTrailingZero(current.quantity)} ${current.unit}',
              onEdit: () => _editQuantity(context, store, current),
            ),
            _InfoRow(
              label: 'Son Kullanma Tarihi',
              value: _formatDate(current.expiryDate),
              onEdit: () => _editExpiry(context, store, current),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: current.statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: current.statusColor),
              ),
              child: Text(
                _daysText(current.daysUntilExpiry),
                style: TextStyle(
                  color: current.statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _decide(
                      context,
                      store,
                      current,
                      wasted: false,
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Tükettim'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _decide(
                      context,
                      store,
                      current,
                      wasted: true,
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Attım (İsraf)'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onEdit;

  const _InfoRow({required this.label, required this.value, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (onEdit != null)
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.edit, size: 16, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}