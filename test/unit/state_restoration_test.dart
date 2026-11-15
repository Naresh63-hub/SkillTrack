import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skilltrack/services/draft_service.dart';
import 'package:skilltrack/services/navigation_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DraftService Unit Tests', () {
    test('saveDraft and getDraft preserve form data faithfully', () async {
      final draftService = DraftService.instance;
      await draftService.saveDraft('test_form', {
        'title': 'System Design Practice',
        'content': 'Study rate limiter and caching strategies.',
        'category': 'DSA & Coding',
      });

      final retrieved = await draftService.getDraft('test_form');
      expect(retrieved, isNotNull);
      expect(retrieved!['title'], 'System Design Practice');
      expect(retrieved['content'],
          'Study rate limiter and caching strategies.');
      expect(retrieved['category'], 'DSA & Coding');
      expect(retrieved['_draft_saved_at'], isNotNull);
    });

    test('hasDraft returns true only when meaningful content exists',
        () async {
      final draftService = DraftService.instance;
      expect(await draftService.hasDraft('empty_form'), isFalse);

      await draftService.saveDraft('blank_form', {'title': '   ', 'notes': ''});
      expect(await draftService.hasDraft('blank_form'), isFalse);

      await draftService.saveDraft('valid_form', {'title': 'Flutter BLoC'});
      expect(await draftService.hasDraft('valid_form'), isTrue);
    });

    test('clearDraft removes specific form draft', () async {
      final draftService = DraftService.instance;
      await draftService.saveDraft('form_a', {'name': 'Project Alpha'});
      await draftService.saveDraft('form_b', {'name': 'Project Beta'});

      await draftService.clearDraft('form_a');

      expect(await draftService.getDraft('form_a'), isNull);
      expect(await draftService.getDraft('form_b'), isNotNull);
    });

    test('clearAllDrafts wipes all form drafts without touching other keys',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('other_user_setting', 'dark_theme');

      final draftService = DraftService.instance;
      await draftService.saveDraft('d1', {'data': '1'});
      await draftService.saveDraft('d2', {'data': '2'});

      await draftService.clearAllDrafts();

      expect(await draftService.getDraft('d1'), isNull);
      expect(await draftService.getDraft('d2'), isNull);
      expect(prefs.getString('other_user_setting'), 'dark_theme');
    });
  });

  group('NavigationStateService Unit Tests', () {
    test('saveActiveTab clamps and persists tab index', () async {
      final navService = NavigationStateService.instance;
      await navService.saveActiveTab(2);
      expect(await navService.getActiveTab(), 2);

      // Clamp negative index
      await navService.saveActiveTab(-3);
      expect(await navService.getActiveTab(), 0);

      // Clamp overflow index
      await navService.saveActiveTab(9);
      expect(await navService.getActiveTab(), 4);
    });

    test('saveActiveRoute and getActiveRoute manage sub-screen navigation',
        () async {
      final navService = NavigationStateService.instance;
      expect(await navService.getActiveRoute(), isNull);

      await navService.saveActiveRoute('notes_planner');
      expect(await navService.getActiveRoute(), 'notes_planner');

      await navService.saveActiveRoute(null);
      expect(await navService.getActiveRoute(), isNull);
    });

    test('recordAppBackgrounded and isRecentSession calculate threshold',
        () async {
      final navService = NavigationStateService.instance;
      expect(await navService.isRecentSession(), isFalse);

      await navService.recordAppBackgrounded();
      expect(await navService.isRecentSession(), isTrue);
    });

    test('clearSession removes all session tracking keys', () async {
      final navService = NavigationStateService.instance;
      await navService.saveActiveTab(3);
      await navService.saveActiveRoute('career_roadmaps');
      await navService.recordAppBackgrounded();

      await navService.clearSession();

      expect(await navService.getActiveTab(), 0);
      expect(await navService.getActiveRoute(), isNull);
      expect(await navService.isRecentSession(), isFalse);
    });
  });
}
