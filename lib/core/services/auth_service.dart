import 'supabase_service.dart';

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  SupabaseService get _supabase => SupabaseService.instance;

  bool get isSignedIn => _supabase.isSignedIn;

  String? get userPhoneNumber => _supabase.currentUser?.phoneNumber;

  String? get userDisplayName => _supabase.currentUser?.name;

  String? get userId => _supabase.currentUser?.id;

  Future<void> signOut() async {
    await _supabase.signOut();
  }
}
