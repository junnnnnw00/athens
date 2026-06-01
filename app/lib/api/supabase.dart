
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://hgehnwruprjoeewrhbgg.supabase.co/',
);
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhnZWhud3J1cHJqb2Vld3JoYmdnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk5ODk1NDAsImV4cCI6MjA5NTU2NTU0MH0.QZtlyvGAfTsG5r3us1gkdoHGZRLuTtbBDqalLACguuI',
);
const supabaseAuthRedirectUrl = String.fromEnvironment(
  'AUTH_REDIRECT_URL',
  defaultValue: 'https://athens.vercel.app/app/',
);

bool get isSupabaseInitialized =>
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
