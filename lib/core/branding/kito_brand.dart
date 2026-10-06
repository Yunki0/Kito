import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/kito_colors.dart';

/// Pastille verte avec le symbole (AppBar, écran d'erreur). Inchangé.
class KitoMark extends StatelessWidget {
  const KitoMark({super.key, this.size = 42, this.padding = 5});

  final double size;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: KitoColors.primary,
      borderRadius: BorderRadius.circular(size * 0.29),
    ),
    child: Image.asset(
      'assets/branding/kito_icon_foreground.png',
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    ),
  );
}

/// Écran de démarrage (ouverture de la base). À utiliser UNE fois, dans
/// HomePage, pendant `databaseReadyProvider`.
///
/// Le symbole est exactement au centre de l'écran et fait la même taille que
/// celui du splash natif (192 dp de canevas) : la transition natif -> Flutter
/// est invisible. Seuls le nom, la baseline et les collines apparaissent.
class KitoSplashView extends StatefulWidget {
  const KitoSplashView({super.key, this.message = 'Ouverture de votre matériel…'});

  final String message;

  @override
  State<KitoSplashView> createState() => _KitoSplashViewState();
}

class _KitoSplashViewState extends State<KitoSplashView>
    with SingleTickerProviderStateMixin {
  static const _markCanvas = 192.0; // doit rester égal à kito_splash_mark.png / 4
  static const _hillsHeight = 150.0;

  late final AnimationController _controller;
  late final Animation<double> _hills;
  late final Animation<double> _wordmark;
  late final Animation<double> _tagline;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _hills = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    );
    _wordmark = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOutCubic),
    );
    _tagline = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      liveRegion: true,
      label: widget.message,
      child: ExcludeSemantics(
        child: ColoredBox(
          color: KitoColors.background,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final centerY = constraints.maxHeight / 2;
              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _hillsHeight,
                    child: AnimatedBuilder(
                      animation: _hills,
                      builder: (_, child) => Opacity(
                        opacity: _hills.value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - _hills.value) * 24),
                          child: child,
                        ),
                      ),
                      child: const CustomPaint(painter: _HillsPainter()),
                    ),
                  ),
                  Center(
                    child: SvgPicture.asset(
                      'assets/branding/kito_mark_color.svg',
                      width: _markCanvas,
                      height: _markCanvas,
                    ),
                  ),
                  Positioned(
                    top: centerY + 58,
                    left: 24,
                    right: 24,
                    child: Column(
                      children: [
                        FadeTransition(
                          opacity: _wordmark,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.25),
                              end: Offset.zero,
                            ).animate(_wordmark),
                            child: const Text(
                              'Kito',
                              style: TextStyle(
                                color: KitoColors.primary,
                                fontSize: 44,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        FadeTransition(
                          opacity: _tagline,
                          child: const Text(
                            'Le matériel de l’unité,\ntoujours à portée de main',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: KitoColors.textSecondary,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        FadeTransition(
                          opacity: _tagline,
                          child: SizedBox(
                            width: 64,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                minHeight: 3,
                                value: reduceMotion ? 0.4 : null,
                                color: KitoColors.secondary,
                                backgroundColor: KitoColors.selectedGreen,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HillsPainter extends CustomPainter {
  const _HillsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final back = Path()
      ..moveTo(0, h * 0.35)
      ..cubicTo(w * 0.25, h * 0.05, w * 0.55, h * 0.45, w * 0.78, h * 0.2)
      ..cubicTo(w * 0.9, h * 0.08, w * 0.96, h * 0.14, w, h * 0.1)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(back, Paint()..color = KitoColors.selectedGreen);

    final front = Path()
      ..moveTo(0, h * 0.65)
      ..cubicTo(w * 0.3, h * 0.4, w * 0.6, h * 0.75, w, h * 0.45)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(front, Paint()..color = KitoColors.paleGreen);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Chargement léger à l'intérieur d'un onglet (inventaire, emprunts, journal).
/// Remplace l'ancien usage du splash plein écran de 3,8 Mo.
class KitoLoadingView extends StatelessWidget {
  const KitoLoadingView({
    super.key,
    this.message = 'Préparation de votre inventaire…',
  });

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: message,
    child: ExcludeSemantics(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: KitoColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: KitoColors.textSecondary),
            ),
          ],
        ),
      ),
    ),
  );
}