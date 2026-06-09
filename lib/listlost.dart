import 'package:flutter/material.dart';

class ItemLaporanCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool canManage;
  final bool isAdmin;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onResolve;
  final VoidCallback? onTap;

  const ItemLaporanCard({
    super.key,
    required this.data,
    this.canManage = false,
    this.isAdmin = false,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
    this.onResolve,
    this.onTap,
  });

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
    final String judul = data['category_name'] ?? data['kategori'] ?? 'Barang';
    final String kodeKategori = data['category_code'] ?? judul;
    final List details = data['details'] is List ? data['details'] : [];
    final List<String> detailRows = details
        .whereType<Map>()
        .map((detail) {
          final label = detail['field_label'] ?? detail['field_key'] ?? '';
          final value = detail['field_value'] ?? '';
          return label.toString().isEmpty ? value.toString() : '$label: $value';
        })
        .where((text) => text.trim().isNotEmpty)
        .take(3)
        .toList();
    final bool isHiddenFoundDetail =
        data['type'] == 'found' && !isAdmin;
    final String baris1 =
        data['detail_1'] ??
        (isHiddenFoundDetail
            ? 'Deskripsi disembunyikan.'
            : detailRows.isNotEmpty
            ? detailRows[0]
            : '');
    final String baris2 =
        data['detail_2'] ??
        (isHiddenFoundDetail
            ? 'Silakan datang ke bagian Lost and Found.'
            : detailRows.length > 1
            ? detailRows[1]
            : '');
    final String baris3 =
        data['detail_3'] ?? (detailRows.length > 2 ? detailRows[2] : '');
    baris3.toString(); // unused reference placeholder
    final String username = data['username'] ?? data['user_name'] ?? '-';
    final String tanggal = data['tanggal'] ?? data['created_at'] ?? '-';

    final bool isLost = data['type'] == 'lost';
    final bool isResolved =
        data['status']?.toString().toLowerCase() == 'returned';
    final Color accentBg = isLost
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFF0FDF4);

    final String? similarityRaw = data['similarity']?.toString();
    final double? similarityValue = similarityRaw != null
        ? double.tryParse(similarityRaw.replaceAll(RegExp(r'[^0-9.]'), ''))
        : null;

    final Color topAccent = isResolved
        ? const Color(0xFF10B981)
        : isLost
        ? const Color(0xFFEF4444)
        : const Color(0xFF2563EB);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shadowColor: topAccent.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 4, color: topAccent),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hero(
                        tag: 'report_icon_${data['id']}',
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isResolved
                                ? const Color(0xFFF0FDF4)
                                : accentBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: topAccent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            getIcon(kodeKategori),
                            color: topAccent,
                            size: 26,
                          ),
                        ),
                      ),
                      if (isOwner && similarityValue != null && similarityValue >= 70)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: similarityValue >= 85
                                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                  : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: similarityValue >= 85
                                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                    : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 9,
                                  color: similarityValue >= 85
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '$similarityRaw',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: similarityValue >= 85
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.only(top: similarityValue != null && similarityValue >= 70 ? 4 : 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isResolved
                                ? const Color(0xFFF0FDF4)
                                : accentBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isResolved
                                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                  : topAccent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            isResolved
                                ? 'AMAN'
                                : isLost
                                ? 'HILANG'
                                : 'DITEMUKAN',
                            style: TextStyle(
                              color: isResolved
                                  ? const Color(0xFF10B981)
                                  : topAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          judul,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (baris1.isNotEmpty)
                          Text(
                            baris1,
                            style: TextStyle(
                              fontSize: 13,
                              color: isHiddenFoundDetail
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF475569),
                              fontStyle: isHiddenFoundDetail
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (baris2.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              baris2,
                              style: TextStyle(
                                fontSize: 13,
                                color: isHiddenFoundDetail
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF475569),
                                fontStyle: isHiddenFoundDetail
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              isAdmin
                                  ? Icons.person
                                  : Icons.person_outline,
                              size: 12,
                              color: isAdmin
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                username,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isAdmin
                                      ? const Color(0xFF475569)
                                      : const Color(0xFF94A3B8),
                                  fontWeight: isAdmin
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                tanggal,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (canManage)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                                onTap: onEdit,
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFE2E8F0),
                              ),
                              InkWell(
                                onTap: onDelete,
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                              if (!isResolved && onResolve != null) ...[
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Color(0xFFE2E8F0),
                                ),
                                InkWell(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(10),
                                    bottomRight: Radius.circular(10),
                                  ),
                                  onTap: onResolve,
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.check_circle_outline,
                                      size: 18,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
