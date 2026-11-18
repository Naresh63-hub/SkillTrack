import 'package:flutter_test/flutter_test.dart';
import 'package:skilltrack/app.dart';
import 'package:skilltrack/features/portfolio/models/portfolio_data.dart';
import 'package:skilltrack/features/portfolio/services/portfolio_pdf_service.dart';
import 'package:skilltrack/models/student_profile.dart';

void main() {
  group('Sharable Web Portfolio - Slug & URL Tests', () {
    test('publicHandle derives slug from email prefix', () {
      final profile = StudentProfile(
        name: 'Priya Sharma',
        email: 'priya.sharma@example.com',
      );
      expect(profile.publicHandle, 'priya-sharma');
      expect(profile.publicPortfolioUrl,
          'https://skill-track-ashy.vercel.app/#/p/priya-sharma');
    });

    test('publicHandle derives slug from name when email is missing', () {
      final profile = StudentProfile(
        name: 'Alex C. Rivera',
        email: '',
      );
      expect(profile.publicHandle, 'alex-c-rivera');
      expect(profile.publicPortfolioUrl,
          'https://skill-track-ashy.vercel.app/#/p/alex-c-rivera');
    });

    test('publicHandle falls back to student when name and email are empty', () {
      final profile = StudentProfile(
        name: '',
        email: '',
      );
      expect(profile.publicHandle, 'student');
    });

    test('SkillTrackApp.extractPublicHandle parses hash routing URLs', () {
      final uri = Uri.parse(
          'https://skill-track-ashy.vercel.app/#/p/priya-sharma');
      final handle = SkillTrackApp.extractPublicHandle(uri);
      expect(handle, 'priya-sharma');
    });

    test('SkillTrackApp.extractPublicHandle parses path routing URLs', () {
      final uri =
          Uri.parse('https://skill-track-ashy.vercel.app/p/john-doe');
      final handle = SkillTrackApp.extractPublicHandle(uri);
      expect(handle, 'john-doe');
    });

    test('SkillTrackApp.extractPublicHandle returns null for standard URLs', () {
      final uri = Uri.parse('https://skill-track-ashy.vercel.app/');
      final handle = SkillTrackApp.extractPublicHandle(uri);
      expect(handle, isNull);
    });
  });

  group('PortfolioData Showcase & PDF Generation Tests', () {
    test('PortfolioData.showcase populates complete verified student card', () {
      final data = PortfolioData.showcase(handle: 'priya-sharma');
      expect(data.handle, 'priya-sharma');
      expect(data.profile.name, 'Priya Sharma');
      expect(data.projects.isNotEmpty, isTrue);
      expect(data.certificates.isNotEmpty, isTrue);
      expect(data.skills.isNotEmpty, isTrue);
      expect(data.githubRepos.isNotEmpty, isTrue);

      // Verify live demo links are populated
      final firstProject = data.projects.first;
      expect(firstProject.deploymentLinks.isNotEmpty, isTrue);
      expect(
          firstProject.deploymentLinks.any((l) => l.type == 'vercel' || l.type == 'demo'),
          isTrue);

      // Verify certificate credential IDs
      final firstCert = data.certificates.first;
      expect(firstCert.credentialId, isNotNull);
      expect(firstCert.hasVerificationUrl, isTrue);
    });

    test('PortfolioPdfService generates valid non-empty PDF bytes', () async {
      final data = PortfolioData.showcase(handle: 'priya-sharma');
      final pdfBytes = await PortfolioPdfService.generatePortfolioPdf(data);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });
}
