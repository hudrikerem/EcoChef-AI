import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class GeminiService {
  static const String _apiKey = 'YOUR_API_KEY';
  
  static const String _lastDateKey = 'last_recipe_date';
  static const String _lastRecipeKey = 'last_recipe_text';

  Future<String?> getTodaysRecipe() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastDateKey);
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastDate == today) {
      return prefs.getString(_lastRecipeKey);
    }
    return null; 
  }

  Future<String> generateRecipe(List<Product> products) async {
    if (products.isEmpty) {
      return "Tarif önerebilmem için önce stoklarına birkaç ürün eklemelisin.";
    }

    final soonToExpire = products.where((p) => p.daysUntilExpiry <= 3 && p.daysUntilExpiry >= 0).toList();
    final others = products.where((p) => p.daysUntilExpiry > 3).toList();

    String prompt = "Sen uzman ve yaratıcı bir şefsin. Amacın gıda israfını önlemek. Kullanıcının elindeki malzemeler şunlar:\n\n";
    
    if (soonToExpire.isNotEmpty) {
      prompt += "Hemen tüketilmesi gerekenler (SKT'si çok yakın, KESİNLİKLE kullan): ${soonToExpire.map((e) => e.name).join(', ')}\n";
    }
    if (others.isNotEmpty) {
      prompt += "Diğer malzemeler: ${others.map((e) => e.name).join(', ')}\n";
    }

    prompt += "\nLütfen bu malzemeleri kullanarak lezzetli ve pratik İKİ tane tarif öner. Eğer İKİ tane öneremiyorsan bir tane de yeterli olur. Cevabında aşağıdaki yazdıklarım dışında hiçbir şey yazma."
        "Tarifin estetik bir başlığı, malzeme listesi, gereken miktarlar ve adım adım yapılışı olsun. Samimi ve motive edici bir dil kullan. "
        "Eğer listedeki malzemeler tek başına bir yemek yapmaya yetmiyorsa, her evde bulunabilecek temel malzemeleri (tuz, yağ, un, karabiber vb.) ekleyebileceğini varsay. "
        "Sonucu Markdown formatında, kalın yazıları ve listeleri güzelce biçimlendirerek ver.";

    final model = GenerativeModel(
      model: 'gemini-3.5-flash-lite',
      apiKey: _apiKey,
    );

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final recipeText = response.text ?? "Tarif oluşturulamadı.";

      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString(_lastDateKey, today);
      await prefs.setString(_lastRecipeKey, recipeText);

      return recipeText;
    } catch (e) {
      throw Exception("Şef ile iletişim kurulamadı. İnternet bağlantını kontrol et. Hata: $e");
    }
  }
}