/// Konfigurasi Supabase untuk RF-Builders (Rlink).
///
/// Dapatkan URL dan Anon/Publishable Key dari Supabase Dashboard:
/// Project Settings -> API -> Project URL & Project API Keys (anon public / publishable).
class SupabaseConfig {
  SupabaseConfig._();

  /// Project URL dari Supabase Dashboard
  static const String supabaseUrl = 'https://yuceisdouyzyboiyjfns.supabase.co';

  /// Publishable/Anon Key dari Supabase Dashboard
  static const String supabaseAnonKey =
      'sb_publishable_Zeco7yYP9Izg5ldkuodUzw_m1uhsxuT';

  /// Menandakan apakah kredensial Supabase sudah diisi dengan benar.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('YOUR_PROJECT_ID') &&
      !supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY');
}
