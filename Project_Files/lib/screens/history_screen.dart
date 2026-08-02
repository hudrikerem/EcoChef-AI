import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/product_store.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<ProductStore>().history;

    return Scaffold(
      appBar: AppBar(title: const Text('Ürün Geçmişi')),
      body: history.isEmpty
          ? const Center(
              child: Text('Henüz tüketilen veya israf edilen ürün yok'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                final rescued = entry.wasRescued;
                final color =
                    rescued ? AppTheme.statusFresh : AppTheme.statusExpired;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color,
                      child: Icon(
                        rescued ? Icons.check_circle : Icons.delete,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(entry.name),
                    subtitle: Text(
                      '${entry.quantity} ${entry.unit} • ${entry.category}\n'
                      'SKT: ${_formatDate(entry.expiryDate)} • Karar: ${_formatDate(entry.decidedAt)}',
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      rescued ? 'Kurtarıldı' : 'İsraf',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}