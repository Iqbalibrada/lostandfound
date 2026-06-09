import 'package:flutter/material.dart';
import 'package:lostandfound/supabase.dart';
import 'package:lostandfound/supabase_config.dart';
import 'package:lostandfound/detail_laporan.dart';
import 'package:lostandfound/formfound.dart';
import 'package:lostandfound/formlost.dart';
import 'package:lostandfound/listlost.dart';
import 'package:lostandfound/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabasePublishableKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lost & Found',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2563EB),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class GreetingCardHeader extends StatelessWidget {
  final String userName;
  final bool isAdmin;

  const GreetingCardHeader({
    super.key,
    required this.userName,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Selamat Pagi'
        : hour < 17
        ? 'Selamat Siang'
        : 'Selamat Malam';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, 👋',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFBFDBFE),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LaporanScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final String role;

  const LaporanScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.role,
  });

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  List<Map<String, dynamic>> listLaporan = [];
  bool isLoading = true;

  int _currentIndex = 0;
  int _userFilter = 0;
  int _statusFilter = 0;
  bool _showTipCard = true;
  bool get isAdmin => widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    fetchDataLaporan();
  }

  Future<void> fetchDataLaporan() async {
    try {
      final results = await Future.wait([
        supabase
            .from('reports')
            .select('id, user_id, category_id, type, status, matched_report_id, similarity, created_at')
            .order('id', ascending: false),
        supabase.from('users').select('id, name'),
        supabase.from('categories').select('id, name, code'),
        supabase
            .from('report_details')
            .select('report_id, field_key, field_label, field_value, is_public')
            .order('id'),
      ]);

      final reports = results[0] as List;
      final users = results[1] as List;
      final categories = results[2] as List;
      final allDetails = results[3] as List;

      final userMap = {for (var u in users) u['id']: u['name'] ?? 'Unknown'};
      final catMap = {
        for (var c in categories)
          c['id']: {'name': c['name'], 'code': c['code']}
      };

      final detailsByReport = <dynamic, List>{};
      for (var d in allDetails) {
        detailsByReport.putIfAbsent(d['report_id'], () => []);
        detailsByReport[d['report_id']]!.add(Map<String, dynamic>.from(d));
      }

      final reportMap = <dynamic, Map<String, dynamic>>{};
      for (var r in reports) {
        reportMap[r['id']] = Map<String, dynamic>.from(r);
      }

      setState(() {
        listLaporan = reports.map<Map<String, dynamic>>((item) {
          final rid = item['id'];
          final uid = item['user_id'];
          final cid = item['category_id'];
          final matchId = item['matched_report_id'];

          return Map<String, dynamic>.from({
            ...item,
            'user_name': userMap[uid] ?? 'Unknown',
            'category_name': catMap[cid]?['name'] ?? 'Unknown',
            'category_code': catMap[cid]?['code'] ?? '',
            'details': detailsByReport[rid] ?? [],
            'matched_report': matchId != null ? reportMap[matchId] : null,
          });
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  List<Map<String, dynamic>> get _filteredLost {
    var lost = listLaporan.where((item) => item['type'] == 'lost');
    if (_userFilter == 1) {
      lost = lost.where(
        (item) => item['user_id'].toString() == widget.userId.toString(),
      );
    }
    if (_statusFilter == 1) {
      lost = lost.where(
        (item) => item['status']?.toString().toLowerCase() != 'returned',
      );
    } else if (_statusFilter == 2) {
      lost = lost.where(
        (item) => item['status']?.toString().toLowerCase() == 'returned',
      );
    }
    final result = lost.toList();
    result.sort((a, b) {
      final aResolved = a['status']?.toString().toLowerCase() == 'returned';
      final bResolved = b['status']?.toString().toLowerCase() == 'returned';
      if (aResolved && !bResolved) return 1;
      if (!aResolved && bResolved) return -1;
      return 0;
    });
    return result;
  }

  List<Map<String, dynamic>> get _filteredFound {
    var found = listLaporan.where((item) => item['type'] == 'found');
    if (_userFilter == 1) {
      found = found.where(
        (item) => item['user_id'].toString() == widget.userId.toString(),
      );
    }
    if (_statusFilter == 1) {
      found = found.where(
        (item) => item['status']?.toString().toLowerCase() != 'returned',
      );
    } else if (_statusFilter == 2) {
      found = found.where(
        (item) => item['status']?.toString().toLowerCase() == 'returned',
      );
    }
    final result = found.toList();
    result.sort((a, b) {
      final aResolved = a['status']?.toString().toLowerCase() == 'returned';
      final bResolved = b['status']?.toString().toLowerCase() == 'returned';
      if (aResolved && !bResolved) return 1;
      if (!aResolved && bResolved) return -1;
      return 0;
    });
    return result;
  }

  void _navigateToDetail(Map<String, dynamic> item) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        pageBuilder: (context, animation, secondaryAnimation) =>
            DetailLaporanPage(
              data: item,
              isAdmin: isAdmin,
              userId: widget.userId,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _openReportForm() async {
    final String reportType = isAdmin && _currentIndex == 1 ? 'found' : 'lost';
    final bool? isSaved = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => reportType == 'lost'
            ? FormLostPage(userId: widget.userId)
            : FormFoundPage(userId: widget.userId),
      ),
    );

    if (isSaved == true) {
      fetchDataLaporan();
    }
  }

  bool _canManageReport(Map<String, dynamic> item) {
    if (isAdmin) return true;
    final int? ownerId = int.tryParse(item['user_id'].toString());
    return item['type'] == 'lost' && ownerId == widget.userId;
  }

  bool _canEditReport(Map<String, dynamic> item) {
    if (isAdmin) return false;
    final int? ownerId = int.tryParse(item['user_id'].toString());
    return item['type'] == 'lost' && ownerId == widget.userId;
  }

  Future<void> _openEditForm(Map<String, dynamic> item) async {
    final bool? isSaved = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportFormPage(
          type: item['type']?.toString() ?? 'lost',
          title: item['type'] == 'found'
              ? 'Edit Barang Ditemukan'
              : 'Edit Barang Hilang',
          userId: widget.userId,
          role: widget.role,
          report: item,
        ),
      ),
    );

    if (isSaved == true) {
      fetchDataLaporan();
    }
  }

  Future<void> _deleteReport(Map<String, dynamic> item) async {
    final bool? isConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 10),
            Text('Hapus laporan?', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: const Text(
          'Laporan yang dihapus tidak bisa dikembalikan.',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Hapus'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );

    if (isConfirmed != true) return;

    try {
      await supabase
          .from('reports')
          .update({'matched_report_id': null, 'similarity': null})
          .eq('matched_report_id', item['id']);
      await supabase.from('report_details').delete().eq('report_id', item['id']);
      await supabase.from('reports').delete().eq('id', item['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Laporan berhasil dihapus')));
      fetchDataLaporan();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  Future<void> _resolveReport(Map<String, dynamic> item) async {
    final bool? isConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 10),
            Text('Tandai Selesai?', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: const Text(
          'Laporan ini akan ditandai sebagai selesai (barang sudah dikembalikan).',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Selesai'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );

    if (isConfirmed != true) return;
    if (!mounted) return;

    try {
      await supabase
          .from('reports')
          .update({'status': 'returned'})
          .eq('id', item['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan ditandai selesai'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      fetchDataLaporan();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  Future<void> _logout() async {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _openReportFormFromEmpty() {
    _openReportForm();
  }

  Widget _buildShimmer() {
    return _ShimmerLoading();
  }

  Widget _buildEmptyState({required bool isLost}) {
    final bool isLostTab = isLost;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isLostTab
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isLostTab ? Icons.search_off_rounded : Icons.inventory_2_outlined,
                size: 36,
                color: isLostTab ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isLostTab ? 'Belum ada laporan hilang' : 'Belum ada barang ditemukan',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isLostTab
                  ? 'Laporkan barang hilangmu dengan menekan tombol +'
                  : 'Admin dapat menambahkan barang temuan',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _openReportFormFromEmpty,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(isLostTab ? 'Lapor Barang Hilang' : 'Tambah Barang Ditemukan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLostTab = _currentIndex == 0;
    final List<Map<String, dynamic>> displayedItems =
        isLostTab ? _filteredLost : _filteredFound;
    final bool isEmpty = displayedItems.isEmpty && !isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                title: const Text(
                  'Lost & Found',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Color(0xFF1E293B),
                  ),
                ),
                centerTitle: false,
                backgroundColor: const Color(0xFFF8FAFC),
                scrolledUnderElevation: 0,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Muat ulang',
                    onPressed: fetchDataLaporan,
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    tooltip: 'Keluar',
                    onPressed: _logout,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GreetingCardHeader(
                      userName: widget.userName,
                      isAdmin: isAdmin,
                    ),
                    if (!isAdmin && !isLoading && _showTipCard)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Tekan + untuk lapor barang hilang',
                                style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _showTipCard = false),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'Semua',
                            selected: _statusFilter == 0,
                            isRed: false,
                            onTap: () => setState(() => _statusFilter = 0),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: isLostTab ? 'Hilang' : 'Ditemukan',
                            selected: _statusFilter == 1,
                            isRed: false,
                            onTap: () => setState(() => _statusFilter = 1),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Aman',
                            selected: _statusFilter == 2,
                            isRed: false,
                            onTap: () => setState(() => _statusFilter = 2),
                          ),
                          if (isAdmin || isLostTab) const Spacer(),
                          if (isAdmin || isLostTab)
                            _buildFilterChip(
                              label: 'Saya',
                            selected: _userFilter == 1,
                            isRed: false,
                            activeColor: const Color(0xFF8B5CF6),
                            onTap: () => setState(
                              () => _userFilter = _userFilter == 1 ? 0 : 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
          body: isLoading
              ? _buildShimmer()
              : isEmpty
              ? _buildEmptyState(isLost: isLostTab)
              : RefreshIndicator(
                  onRefresh: fetchDataLaporan,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: displayedItems.length,
                    itemBuilder: (ctx, index) {
                      final item = displayedItems[index];
                      final bool isOwner =
                          isAdmin || item['user_id'].toString() == widget.userId.toString();
                      return ItemLaporanCard(
                        data: item,
                        isAdmin: isAdmin,
                        isOwner: isOwner,
                        canManage: _canManageReport(item),
                        onTap: () => _navigateToDetail(item),
                        onEdit: _canEditReport(item)
                            ? () => _openEditForm(item)
                            : null,
                        onDelete: _canManageReport(item)
                            ? () => _deleteReport(item)
                            : null,
                        onResolve: _canManageReport(item)
                            ? () => _resolveReport(item)
                            : null,
                      );
                    },
                  ),
                ),
        ),
      ),
      floatingActionButton: (isAdmin || _currentIndex == 0)
          ? FloatingActionButton(
              onPressed: _openReportForm,
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      bottomNavigationBar: Material(
        elevation: 8,
        shadowColor: Colors.black26,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _BottomNavItem(
                  icon: Icons.search_rounded,
                  label: 'Hilang',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _BottomNavItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Ditemukan',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required bool isRed,
    required VoidCallback onTap,
    Color activeColor = const Color(0xFF2563EB),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? activeColor : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? activeColor : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}
