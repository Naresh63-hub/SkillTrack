/// SkillTrack - Supabase Cloud Configuration
///
/// Security:
/// - Only the public Publishable / Anon Key is included here for client-side authentication.
/// - The Service Role Secret Key must NEVER be stored in client-side code.
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://uymkuhkognedjcwtveso.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_LvxqV_YAgVl-pgM1ogEVGg_DspqvCUi',
  );

  static bool get isConfigured =>
      url.trim().isNotEmpty && anonKey.trim().isNotEmpty;
}
