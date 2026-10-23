import 'package:flutter/material.dart';
import '../widgets/info_page_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoPageScaffold(
      title: 'Privacy Policy',
      icon: Icons.privacy_tip_outlined,
      subtitle:
          'Learn how Weight Scale collects, uses and protects your information.',
      headerNote: 'Last updated: 23 Oct 2026',
      children: [
        InfoSection(
          title: 'Information We Use',
          icon: Icons.photo_camera_outlined,
          children: const [
            InfoBullet(
                'Camera photos you capture are used only to estimate the weight of the object in the photo.'),
            InfoBullet(
                'Estimated results such as object name, weight range and confidence score are saved in your scan history.'),
            InfoBullet(
                'Your calibration value (for example, a known 100 g reference) is stored so you do not have to set it again.'),
            InfoParagraph(
                'Weight Scale does not ask for your name, email or any account registration to work.'),
          ],
        ),
        InfoSection(
          title: 'Camera Permission',
          icon: Icons.videocam_outlined,
          children: const [
            InfoParagraph(
                'The app requests camera access only when you tap Scan. If you deny the permission, you cannot scan objects, but the rest of the app keeps working.'),
            InfoParagraph(
                'You can change or revoke the camera permission at any time from your device Settings.'),
          ],
        ),
        InfoSection(
          title: 'Where Your Photos Are Processed',
          icon: Icons.cloud_outlined,
          children: const [
            InfoParagraph(
                'Weight estimation is AI based. The photo you capture is sent securely to the Google Gemini API for analysis and is returned as an estimated weight.'),
            InfoBullet(
                'On-device processing: face detection runs locally with Google ML Kit and does not upload your image on its own.'),
            InfoBullet(
                'Photos are not stored on our servers. They are used for the single estimation request only.'),
            InfoBullet(
                'Google processes the request under its own privacy terms: policies.google.com/privacy'),
          ],
        ),
        InfoSection(
          title: 'Data Stored On Your Device',
          icon: Icons.phone_android_outlined,
          children: const [
            InfoParagraph(
                'Scan history is kept locally on your phone and is never uploaded to us. It is limited to the most recent scans.'),
            InfoParagraph(
                'You can remove everything at any time: open Scan History from the home screen and tap Clear.'),
          ],
        ),
        InfoSection(
          title: 'Advertising & Third-Party Services',
          icon: Icons.campaign_outlined,
          children: const [
            InfoParagraph(
                'Weight Scale is free to use and is supported by advertisements. Ads may appear as app open, banner, native and full-screen (interstitial) formats.'),
            InfoBullet(
                'We use Google AdMob and Facebook Audience Network (Meta) to display ads.'),
            InfoBullet(
                'These ad partners may collect your device advertising identifier (Advertising ID), IP address, device and network information to serve, limit and measure ads.'),
            InfoBullet(
                'Ads may be personalised based on your interests, or non-personalised where required by law or by your device settings.'),
            InfoBullet(
                'You can reset or delete your Advertising ID and opt out of personalised ads from your device Settings > Google > Ads.'),
            InfoParagraph(
                'Google privacy policy: policies.google.com/privacy'),
            InfoParagraph(
                'Meta (Facebook) privacy policy: facebook.com/privacy/policy'),
          ],
        ),
        InfoSection(
          title: 'What We Do Not Do',
          icon: Icons.block_outlined,
          children: const [
            InfoBullet(
                'We do not sell or rent your photos, scan history or personal information to anyone.'),
            InfoBullet(
                'We do not collect your contacts, messages or precise location data.'),
            InfoBullet(
                'We do not use the photos you scan to target advertising.'),
          ],
        ),
        InfoSection(
          title: 'Children\'s Privacy',
          icon: Icons.child_care_outlined,
          children: const [
            InfoParagraph(
                'The app is not directed to children under 13. We do not knowingly collect personal information from children.'),
          ],
        ),
        InfoSection(
          title: 'Changes To This Policy',
          icon: Icons.update_outlined,
          children: const [
            InfoParagraph(
                'We may update this policy from time to time. Any change will be reflected on this page with a new "Last updated" date.'),
          ],
        ),
        InfoSection(
          title: 'Contact Us',
          icon: Icons.mail_outline,
          children: const [
            InfoParagraph(
                'Questions about this policy? Reach us any time and we will be happy to help.'),
            InfoParagraph('Email: vaghasiyasanket36@gmail.com'),
            InfoParagraph('Phone: +91 97260 30303'),
          ],
        ),
      ],
    );
  }
}
