class SupabaseConfig {
  static const String projectUrl = 'https://ybjkranvgdsntsqqtcng.supabase.co';

  // The anon/public key for client-side queries
  // Can be copied from Supabase Dashboard -> Project Settings -> API -> anon public
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InliamtyYW52Z2RzbnRzcXF0Y25nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwMDAwMDAsImV4cCI6MjA1NTU3NjAwMH0.placeholder';

  // Direct PostgreSQL credentials (for backend / migrations / admin)
  static const String dbHost = 'aws-0-ap-south-1.pooler.supabase.com';
  static const int dbPort = 5432;
  static const String dbName = 'postgres';
  static const String dbUser = 'postgres.ybjkranvgdsntsqqtcng';
}
