import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../state/product_store.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  String _unit = 'adet';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 3));
  String? _selectedCategory;
  String? _categoryError;
  bool _saving = false;

  final List<String> _units = ['adet', 'kg', 'gr', 'lt', 'ml'];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    if (_selectedCategory == null) {
      setState(() => _categoryError = 'Lütfen bir kategori seç');
    }
    if (!formOk || _selectedCategory == null) return;

    final store = context.read<ProductStore>();
    final name = _nameController.text.trim();

    if (store.isNameTaken(name)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Aynı isimde ürün var'),
          content: Text(
              '"$name" isminde bir ürün zaten stokta. Yine de eklemek istiyor musun?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Yine de Ekle'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (!mounted) return;
    setState(() => _saving = true);

    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      category: _selectedCategory!,
      quantity: double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 1,
      unit: _unit,
      expiryDate: _expiryDate,
    );

    try {
      await store.ensureCategoryColor(product.category);
      await store.addProduct(product);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün eklenirken bir sorun oluştu, tekrar dene.')),
      );
    }
  }

  List<String> _categoriesFrom(ProductStore store) => store.knownCategories;

  Future<void> _createNewCategory(ProductStore store) async {
    final nameController = TextEditingController();
    Color? chosenColor;

    final result = await showDialog<_NewCategoryResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Yeni Kategori'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Kategori adı'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Renk (seçmezsen otomatik atanır)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final color in ProductStore.categoryColorPalette)
                          GestureDetector(
                            onTap: () => setDialogState(() {
                              chosenColor = chosenColor?.toARGB32() == color.toARGB32()
                                  ? null
                                  : color;
                            }),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: color,
                              child: chosenColor?.toARGB32() == color.toARGB32()
                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.of(dialogContext)
                        .pop(_NewCategoryResult(name, chosenColor));
                  },
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;
    final name = result.name;

    if (_categoriesFrom(store).any((c) => c.toLowerCase() == name.toLowerCase())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu isimde bir kategori zaten var.')),
      );
      return;
    }

    if (result.color != null) {
      final conflictWith = store.categoryUsingColor(result.color!);
      if (conflictWith != null) {
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Renk zaten kullanılıyor'),
            content: Text(
                'Bu renk zaten "$conflictWith" kategorisinde kullanılıyor. '
                'Yine de kullanmak istediğinize emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Yine de Kullan'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }
      await store.setCategoryColor(name, result.color!);
    } else {
      await store.ensureCategoryColor(name);
    }

    if (!mounted) return;
    setState(() {
      _selectedCategory = name;
      _categoryError = null;
    });
  }

  Future<void> _editCategoryColor(ProductStore store, String category) async {
    Color? chosenColor = store.colorForCategory(category);

    final newColor = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('"$category" rengini değiştir'),
              content: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final color in ProductStore.categoryColorPalette)
                    GestureDetector(
                      onTap: () => setDialogState(() => chosenColor = color),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: color,
                        child: chosenColor?.toARGB32() == color.toARGB32()
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(chosenColor),
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );

    if (newColor == null) return;

    final conflictWith = store.categoryUsingColor(newColor);
    if (conflictWith != null && conflictWith != category) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Renk zaten kullanılıyor'),
          content: Text(
              'Bu renk zaten "$conflictWith" kategorisinde kullanılıyor. '
              'Yine de değiştirmek istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Yine de Değiştir'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await store.setCategoryColor(category, newColor);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProductStore>();
    final categories = _categoriesFrom(store);

    return Scaffold(
      appBar: AppBar(title: const Text('Ürün Ekle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Ürün Adı'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Ürün adı gerekli' : null,
            ),
            const SizedBox(height: 20),
            const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              'Bir kategoriye uzun basarak rengini değiştirebilirsin.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in categories)
                  GestureDetector(
                    onLongPress: () => _editCategoryColor(store, category),
                    child: ChoiceChip(
                      label: Text(category),
                      avatar: CircleAvatar(
                        backgroundColor: store.colorForCategory(category),
                      ),
                      selected: _selectedCategory == category,
                      onSelected: (_) => setState(() {
                        _selectedCategory = category;
                        _categoryError = null;
                      }),
                    ),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Yeni Kategori'),
                  onPressed: () => _createNewCategory(store),
                ),
              ],
            ),
            if (_categoryError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _categoryError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Miktar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: const InputDecoration(labelText: 'Birim'),
                    items: _units
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _unit = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Son Kullanma Tarihi'),
              subtitle: Text(
                  '${_expiryDate.day.toString().padLeft(2, '0')}.${_expiryDate.month.toString().padLeft(2, '0')}.${_expiryDate.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewCategoryResult {
  final String name;
  final Color? color;

  const _NewCategoryResult(this.name, this.color);
}
