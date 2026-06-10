import 'package:flutter/material.dart';
import 'package:lostandfound/supabase.dart';
import 'package:lostandfound/similarity_helper.dart';

class DetailLaporanPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isAdmin;
  final int userId;

  const DetailLaporanPage({
    super.key,
    required this.data,
    this.isAdmin = false,
    this.userId = 0,
  });

  @override
  State<DetailLaporanPage> createState() => _DetailLaporanPageState();
}

class _DetailLaporanPageState extends State<DetailLaporanPage> {
  bool _isChecking = false;

  bool get _isOwner =>
      widget.data['user_id'].toString() == widget.userId.toString();

  Future<void> _checkSimilarity() async {
    setState(() => _isChecking = true);

    try {
      final reportId = widget.data['id'] as int;
      final type = widget.data['type']?.toString() ?? 'lost';
      final targetType = type == 'lost' ? 'found' : 'lost';
      final categoryId = widget.data['category_id'] as int;

      final myDetails = widget.data['details'] as List? ?? [];
      final combinedSaya = gabungTeks(myDetails);
      if (combinedSaya.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Detail laporan kosong')));
        return;
      }

      final targetReports = await supabase
          .from('reports')
          .select('id')
          .eq('type', targetType)
          .eq('category_id', categoryId)
          .neq('status', 'returned')
          .neq('id', reportId);

      if ((targetReports as List).isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Belum ditemukan kecocokan'),
            backgroundColor: Color(0xFF64748B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      final targetIds = targetReports.map((r) => r['id'] as int).toList();

      final allDetails = await supabase
          .from('report_details')
          .select('report_id, field_value')
          .filter('report_id', 'in', '(${targetIds.join(',')})')
          .order('id');

      final detailsByReport = <int, List<dynamic>>{};
      for (var d in allDetails) {
        detailsByReport.putIfAbsent(d['report_id'] as int, () => []);
        detailsByReport[d['report_id'] as int]!.add(d);
      }

      final usersResp = await supabase.from('users').select('id, name');
      final userMap = {for (var u in usersResp) u['id']: u['name']};

      final catsResp = await supabase.from('categories').select('id, name');
      final catMap = {for (var c in catsResp) c['id']: c['name']};

      final List<Map<String, dynamic>> matches = [];
      for (final tid in targetIds) {
        final fd = detailsByReport[tid] ?? [];
        final combinedTarget = gabungTeks(fd);
        if (combinedTarget.isEmpty) continue;

        final kemiripan = hitungKemiripan(combinedSaya, combinedTarget);
        if (kemiripan >= 70) {
          final targetReport = targetReports.firstWhere(
            (r) => r['id'] == tid,
            orElse: () => {},
          );

          matches.add({
            'id_matched': tid,
            'kemiripan': '${kemiripan.toStringAsFixed(1)}%',
            'category_name': catMap[categoryId] ?? '-',
            'user_name': userMap[targetReport['user_id']] ?? '-',
            'created_at': targetReport['created_at']?.toString() ?? '',
          });
        }
      }

      matches.sort((a, b) {
        final va =
            double.tryParse(
              a['kemiripan']!.replaceAll(RegExp(r'[^0-9.]'), ''),
            ) ??
            0;
        final vb =
            double.tryParse(
              b['kemiripan']!.replaceAll(RegExp(r'[^0-9.]'), ''),
            ) ??
            0;
        return vb.compareTo(va);
      });

      if (!mounted) return;

      if (matches.isNotEmpty) {
        final topPercent =
            double.tryParse(
              matches[0]['kemiripan']!.replaceAll(RegExp(r'[^0-9.]'), ''),
            ) ??
            0;
        if (topPercent >= 80) {
          final bestMatchId = matches[0]['id_matched'] as int;
          await supabase
              .from('reports')
              .update({
                'matched_report_id': bestMatchId,
                'similarity': matches[0]['kemiripan'],
              })
              .eq('id', reportId);
          await supabase
              .from('reports')
              .update({
                'matched_report_id': reportId,
                'similarity': matches[0]['kemiripan'],
              })
              .eq('id', bestMatchId);
        }
        _showMatchDialog(matches, targetType);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Belum ditemukan kecocokan'),
            backgroundColor: Color(0xFF64748B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _showMatchDialog(List matches, String targetType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, size: 20, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            const Text(
              'Kecocokan Ditemukan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final item = matches[index];
              final sim = item['kemiripan']?.toString() ?? '0%';
              final simVal =
                  double.tryParse(sim.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
              final color = simVal >= 85
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B);
              final catName = item['category_name'] ?? '-';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 18, color: color),
                        const SizedBox(width: 8),
                        Text(
                          catName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sim,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 6),
                        const SizedBox(width: 16),
                        const SizedBox(width: 6),
                        Text(
                          item['created_at'] ?? '-',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Segera verifikasi ke Pos Satpam untuk mengambil barang.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF92400E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  IconData getIcon(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'hp':
      case 'handphone':
      case 'phone':
        return Icons.phone_android;
      case 'dompet':
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'kunci':
      case 'key':
        return Icons.vpn_key_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String judul =
        widget.data['category_name'] ?? widget.data['kategori'] ?? 'Barang';
    final String kodeKategori = widget.data['category_code'] ?? judul;
    final bool isLost = widget.data['type'] == 'lost';
    final bool isResolved =
        widget.data['status']?.toString().toLowerCase() == 'returned';
    final bool isHiddenFoundDetail = !isLost && !widget.isAdmin;
    final Color accentColor = isLost
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);
    final Color accentBg = isLost
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFF0FDF4);
    final String username =
        widget.data['username'] ?? widget.data['user_name'] ?? '-';
    final String tanggal =
        widget.data['tanggal'] ?? widget.data['created_at'] ?? '-';
    final String description =
        widget.data['deskripsi'] ?? widget.data['description'] ?? '';
    final List details = widget.data['details'] is List
        ? widget.data['details']
        : [];
    final String? similarityRaw = widget.data['similarity']?.toString();
    final double? similarityValue = similarityRaw != null
        ? double.tryParse(similarityRaw.replaceAll(RegExp(r'[^0-9.]'), ''))
        : null;
    final Map<String, dynamic>? matchedReport =
        widget.data['matched_report'] is Map
        ? Map<String, dynamic>.from(widget.data['matched_report'])
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFEEF2FF)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Hero(
                  tag: 'report_icon_${widget.data['id']}',
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: accentBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      getIcon(kodeKategori),
                      color: accentColor,
                      size: 48,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Text(
                      judul,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        if (similarityValue != null && similarityValue >= 70)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: similarityValue >= 85
                                  ? const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.1)
                                  : const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: similarityValue >= 85
                                    ? const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.3)
                                    : const Color(
                                        0xFFF59E0B,
                                      ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 14,
                                  color: similarityValue >= 85
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$similarityRaw match',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: similarityValue >= 85
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isResolved
                                ? const Color(0xFFF0FDF4)
                                : accentBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isResolved
                                  ? const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.3)
                                  : accentColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            isResolved
                                ? 'SELESAI'
                                : isLost
                                ? 'HILANG'
                                : 'DITEMUKAN',
                            style: TextStyle(
                              color: isResolved
                                  ? const Color(0xFF10B981)
                                  : accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isOwner && (isLost || !widget.isAdmin)) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isChecking ? null : _checkSimilarity,
                    icon: _isChecking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2563EB),
                            ),
                          )
                        : const Icon(Icons.search_rounded, size: 18),
                    label: Text(
                      _isChecking ? 'Memeriksa kecocokan...' : 'Cek Kecocokan',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (isHiddenFoundDetail) ...[
                _buildSectionCard(
                  title: 'Detail Barang',
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Deskripsi disembunyikan.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Silakan datang ke Pos Satpam untuk informasi lebih lanjut.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF92400E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ] else ...[
                if (details.isNotEmpty) ...[
                  _buildSectionCard(
                    title: 'Detail Barang',
                    children: details.whereType<Map>().map((d) {
                      final label = d['field_label'] ?? d['field_key'] ?? '';
                      final value = d['field_value'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (label.toString().isNotEmpty)
                              SizedBox(
                                width: 100,
                                child: Text(
                                  label.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                value.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (description.isNotEmpty) ...[
                  _buildSectionCard(
                    title: 'Deskripsi',
                    children: [
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ],
              _buildSectionCard(
                title: 'Informasi Pelapor',
                children: [
                  _infoRow(Icons.person_outline, username),
                  const SizedBox(height: 6),
                  _infoRow(Icons.access_time_rounded, tanggal),
                ],
              ),
              if (matchedReport != null) ...[
                const SizedBox(height: 12),
                _buildSectionCard(
                  title: 'Barang yang Cocok',
                  children: [
                    _infoRow(
                      Icons.category_rounded,
                      matchedReport['category_name'] ?? '-',
                    ),
                    const SizedBox(height: 6),
                    _infoRow(
                      Icons.info_outline_rounded,
                      matchedReport['type'] == 'found'
                          ? 'Barang Ditemukan'
                          : 'Barang Hilang',
                    ),
                    const SizedBox(height: 6),
                    _infoRow(
                      Icons.person_outline,
                      matchedReport['user_name'] ?? '-',
                    ),
                    const SizedBox(height: 6),
                    _infoRow(
                      Icons.access_time_rounded,
                      matchedReport['created_at'] ?? '-',
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Kemiripan: ${widget.data['similarity'] ?? '-'}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: (() {
                              final sim =
                                  double.tryParse(
                                    (widget.data['similarity'] ?? '0')
                                        .toString()
                                        .replaceAll(RegExp(r'[^0-9.]'), ''),
                                  ) ??
                                  0;
                              return sim >= 85
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B);
                            })(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Segera verifikasi ke Lost and Found di Pos Satpam untuk memastikan kecocokan barang.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF92400E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
      ],
    );
  }
}
