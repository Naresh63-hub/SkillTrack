import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../resume/screens/resume_preview_screen.dart';
import '../models/portfolio_data.dart';
import '../services/portfolio_pdf_service.dart';

class StudentCardShareSheet extends StatelessWidget {
  final PortfolioData data;

  const StudentCardShareSheet({super.key, required this.data});

  static Future<void> show(BuildContext context, PortfolioData data) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StudentCardShareSheet(data: data),
    );
  }

  String get _publicUrl =>
      'https://skill-track-ashy.vercel.app/#/p/${data.handle}';

  String get _shareText {
    final name = data.profile.name.isNotEmpty ? data.profile.name : 'Student';
    final role = data.profile.targetJobRole.isNotEmpty
        ? data.profile.targetJobRole
        : 'Software Engineer';
    return 'Check out my verified student portfolio & live projects on SkillTrack!\n\n'
        '👤 $name\n'
        '🎯 $role\n'
        '🏅 ${data.certificates.length} Verified Certifications\n'
        '🚀 ${data.projects.length} Live Projects & Demos\n'
        '⚡ ${data.skills.length} Technical Skills\n\n'
        '🌐 View Live Web Portfolio:\n$_publicUrl';
  }

  Future<void> _launchExternalUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open external link')),
        );
      }
    }
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _publicUrl));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
            const SizedBox(width: 8),
            Expanded(child: Text('Portfolio link copied: $_publicUrl')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareToWhatsApp(BuildContext context) {
    final encoded = Uri.encodeComponent(_shareText);
    _launchExternalUrl(context, 'https://wa.me/?text=$encoded');
  }

  void _shareToLinkedIn(BuildContext context) {
    final encodedUrl = Uri.encodeComponent(_publicUrl);
    _launchExternalUrl(
        context, 'https://www.linkedin.com/sharing/share-offsite/?url=$encodedUrl');
  }

  void _shareToTwitter(BuildContext context) {
    final text = 'Check out my verified student portfolio and live demos on SkillTrack!';
    final encodedText = Uri.encodeComponent(text);
    final encodedUrl = Uri.encodeComponent(_publicUrl);
    _launchExternalUrl(
        context, 'https://twitter.com/intent/tweet?text=$encodedText&url=$encodedUrl');
  }

  Future<void> _exportPdf(BuildContext context) async {
    try {
      final pdfBytes = await PortfolioPdfService.generatePortfolioPdf(data);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => ResumePreviewScreen(
            pdfBytes: pdfBytes,
            fileName: '${data.handle}_SkillTrack_Portfolio.pdf',
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = data.profile;
    final name = profile.name.isNotEmpty ? profile.name : 'Student Name';
    final role = profile.targetJobRole.isNotEmpty
        ? profile.targetJobRole
        : 'Aspiring Software Engineer';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.badge_rounded,
                    color: AppColors.brightAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share Student Card & Portfolio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    Text(
                      'Public, verified read-only profile link',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Portfolio Card Preview
            CustomCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryPurple,
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        Text(
                          role,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.brightAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _publicUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.lightPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    tooltip: 'Copy Link',
                    color: AppColors.brightAccent,
                    onPressed: () => _copyToClipboard(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              'Share directly with recruiters & peers',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 12),

            // Share channels grid
            Row(
              children: [
                Expanded(
                  child: _buildShareButton(
                    icon: Icons.link_rounded,
                    label: 'Copy Link',
                    color: AppColors.primaryPurple,
                    onTap: () => _copyToClipboard(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildShareButton(
                    icon: Icons.chat_rounded,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () => _shareToWhatsApp(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildShareButton(
                    icon: Icons.business_center_rounded,
                    label: 'LinkedIn',
                    color: const Color(0xFF0A66C2),
                    onTap: () => _shareToLinkedIn(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildShareButton(
                    icon: Icons.tag_rounded,
                    label: 'Twitter / X',
                    color: const Color(0xFF1DA1F2),
                    onTap: () => _shareToTwitter(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildShareButton(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'Export PDF Card',
                    color: const Color(0xFFE11D48),
                    onTap: () => _exportPdf(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
