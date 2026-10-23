import 'package:flutter/material.dart';
import '../widgets/info_page_scaffold.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoPageScaffold(
      title: 'About Us',
      icon: Icons.info_outline,
      subtitle: 'A simple, smart way to find out how heavy something is.',
      headerNote: 'Version 1.0.0',
      children: [
        InfoSection(
          title: 'What We Do',
          icon: Icons.scale_outlined,
          children: const [
            InfoParagraph(
                'Weight Scale is an AI powered weighing assistant. Point your camera at an object, capture a photo, and the app estimates its weight in seconds.'),
            InfoParagraph(
                'It is built for quick everyday answers — checking a package before shipping, sorting fruits and vegetables, or simply satisfying your curiosity.'),
          ],
        ),
        InfoSection(
          title: 'How It Works',
          icon: Icons.auto_awesome_outlined,
          children: const [
            InfoBullet('You capture a photo of the object.'),
            InfoBullet(
                'The AI model identifies the object and studies its size in the frame.'),
            InfoBullet(
                'The app combines object knowledge with size analysis to estimate a weight range.'),
            InfoBullet(
                'For better precision you can calibrate once using a known weight (for example, a 100 g packet).'),
          ],
        ),
        InfoSection(
          title: 'Accuracy You Can Expect',
          icon: Icons.verified_outlined,
          children: const [
            InfoParagraph(
                'Typical accuracy is around 85–95% for common, clearly visible objects. Results improve with good lighting, a clean background and a full view of the object.'),
            InfoParagraph(
                'Estimates are indicative only. For trade, medical, legal or any certified measurement, always use a calibrated weighing scale.'),
          ],
        ),
        InfoSection(
          title: 'Free, With Ads',
          icon: Icons.campaign_outlined,
          children: const [
            InfoParagraph(
                'Weight Scale is completely free. To keep it that way, the app shows ads through trusted partners like Google AdMob and Facebook Audience Network (Meta).'),
            InfoParagraph(
                'Ads help us maintain and improve the app. You can learn how ad data is handled in our Privacy Policy.'),
          ],
        ),
        InfoSection(
          title: 'Our Promise',
          icon: Icons.favorite_outline,
          children: const [
            InfoBullet('No sign-up, no clutter — just open and scan.'),
            InfoBullet('Your scan history stays on your own device.'),
            InfoBullet('We keep improving accuracy with every update.'),
          ],
        ),
        InfoSection(
          title: 'Get In Touch',
          icon: Icons.mail_outline,
          children: const [
            InfoParagraph(
                'Feedback, feature ideas or a bug to report? We would love to hear from you.'),
            InfoParagraph('Email: vaghasiyasanket36@gmail.com'),
            InfoParagraph('Phone: +91 97260 30303'),
          ],
        ),
      ],
    );
  }
}
