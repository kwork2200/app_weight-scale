import 'package:flutter/material.dart';
import '../widgets/info_page_scaffold.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoPageScaffold(
      title: 'Terms & Conditions',
      icon: Icons.description_outlined,
      subtitle: 'Please read these terms before using Weight Scale.',
      headerNote: 'Last updated: 23 Oct 2026',
      children: [
        InfoSection(
          title: 'Acceptance Of Terms',
          icon: Icons.check_circle_outline,
          children: const [
            InfoParagraph(
                'By downloading or using Weight Scale, you agree to these terms. If you do not agree, please do not use the app.'),
          ],
        ),
        InfoSection(
          title: 'License To Use',
          icon: Icons.badge_outlined,
          children: const [
            InfoParagraph(
                'You are granted a personal, non-exclusive and non-transferable license to use the app on your own device. You may not copy, modify, reverse engineer, resell or redistribute the app or any part of it.'),
          ],
        ),
        InfoSection(
          title: 'Estimates Are Approximate',
          icon: Icons.warning_amber_outlined,
          children: const [
            InfoBullet(
                'All weights shown by the app are AI generated estimates, not measurements.'),
            InfoBullet(
                'The app is not a certified weighing device and must not be used for trade, billing, medical, legal, safety or any official purpose.'),
            InfoBullet(
                'Accuracy depends on lighting, camera quality, background and object shape, and may vary from object to object.'),
            InfoParagraph(
                'Always use a calibrated scale where an accurate weight is required.'),
          ],
        ),
        InfoSection(
          title: 'Acceptable Use',
          icon: Icons.do_not_disturb_on_outlined,
          children: const [
            InfoBullet('Do not use the app for any unlawful or harmful activity.'),
            InfoBullet(
                'Do not attempt to misuse, overload or attack the AI services used by the app.'),
            InfoBullet(
                'Do not upload content that you do not have the right to use.'),
          ],
        ),
        InfoSection(
          title: 'Ads & Third-Party Services',
          icon: Icons.campaign_outlined,
          children: const [
            InfoBullet(
                'Weight Scale is provided free of charge and is supported by advertising.'),
            InfoBullet(
                'The app uses third-party ad services such as Google AdMob and Facebook Audience Network (Meta) to show app open, banner, native and interstitial ads.'),
            InfoBullet(
                'These services may use your device advertising identifier and related technical data to serve and measure ads, as described in our Privacy Policy.'),
            InfoBullet(
                'We are not responsible for the content, products or offers shown in third-party ads, or for the websites you may reach through them.'),
            InfoParagraph(
                'Your use of the app also means you accept the terms and privacy policies of these third-party providers.'),
          ],
        ),
        InfoSection(
          title: 'No Warranty',
          icon: Icons.remove_shopping_cart_outlined,
          children: const [
            InfoParagraph(
                'The app is provided "as is" without warranties of any kind, whether express or implied, including but not limited to accuracy, fitness for a particular purpose or uninterrupted availability.'),
          ],
        ),
        InfoSection(
          title: 'Limitation Of Liability',
          icon: Icons.gavel_outlined,
          children: const [
            InfoParagraph(
                'To the maximum extent permitted by law, we are not liable for any direct, indirect, incidental or consequential loss arising from the use of, or inability to use, the app or its estimates.'),
          ],
        ),
        InfoSection(
          title: 'Intellectual Property',
          icon: Icons.copyright_outlined,
          children: const [
            InfoParagraph(
                'The app name, design, graphics and source code belong to their respective owners and are protected by applicable copyright and trademark laws.'),
          ],
        ),
        InfoSection(
          title: 'Changes To These Terms',
          icon: Icons.update_outlined,
          children: const [
            InfoParagraph(
                'These terms may be updated at any time. Continued use of the app after an update means you accept the revised terms.'),
          ],
        ),
        InfoSection(
          title: 'Contact Us',
          icon: Icons.mail_outline,
          children: const [
            InfoParagraph(
                'For any question about these terms, please contact us:'),
            InfoParagraph('Email: vaghasiyasanket36@gmail.com'),
            InfoParagraph('Phone: +91 97260 30303'),
          ],
        ),
      ],
    );
  }
}
