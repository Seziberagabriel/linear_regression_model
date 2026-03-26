import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const UndernourishmentApp());
}

class UndernourishmentApp extends StatelessWidget {
  const UndernourishmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Undernourishment Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1A3A5C),
        useMaterial3: true,
      ),
      home: const PredictionPage(),
    );
  }
}

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  static const String _apiBase = 'https://undernourishment-api.onrender.com';

  final _formKey    = GlobalKey<FormState>();
  final _entityCtrl = TextEditingController();
  final _yearCtrl   = TextEditingController();

  bool   _loading = false;
  String _result  = '';
  bool   _isError = false;

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _result = ''; _isError = false; });

    try {
      final response = await http.post(
        Uri.parse('$_apiBase/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'entity_code': int.parse(_entityCtrl.text.trim()),
          'year':        int.parse(_yearCtrl.text.trim()),
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result  = 'Predicted Undernourishment:\n${data['predicted_undernourishment_pct']}%';
          _isError = false;
        });
      } else {
        final detail = jsonDecode(response.body)['detail'] ?? 'Unknown error';
        setState(() { _result = '⚠️ Error ${response.statusCode}: $detail'; _isError = true; });
      }
    } catch (e) {
      setState(() { _result = '❌ Network error: $e'; _isError = true; });
    } finally {
      setState(() => _loading = false);
    }
  }

  String? _validateEntity(String? v) {
    if (v == null || v.trim().isEmpty) return '⚠️ Entity code is required';
    final n = int.tryParse(v.trim());
    if (n == null) return '⚠️ Must be a whole number';
    if (n < 0 || n > 300) return '⚠️ Must be between 0 and 300';
    return null;
  }

  String? _validateYear(String? v) {
    if (v == null || v.trim().isEmpty) return '⚠️ Year is required';
    final n = int.tryParse(v.trim());
    if (n == null) return '⚠️ Must be a whole number';
    if (n < 2000 || n > 2030) return '⚠️ Must be between 2000 and 2030';
    return null;
  }

  @override
  void dispose() {
    _entityCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco({required String label, required String hint, required IconData icon}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1A3A5C)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                         borderSide: const BorderSide(color: Color(0xFFDDE3EA))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                         borderSide: const BorderSide(color: Color(0xFFDDE3EA))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                         borderSide: const BorderSide(color: Color(0xFF1A3A5C), width: 2)),
        errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                         borderSide: const BorderSide(color: Color(0xFFE53935), width: 2)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Column(
          children: [
            Text('🌍 Undernourishment Predictor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('FAO Global Data Model',
                style: TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Info card ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3A5C),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.public, color: Colors.white70, size: 36),
                    SizedBox(height: 10),
                    Text(
                      'Enter a country code and year to predict\nthe undernourishment prevalence (%)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Input section label ───────────────────────────────────────
              const Text('INPUT VARIABLES',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: Color(0xFF8A97A8), letterSpacing: 1.2)),
              const SizedBox(height: 12),

              // ── Entity code field ─────────────────────────────────────────
              TextFormField(
                controller: _entityCtrl,
                keyboardType: TextInputType.number,
                validator: _validateEntity,
                decoration: _inputDeco(
                  label: 'Country Code',
                  hint: 'Enter 0 – 300  (e.g. 12 for Algeria)',
                  icon: Icons.flag_outlined,
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text('Label-encoded integer from model training (0–300)',
                    style: TextStyle(fontSize: 11, color: Color(0xFF8A97A8))),
              ),

              const SizedBox(height: 20),

              // ── Year field ────────────────────────────────────────────────
              TextFormField(
                controller: _yearCtrl,
                keyboardType: TextInputType.number,
                validator: _validateYear,
                decoration: _inputDeco(
                  label: 'Year',
                  hint: 'Enter 2000 – 2030  (e.g. 2015)',
                  icon: Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text('Observation year between 2000 and 2030',
                    style: TextStyle(fontSize: 11, color: Color(0xFF8A97A8))),
              ),

              const SizedBox(height: 32),

              // ── Predict button ────────────────────────────────────────────
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _predict,
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Icon(Icons.analytics_outlined, size: 22),
                  label: Text(_loading ? 'Predicting...' : 'Predict',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE07B4F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Output display area ───────────────────────────────────────
              if (_result.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isError ? const Color(0xFFFFF0F0) : const Color(0xFFEAF6EC),
                    border: Border.all(
                      color: _isError ? const Color(0xFFE57373) : const Color(0xFF66BB6A),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _isError ? Icons.error_outline : Icons.check_circle_outline,
                        color: _isError ? const Color(0xFFE53935) : const Color(0xFF2E7D32),
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _result,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: _isError ? const Color(0xFFB71C1C) : const Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // ── Footer ────────────────────────────────────────────────────
              const Center(
                child: Text('Powered by Random Forest · FAO Dataset 2000–2024',
                    style: TextStyle(fontSize: 11, color: Color(0xFF8A97A8))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}