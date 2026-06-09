import 'package:flutter/material.dart';
import 'package:lostandfound/formlost.dart';

class FormFoundPage extends StatelessWidget {
  final int userId;

  const FormFoundPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ReportFormPage(
      type: 'found',
      title: 'Lapor Barang Ditemukan',
      userId: userId,
    );
  }
}
