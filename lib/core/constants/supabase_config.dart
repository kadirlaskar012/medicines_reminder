class SupabaseConfig {
  static const String projectUrl = 'https://ybjkranvgdsntsqqtcng.supabase.co';

  // The verified anon/public key for client-side queries
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InliamtyYW52Z2RzbnRzcXF0Y25nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkyOTA1NTYsImV4cCI6MjEwNDg2NjU1Nn0.ndPVXa0bHRVUqTqldkqvx77OTYiaL4VhFQ0LXKIHnxQ';

  // Direct PostgreSQL credentials (for backend / migrations / admin)
  static const String dbHost = 'aws-0-ap-south-1.pooler.supabase.com';
  static const int dbPort = 5432;
  static const String dbName = 'postgres';
  static const String dbUser = 'postgres.ybjkranvgdsntsqqtcng';
}
