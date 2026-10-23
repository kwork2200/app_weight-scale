import 'package:app_weight_scale/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../widgets/info_page_scaffold.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const String _email = 'vaghasiyasanket36@gmail.com';
  static const String _phone = '+91 97260 30303';

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied',style: TextStyle(color: AppColor.white)),
        backgroundColor: InfoTheme.card,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InfoPageScaffold(
      title: 'Contact Us',
      icon: Icons.support_agent,
      subtitle: 'Need help, found a bug or have a suggestion? Reach out to us.',
      children: [
        _ContactTile(
          icon: Icons.mail_outline,
          label: 'Email',
          value: _email,
          onTap: () => _copy(context, 'Email', _email),
        ),
        _ContactTile(
          icon: Icons.call_outlined,
          label: 'Phone',
          value: _phone,
          onTap: () => _copy(context, 'Phone number', _phone),
        ),
        const Gap(4),
        InfoSection(
          title: 'Support Hours',
          icon: Icons.schedule_outlined,
          children: const [
            InfoBullet('Monday to Saturday, 10:00 AM – 7:00 PM (IST).'),
            InfoBullet('We usually reply within 24–48 hours on working days.'),
          ],
        ),
        InfoSection(
          title: 'Before You Write',
          icon: Icons.tips_and_updates_outlined,
          children: const [
            InfoBullet(
                'Tell us your phone model and Android version so we can help faster.'),
            InfoBullet(
                'For issues while scanning, mention the object you were trying to weigh.'),
            InfoBullet(
                'Suggestions to improve accuracy are always welcome.'),
          ],
        ),
        InfoSection(
          title: 'Report An Ad',
          icon: Icons.report_gmailerrorred_outlined,
          children: const [
            InfoParagraph(
                'Found an ad that is inappropriate, misleading or not working? Email us with a screenshot and the app version, and we will block it with our ad partners.'),
          ],
        ),
        InfoSection(
          title: 'Tap To Copy',
          icon: Icons.content_copy_outlined,
          children: const [
            InfoParagraph(
                'Tap the email or phone card above to copy the details instantly.'),
          ],
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: InfoTheme.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: InfoTheme.accent.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: InfoTheme.accentGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.copy_rounded,
                    color: InfoTheme.accent.withOpacity(0.8), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
