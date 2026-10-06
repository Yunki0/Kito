import 'package:flutter/material.dart';

class KitoBrand {
  const KitoBrand._();

  static const forest = Color(0xFF0F5132);
  static const forestDark = Color(0xFF0A3924);
  static const cream = Color(0xFFF8F7EF);
  static const sage = Color(0xFF688F58);
  static const paleSage = Color(0xFFE8EEE1);
  static const amber = Color(0xFFF5A623);
  static const ink = Color(0xFF2E3A3F);
  static const mutedInk = Color(0xFF65716B);
}

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
      color: KitoBrand.forest,
      borderRadius: BorderRadius.circular(size * 0.29),
    ),
    child: Image.asset(
      'assets/branding/kito_icon_foreground.png',
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    ),
  );
}

class KitoLoadingView extends StatefulWidget {
  const KitoLoadingView({
    super.key,
    this.message = 'Préparation de votre inventaire…',
  });

  final String message;

  @override
  State<KitoLoadingView> createState() => _KitoLoadingViewState();
}

class _KitoLoadingViewState extends State<KitoLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathing;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _breathing = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1, end: 1.025).animate(
      CurvedAnimation(parent: _breathing, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ColoredBox(
      color: KitoBrand.forestDark,
      child: Semantics(
        liveRegion: true,
        label: widget.message,
        child: ExcludeSemantics(
          child: Center(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _scale,
                builder: (context, _) => Transform.scale(
                  scale: reduceMotion ? 1 : _scale.value,
                  child: const SizedBox.expand(
                    child: Image(
                      image: AssetImage('assets/branding/kito_splash.png'),
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
