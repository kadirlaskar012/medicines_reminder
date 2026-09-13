import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';

class AdminControlPanelScreen extends StatefulWidget {
  const AdminControlPanelScreen({super.key});

  @override
  State<AdminControlPanelScreen> createState() => _AdminControlPanelScreenState();
}

class _AdminControlPanelScreenState extends State<AdminControlPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _supabase = SupabaseService.instance;

  bool _isLoading = true;
  Map<String, int> _stats = {'users': 0, 'medicines': 0, 'pending_requests': 0};
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _medicines = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAdminData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_users);
      } else {
        _filteredUsers = _users.where((u) {
          final phone = u['phone_number']?.toString().toLowerCase() ?? '';
          final name = u['name']?.toString().toLowerCase() ?? '';
          return phone.contains(query) || name.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _supabase.adminGetStats();
      final users = await _supabase.adminGetAllUsers();
      final requests = await _supabase.adminGetAllRequests();
      final medicines = await _supabase.adminGetAllMedicines();

      if (mounted) {
        setState(() {
          _stats = stats;
          _users = users;
          _filteredUsers = users;
          _requests = requests;
          _medicines = medicines;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading admin data: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot launch dialer for $clean'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber, String userName) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final msg = Uri.encodeComponent('হ্যালো $userName, MediRemind সাপোর্ট থেকে যোগাযোগ করা হচ্ছে। আপনার পিন রিসেট করার বিষয়ে সাহায্য করতে আমরা প্রস্তুত।');
    final uri = Uri.parse('https://wa.me/$clean?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _makeCall(phoneNumber);
    }
  }

  void _showResetPinDialog({required String phoneNumber, required String userName, String? requestId}) {
    final pinController = TextEditingController(text: '1234');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.vpn_key_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'পিন পরিবর্তন / রিসেট করুন',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ইউজার: $userName', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('ফোন: $phoneNumber', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              const Text('নতুন ৪-সংখ্যার সিকিউরিটি পিন দিন:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '৪-সংখ্যার পিন',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final newPin = pinController.text.trim();
                if (newPin.length != 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('৪ সংখ্যার পিন লিখুন'), backgroundColor: AppColors.error),
                  );
                  return;
                }
                Navigator.pop(ctx);

                final ok = await _supabase.adminUpdateUserPin(phoneNumber: phoneNumber, newPin: newPin);
                if (requestId != null) {
                  await _supabase.adminResolveRequest(requestId);
                }

                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ $phoneNumber-এর পিন সফলভাবে পরিবর্তন করা হয়েছে: $newPin'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _loadAdminData();
                }
              },
              child: const Text('সংরক্ষণ করুন'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Admin Control Panel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload Data',
            onPressed: _loadAdminData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              icon: Badge(
                isLabelVisible: _stats['pending_requests']! > 0,
                label: Text('${_stats['pending_requests']}'),
                child: const Icon(Icons.support_agent_rounded),
              ),
              text: 'সাপোর্ট রিকোয়েস্ট',
            ),
            Tab(
              icon: const Icon(Icons.people_alt_rounded),
              text: 'ইউজার তালিকা (${_stats['users']})',
            ),
            Tab(
              icon: const Icon(Icons.medication_rounded),
              text: 'ওষুধ (${_stats['medicines']})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsTab(isDark),
                _buildUsersTab(isDark),
                _buildMedicinesTab(isDark),
              ],
            ),
    );
  }

  // ==================== TAB 1: SUPPORT & PIN RESET REQUESTS ====================
  Widget _buildRequestsTab(bool isDark) {
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.success.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            const Text('কোনো সাপোর্ট রিকোয়েস্ট পেন্ডিং নেই!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('ইউজাররা পিন ভুলে সাহায্য চাইলে এখানে প্রদর্শিত হবে।', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final req = _requests[index];
        final phone = req['phone_number']?.toString() ?? '';
        final name = req['user_name']?.toString() ?? 'User';
        final message = req['message']?.toString() ?? 'Forgot PIN';
        final status = req['status']?.toString() ?? 'pending';
        final isPending = status == 'pending';
        final createdAtStr = req['created_at'] != null
            ? DateFormat('dd MMM, hh:mm a').format(DateTime.tryParse(req['created_at']) ?? DateTime.now())
            : '';

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isPending ? AppColors.warning.withValues(alpha: 0.5) : Colors.transparent,
              width: 1.5,
            ),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isPending ? AppColors.warning.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                          child: Icon(
                            isPending ? Icons.warning_amber_rounded : Icons.check_rounded,
                            color: isPending ? AppColors.warning : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(phone, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPending ? AppColors.warning.withValues(alpha: 0.15) : AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPending ? 'Pending' : 'Resolved',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPending ? AppColors.warning : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('বার্তা: $message\nসময়: $createdAtStr', style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _makeCall(phone),
                        icon: const Icon(Icons.call_rounded, size: 16),
                        label: const Text('কল দিন'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openWhatsApp(phone, name),
                        icon: const Icon(Icons.chat_rounded, size: 16),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showResetPinDialog(
                          phoneNumber: phone,
                          userName: name,
                          requestId: req['id']?.toString(),
                        ),
                        icon: const Icon(Icons.key_rounded, size: 16),
                        label: const Text('পিন রিসেট'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== TAB 2: USER DIRECTORY ====================
  Widget _buildUsersTab(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ফোন নম্বর বা নাম দিয়ে খুঁজুন...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: _filteredUsers.isEmpty
              ? const Center(child: Text('কোনো ইউজার পাওয়া যায়নি'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final u = _filteredUsers[index];
                    final phone = u['phone_number']?.toString() ?? '';
                    final name = u['name']?.toString() ?? 'Patient';
                    final pin = u['security_pin']?.toString() ?? 'সেট করা নেই';
                    final question = u['security_question']?.toString();
                    final lastLogin = u['last_login'] != null
                        ? DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.tryParse(u['last_login']) ?? DateTime.now())
                        : 'Unknown';

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            if (u['is_admin'] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(6)),
                                child: const Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('📱 $phone', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                            Text('🔑 PIN: $pin', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                            if (question != null)
                              Text('❓ প্রশ্ন: $question', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('🕒 শেষ সক্রিয়: $lastLogin', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                          tooltip: 'পিন পরিবর্তন করুন',
                          onPressed: () => _showResetPinDialog(phoneNumber: phone, userName: name),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==================== TAB 3: MEDICINES DIRECTORY ====================
  Widget _buildMedicinesTab(bool isDark) {
    if (_medicines.isEmpty) {
      return const Center(child: Text('ক্লাউডে কোনো ওষুধ সংরক্ষিত নেই'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _medicines.length,
      itemBuilder: (context, index) {
        final m = _medicines[index];
        final name = m['name']?.toString() ?? '';
        final dosage = m['dosage']?.toString() ?? '';
        final type = m['type']?.toString() ?? 'tablet';
        final phone = m['phone_number']?.toString() ?? '';
        final stock = m['current_stock']?.toString() ?? '0';

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: const Icon(Icons.medication_rounded, color: AppColors.primary),
            ),
            title: Text('$name ($dosage)', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('ইউজার: $phone • ধরন: $type • স্টক: $stock টি'),
          ),
        );
      },
    );
  }
}
