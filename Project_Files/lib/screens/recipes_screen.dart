import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/product_store.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final GeminiService _geminiService = GeminiService();
  String? _recipe;
  bool _isLoading = false;
  bool _isFetchingInitial = true;

  @override
  void initState() {
    super.initState();
    _checkTodaysRecipe();
  }

  Future<void> _checkTodaysRecipe() async {
    final savedRecipe = await _geminiService.getTodaysRecipe();
    setState(() {
      _recipe = savedRecipe;
      _isFetchingInitial = false;
    });
  }

  Future<void> _generateNewRecipe() async {
    final store = context.read<ProductStore>();
    
    if (store.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce stoklarına ürün eklemelisin.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newRecipe = await _geminiService.generateRecipe(store.products);
      setState(() {
        _recipe = newRecipe;
      });
      
      await store.recordRecipeMade();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Günün Tarifi'),
      ),
      body: _isFetchingInitial
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_recipe == null) ...[
                    const Spacer(),
                    const Icon(Icons.restaurant_menu, size: 80, color: AppTheme.primaryGreen),
                    const SizedBox(height: 24),
                    const Text(
                      'Bugün için henüz bir tarif oluşturmadın.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Yapay zeka, stoklarındaki SKT\'si yaklaşan ürünleri analiz ederek sana harika bir tarif sunacak.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _generateNewRecipe,
                      icon: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.auto_awesome),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Günün Tarifini Oluştur ✨', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const Spacer(),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bugünkü tarif hakkını kullandın. Yeni tarif için yarını bekle!',
                              style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Card(
                        elevation: 2,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            _recipe!,
                            style: const TextStyle(fontSize: 15, height: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}