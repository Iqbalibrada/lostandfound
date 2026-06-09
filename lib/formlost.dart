import 'package:flutter/material.dart';
import 'package:lostandfound/supabase.dart';
import 'package:lostandfound/similarity_helper.dart';

class FormLostPage extends StatelessWidget {
  final int userId;

  const FormLostPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ReportFormPage(
      type: 'lost',
      title: 'Lapor Barang Hilang',
      userId: userId,
    );
  }
}

class ReportFormPage extends StatefulWidget {
  final String type;
  final String title;
  final int userId;
  final String role;
  final Map<String, dynamic>? report;

  const ReportFormPage({
    super.key,
    required this.type,
    required this.title,
    required this.userId,
    this.role = 'user',
    this.report,
  });

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage>
    with SingleTickerProviderStateMixin {
  final Map<String, TextEditingController> _controllers = {};
  String _selectedCode = 'wallet';

  final List<Map<String, dynamic>> _categories = [
    {
      'code': 'wallet',
      'name': 'Dompet',
      'icon': Icons.account_balance_wallet_outlined,
      'fields': [
        {'key': 'warna', 'label': 'Warna dompet', 'type': 'text'},
        {'key': 'bahan', 'label': 'Bahan', 'type': 'text'},
        {'key': 'ciri', 'label': 'Ciri khusus', 'type': 'textarea'},
      ],
    },
    {
      'code': 'key',
      'name': 'Kunci',
      'icon': Icons.key,
      'fields': [
        {'key': 'merk_motor', 'label': 'Merk motor', 'type': 'text'},
        {'key': 'tipe_motor', 'label': 'Tipe motor', 'type': 'text'},
        {'key': 'gantungan', 'label': 'Gantungan kunci', 'type': 'text'},
      ],
    },
    {
      'code': 'phone',
      'name': 'Handphone',
      'icon': Icons.phone_android,
      'fields': [
        {'key': 'merk', 'label': 'Merk handphone', 'type': 'text'},
        {'key': 'tipe', 'label': 'Tipe handphone', 'type': 'text'},
        {'key': 'warna', 'label': 'Warna', 'type': 'text'},
      ],
    },
  ];

  Map<String, dynamic> get _selectedCategory {
    return _categories.firstWhere((item) => item['code'] == _selectedCode);
  }

  bool get _isEdit => widget.report != null;

  List<Map<String, String>> get _selectedFields {
    return (_selectedCategory['fields'] as List)
        .map((field) => Map<String, String>.from(field))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final report = widget.report;
    if (report == null) return;

    final categoryCode = report['category_code']?.toString();
    final bool hasCategory = _categories.any(
      (category) => category['code'] == categoryCode,
    );
    if (hasCategory) _selectedCode = categoryCode!;

    _loadReportDetails();
  }

  Future<void> _loadReportDetails() async {
    try {
      final reportId = widget.report!['id'];
      final response = await supabase
          .from('report_details')
          .select('field_key, field_label, field_value')
          .eq('report_id', reportId)
          .order('id');

      for (final detail in (response as List).cast<Map<String, dynamic>>()) {
        _controllerFor(detail['field_key']!.toString()).text =
            detail['field_value']?.toString() ?? '';
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String key) {
    return _controllers.putIfAbsent(key, () => TextEditingController());
  }

  Future<void> _submitReport() async {
    final details = _selectedFields.map((field) {
      return {
        'field_key': field['key'] ?? '',
        'field_label': field['label'] ?? '',
        'field_value': _controllerFor(field['key']!).text,
      };
    }).toList();

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );

      final catResponse = await supabase
          .from('categories')
          .select('id')
          .eq('code', _selectedCode)
          .single();
      final categoryId = catResponse['id'];

      if (_isEdit) {
        final reportId = widget.report!['id'];
        await supabase
            .from('reports')
            .update({
              'category_id': categoryId,
              'type': widget.type,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', reportId);

        await supabase
            .from('report_details')
            .delete()
            .eq('report_id', reportId);
        for (final detail in details) {
          await supabase.from('report_details').insert({
            'report_id': reportId,
            'field_key': detail['field_key'],
            'field_label': detail['field_label'],
            'field_value': detail['field_value'],
            'is_public': 1,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      } else {
        final insertResponse = await supabase
            .from('reports')
            .insert({
              'user_id': widget.userId,
              'category_id': categoryId,
              'type': widget.type,
              'status': 'open',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select('id')
            .single();

        final reportId = insertResponse['id'];

        for (final detail in details) {
          await supabase.from('report_details').insert({
            'report_id': reportId,
            'field_key': detail['field_key'],
            'field_label': detail['field_label'],
            'field_value': detail['field_value'],
            'is_public': 1,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }

        if (widget.type == 'lost') {
          final matches = await _cekSimilarityLocal(
            reportId,
            categoryId,
            details,
          );

          if (!mounted) return;
          if (context.mounted) Navigator.pop(context);

          if (matches.isNotEmpty) {
            _showMatchDialog(matches);
            return;
          }
          _showSuccessAnimation();
          return;
        }
      }

      if (!mounted) return;
      if (context.mounted) Navigator.pop(context);
      _showSuccessAnimation();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  Future<List<Map<String, dynamic>>> _cekSimilarityLocal(
    int reportId,
    int categoryId,
    List<Map<String, String>> details,
  ) async {
    final combinedBaru = gabungTeks(details.map((d) => d).toList());
    if (combinedBaru.isEmpty) return [];

    final foundReports = await supabase
        .from('reports')
        .select('id')
        .eq('type', 'found')
        .eq('category_id', categoryId)
        .neq('status', 'returned')
        .neq('id', reportId);

    if (foundReports.isEmpty) return [];

    final foundIds = foundReports.map((r) => r['id'] as int).toList();

    final allDetails = await supabase
        .from('report_details')
        .select('report_id, field_key, field_label, field_value')
        .filter('report_id', 'in', '(${foundIds.join(',')})')
        .order('id');

    final detailsByReport = <int, List<Map<String, dynamic>>>{};
    for (var d in allDetails) {
      final rid = d['report_id'] as int;
      detailsByReport.putIfAbsent(rid, () => []);
      detailsByReport[rid]!.add(Map<String, dynamic>.from(d));
    }

    final List<Map<String, dynamic>> hasil = [];
    for (final rid in foundIds) {
      final fd = detailsByReport[rid] ?? [];
      final combinedFound = gabungTeks(fd);
      if (combinedFound.isEmpty) continue;

      final kemiripan = hitungKemiripan(combinedBaru, combinedFound);
      if (kemiripan >= 70) {
        hasil.add({
          'id_matched': rid,
          'kemiripan': '${kemiripan.toStringAsFixed(1)}%',
        });
      }
    }

    hasil.sort((a, b) {
      final va =
          double.tryParse(a['kemiripan']!.replaceAll(RegExp(r'[^0-9.]'), '')) ??
          0;
      final vb =
          double.tryParse(b['kemiripan']!.replaceAll(RegExp(r'[^0-9.]'), '')) ??
          0;
      return vb.compareTo(va);
    });

    if (hasil.isNotEmpty) {
      final topMatchPercent =
          double.tryParse(
            hasil[0]['kemiripan']!.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0;
      if (topMatchPercent >= 80) {
        final matchedId = hasil[0]['id_matched'];
        final simStr = hasil[0]['kemiripan'];
        await supabase
            .from('reports')
            .update({'matched_report_id': matchedId, 'similarity': simStr})
            .eq('id', reportId);
        await supabase
            .from('reports')
            .update({'matched_report_id': reportId, 'similarity': simStr})
            .eq('id', matchedId);
      }
    }

    return hasil;
  }

  Future<void> _showSuccessAnimation() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => _SuccessDialog(),
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _showMatchDialog(List<Map<String, dynamic>> matches) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFEF3C7), Color(0xFFFFF7ED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Color(0xFFD97706),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Barang Mirip Ditemukan!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Similarity Checker mendeteksi kecocokan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFA16207),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sistem mendeteksi laporan barang ditemukan dengan deskripsi yang mirip. Untuk keamanan, detail pemilik tidak ditampilkan.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...matches.map((item) {
                      final similarity = item['kemiripan']?.toString() ?? '90%';
                      final similarityValue =
                          double.tryParse(
                            similarity.replaceAll(RegExp(r'[^0-9.]'), ''),
                          ) ??
                          0;
                      if (similarityValue < 70) return const SizedBox.shrink();
                      final Color simColor = similarityValue >= 85
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: simColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                color: simColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kemiripan $similarity',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: simColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Verifikasi ke Pos Satpam untuk informasi lebih lanjut',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(this.context, true);
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Mengerti',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 17)),
            if (_isEdit)
              const Text(
                'Mode Edit',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFF59E0B),
                ),
              ),
          ],
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                const Text(
                  'Pilih Kategori Barang',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                if (_isEdit)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'EDITING',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD97706),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: _categories.map((category) {
                final bool isSelected = category['code'] == _selectedCode;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCode = category['code']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEFF6FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              category['icon'] as IconData,
                              size: 28,
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              category['name'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            ..._selectedFields.asMap().entries.map((entry) {
              final int index = entry.key;
              final field = entry.value;
              final bool isTextarea = field['type'] == 'textarea';
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < _selectedFields.length - 1 ? 16 : 0,
                ),
                child: TextField(
                  controller: _controllerFor(field['key']!),
                  minLines: isTextarea ? 4 : 1,
                  maxLines: isTextarea ? 5 : 1,
                  decoration: InputDecoration(
                    labelText: field['label'],
                    hintText: 'Masukkan ${field['label']?.toLowerCase()}',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _submitReport,
            icon: Icon(
              _isEdit ? Icons.save_rounded : Icons.send_rounded,
              size: 18,
            ),
            label: Text(
              _isEdit
                  ? 'Simpan Perubahan'
                  : widget.type == 'lost'
                  ? 'Kirim Laporan Hilang'
                  : 'Kirim Laporan Ditemukan',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatefulWidget {
  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            width: 220,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 48,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Laporan Terkirim!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Barang akan segera diproses',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
