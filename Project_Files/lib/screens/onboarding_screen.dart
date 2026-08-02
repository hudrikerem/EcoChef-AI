import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'login_screen.dart'; 

class AppColors {
  static const Color green = Color(0xFF2D6A4F);
  static const Color greenDark = Color(0xFF1B4332);
  static const Color greenLight = Color(0xFF52A373);
  static const Color tint = Color(0xFFE8F3EC);
  static const Color tintSoft = Color(0xFFF3F9F5);
  static const Color orange = Color(0xFFE8842B); // sıcak vurgu
  static const Color textDark = Color(0xFF1B2E24);
  static const Color textGrey = Color(0xFF6B7B72);
}

class HeroChip {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final Alignment align;
  final double angle;
  final double phase;

  const HeroChip({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.align,
    required this.angle,
    required this.phase,
  });
}

class OnboardingPageData {
  final String image;
  final String titlePlain;
  final String titleAccent;
  final String subtitle;
  final List<HeroChip> chips;

  const OnboardingPageData({
    required this.image,
    required this.titlePlain,
    required this.titleAccent,
    required this.subtitle,
    required this.chips,
  });
}

const List<OnboardingPageData> onboardingPages = [
  OnboardingPageData(
    image: 'assets/illustrations/track.svg',
    titlePlain: 'Gıdalarını',
    titleAccent: 'Takip Et',
    subtitle:
        'Evindeki gıdaların son kullanma tarihlerini tek yerden kaydet ve kolayca yönet.',
    chips: [
      HeroChip(
        icon: Icons.schedule,
        label: 'Son 2 gün',
        bg: Colors.white,
        fg: AppColors.orange,
        align: Alignment(0.92, -0.72),
        angle: 0.10,
        phase: 0.0,
      ),
      HeroChip(
        icon: Icons.check_circle,
        label: 'Takipte',
        bg: AppColors.green,
        fg: Colors.white,
        align: Alignment(-0.9, 0.7),
        angle: -0.09,
        phase: 0.5,
      ),
    ],
  ),
  OnboardingPageData(
    image: 'assets/illustrations/alert.svg',
    titlePlain: 'Zamanında',
    titleAccent: 'Haberdar Ol',
    subtitle:
        'Gıdaların bozulmadan önce akıllı hatırlatmalar al, hiçbir şeyi çöpe atma.',
    chips: [
      HeroChip(
        icon: Icons.notifications_active,
        label: 'Süt yarın!',
        bg: Colors.white,
        fg: AppColors.orange,
        align: Alignment(-0.92, -0.7),
        angle: -0.10,
        phase: 0.25,
      ),
      HeroChip(
        icon: Icons.done_all,
        label: 'Hatırlatıldı',
        bg: AppColors.green,
        fg: Colors.white,
        align: Alignment(0.9, 0.72),
        angle: 0.08,
        phase: 0.6,
      ),
    ],
  ),
  OnboardingPageData(
    image: 'assets/illustrations/recipe.svg',
    titlePlain: 'Tariflerle',
    titleAccent: 'İsrafı Önle',
    subtitle:
        'Son kullanma tarihi yaklaşan malzemelerle yapabileceğin lezzetli tarifleri keşfet.',
    chips: [
      HeroChip(
        icon: Icons.restaurant_menu,
        label: '2 optimal tarif',
        bg: AppColors.green,
        fg: Colors.white,
        align: Alignment(0.92, -0.72),
        angle: 0.10,
        phase: 0.1,
      ),
      HeroChip(
        icon: Icons.eco,
        label: 'Sıfır israf',
        bg: Colors.white,
        fg: AppColors.green,
        align: Alignment(-0.9, 0.68),
        angle: -0.08,
        phase: 0.55,
      ),
    ],
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  late final AnimationController _floatController;
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == onboardingPages.length - 1;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_isLastPage) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, AppColors.tintSoft],
              ),
            ),
          ),
          _buildFloatingBlobs(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: onboardingPages.length,
                        onPageChanged: (index) =>
                            setState(() => _currentPage = index),
                        itemBuilder: (context, index) {
                          return _OnboardingPageView(
                            data: onboardingPages[index],
                            pageIndex: index,
                            controller: _controller,
                            floatController: _floatController,
                          );
                        },
                      ),
                    ),
                    _buildDots(),
                    const SizedBox(height: 28),
                    _PressableButton(
                      label: _isLastPage ? 'Başlayalım' : 'İleri',
                      icon: _isLastPage
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      onTap: _goToNextPage,
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBlobs() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        double bob(double phase, double amp) =>
            math.sin((_floatController.value + phase) * 2 * math.pi) * amp;
        return Stack(
          children: [
            Positioned(
              top: -60 + bob(0.0, 10),
              right: -40,
              child: _blob(200, AppColors.green.withValues(alpha: 0.06)),
            ),
            Positioned(
              top: 180 + bob(0.3, 12),
              left: -70,
              child: _blob(160, AppColors.green.withValues(alpha: 0.05)),
            ),
            Positioned(
              bottom: -50 + bob(0.6, 10),
              right: -30,
              child: _blob(180, AppColors.green.withValues(alpha: 0.07)),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              const Text(
                'EcoChef AI',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          _isLastPage
              ? const SizedBox(height: 40)
              : TextButton(
                  onPressed: _skip,
                  child: const Text(
                    'Atla',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 15),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        onboardingPages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: index == _currentPage ? 26 : 8,
          decoration: BoxDecoration(
            color: index == _currentPage
                ? AppColors.green
                : AppColors.green.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _PressableButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PressableButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.green, AppColors.greenDark],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(widget.icon, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  final OnboardingPageData data;
  final int pageIndex;
  final PageController controller;
  final AnimationController floatController;

  const _OnboardingPageView({
    required this.data,
    required this.pageIndex,
    required this.controller,
    required this.floatController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, floatController]),
      builder: (context, child) {
        double page = pageIndex.toDouble();
        if (controller.hasClients && controller.page != null) {
          page = controller.page!;
        }
        final delta = pageIndex - page;

        final heroDx = delta * 40;
        final scale = (1 - delta.abs() * 0.16).clamp(0.0, 1.0);
        final opacity = (1 - delta.abs() * 0.6).clamp(0.0, 1.0);

        double bob(double phase, double amp) =>
            math.sin((floatController.value + phase) * 2 * math.pi) * amp;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: Offset(heroDx, 0),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(opacity: opacity, child: _buildHero(bob)),
                ),
              ),
              const SizedBox(height: 44),
              Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(delta * 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${data.titlePlain}\n'),
                            TextSpan(
                              text: data.titleAccent,
                              style: const TextStyle(color: AppColors.green),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.6,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        data.subtitle,
                        style: const TextStyle(
                          fontSize: 15.5,
                          height: 1.6,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHero(double Function(double, double) bob) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(0, bob(0.0, 6)),
            child: Transform.rotate(
              angle: -0.05,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.tint,
                  borderRadius: BorderRadius.circular(48),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.20),
                      blurRadius: 34,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: SvgPicture.asset(
                  data.image,
                  width: 196,
                  height: 196,
                ),
              ),
            ),
          ),
          // Süzülen kartçıklar
          for (final chip in data.chips)
            Align(
              alignment: chip.align,
              child: Transform.translate(
                offset: Offset(0, bob(chip.phase, 8)),
                child: Transform.rotate(
                  angle: chip.angle,
                  child: _buildChip(chip),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(HeroChip chip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: chip.bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chip.icon, size: 16, color: chip.fg),
          const SizedBox(width: 6),
          Text(
            chip.label,
            style: TextStyle(
              color: chip.fg,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}