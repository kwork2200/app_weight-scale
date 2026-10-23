import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Common dark-theme palette + building blocks used by all info screens
/// (Privacy Policy, About Us, Terms & Conditions, Contact Us) so every
/// page shares the same look and structure.
class InfoTheme {
  static const Color background = Color(0xFF0A0E1A);
  static const Color card = Color(0xFF1E2940);
  static const Color accent = Color(0xFF00D4AA);
  static const Color accentBlue = Color(0xFF0066FF);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Shared scaffold for information pages: back button, gradient header and a
/// scrollable list of [InfoSection] cards.
class InfoPageScaffold extends StatelessWidget {
  const InfoPageScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
    this.headerNote,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final String? headerNote;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InfoTheme.background,
      appBar: AppBar(
        backgroundColor: InfoTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _header(),
          const Gap(20),
          ...children,
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: InfoTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: InfoTheme.accent.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: InfoTheme.accentGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                if (subtitle != null) ...[
                  const Gap(4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
                if (headerNote != null) ...[
                  const Gap(4),
                  Text(
                    headerNote!,
                    style: TextStyle(
                      color: InfoTheme.accent.withOpacity(0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled card that groups related paragraphs / bullets.
class InfoSection extends StatelessWidget {
  const InfoSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
  });

  final String title;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: InfoTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: InfoTheme.accent.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: InfoTheme.accent, size: 20),
                const Gap(10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          ...children,
        ],
      ),
    );
  }
}

/// Standard body paragraph.
class InfoParagraph extends StatelessWidget {
  const InfoParagraph(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.72),
          fontSize: 13,
          height: 1.65,
        ),
      ),
    );
  }
}

/// Bullet line with an accent dot.
class InfoBullet extends StatelessWidget {
  const InfoBullet(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7, right: 10),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: InfoTheme.accent,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
