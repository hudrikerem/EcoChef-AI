import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/avatar.dart';
import '../state/product_store.dart';
import '../theme/app_theme.dart';
import 'avatar_crop_screen.dart';

class AvatarPickerSheet extends StatelessWidget {
  const AvatarPickerSheet({super.key});

  Future<void> _pickFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!context.mounted) return;

    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => AvatarCropScreen(imageBytes: bytes)),
    );
    if (result == null || !context.mounted) return;

    try {
      await context.read<ProductStore>().setAvatarImage(result);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('EcoChef avatar kaydetme hatası: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar kaydedilirken bir sorun oluştu, tekrar dene.')),
      );
    }
  }

  Future<void> _selectPreset(BuildContext context, String id) async {
    try {
      await context.read<ProductStore>().setAvatarPreset(id);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('EcoChef avatar seçme hatası: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar seçilirken bir sorun oluştu, tekrar dene.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Avatar Seç',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: presetAvatars.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
              ),
              itemBuilder: (context, index) {
                final avatar = presetAvatars[index];
                return GestureDetector(
                  onTap: () => _selectPreset(context, avatar.id),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: AssetImage(avatar.assetPath),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pickFromGallery(context),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galeriden / Dosyalardan Seç'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
