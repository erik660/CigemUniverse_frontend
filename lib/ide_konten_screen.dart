import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'backend_config.dart';
import 'profile_screen.dart';
import 'services/history_service.dart';

class DropdownItem {
  final String title;
  final String description;
  final String? category;
  DropdownItem({
    required this.title,
    required this.description,
    this.category,
  });
}

class IdeKontenScreen extends StatefulWidget {
  const IdeKontenScreen({super.key});
  @override
  State<IdeKontenScreen> createState() => _IdeKontenScreenState();
}

class _IdeKontenScreenState extends State<IdeKontenScreen> {
  final Color cigemGreen = const Color(0xFF3EB49F);
  final Color bgLight = const Color(0xFFF9FAFB);
  final Color textDark = const Color(0xFF1E1E1E);
  final Color textGrey = const Color(0xFF6B7280);
  String? selectedAset;
  String? selectedGaya;
  String? _expandedCategory;
  String _username = '';
  bool isLoading = false;
  String generatedIdea = '';
  List<dynamic> hasilRanking = [];
  final ScrollController _scrollController = ScrollController();

  // Local in-memory cache for generated ideas to speed up repeated requests
  final Map<String, Map<String, dynamic>> _ideaCache = {};
  final Duration _cacheTTL = const Duration(hours: 6);
  final Set<String> _pendingRequests = {};

  Future<void> _loadUsername() async {
    final username = await HistoryService.getUsername();
    setState(() {
      _username = username ?? 'User';
    });
  }

  @override
  void initState() {
    super.initState();
    HttpOverrides.global = _MyHttpOverrides();
    _loadUsername();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      selectedAset = null;
      selectedGaya = null;
      _expandedCategory = null;
      generatedIdea = '';
      hasilRanking = [];
    });
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Pilihan telah dikosongkan.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  bool _handleAsetChanged(String? val) {
    if (val == null) {
      setState(() {
        selectedAset = null;
        _expandedCategory = null;
      });
      return true;
    }

    if (selectedGaya != null && !_isValidCombination(val, selectedGaya!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Aset/mesin "$val" tidak cocok dengan gaya "$selectedGaya". Pilih Journey PO / BTS atau Portofolio.'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red.shade700,
        ),
      );
      setState(() {
        _expandedCategory = 'Pilih Aset/Bahan';
      });
      return false;
    }

    setState(() {
      selectedAset = val;
      _expandedCategory = null;
    });
    return true;
  }

  bool _handleGayaChanged(String? val) {
    if (val == null) {
      setState(() {
        selectedGaya = null;
        _expandedCategory = null;
      });
      return true;
    }

    if (selectedAset != null && !_isValidCombination(selectedAset!, val)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Gaya konten "$val" tidak cocok dengan alat/mesin "$selectedAset". Pilih Journey PO / BTS atau Portofolio.'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red.shade700,
        ),
      );
      setState(() {
        _expandedCategory = 'Gaya Konten';
      });
      return false;
    }

    setState(() {
      selectedGaya = val;
      _expandedCategory = null;
    });
    return true;
  }

  bool _isValidCombination(String aset, String gaya) {
    return true; // Klien minta dibebaskan untuk semua kombinasi
  }

  String _buildContextualPrompt(String aset, String gaya) {
    final bool isAlatMesin = ['mesin', 'alat', 'printer', 'meja', 'obras', 'kam', 'bis', 'potong'].any((w) => aset.toLowerCase().contains(w));
    
    String prompt = 'Kamu adalah Social Media Manager Gen-Z yang bekerja di "Cigem Creative", sebuah vendor konveksi/garment pembuat kaos, jaket, dan seragam custom berkualitas. '
                    'Tugasmu HANYA SATU: membuat 1 ide konten TikTok/Instagram Reels yang BENAR-BENAR FOKUS 100% pada gaya "$gaya" dengan melibatkan aset "$aset". JANGAN MENCAMPURADUKKAN GAYA! Jika komedi, harus full komedi bikin ngakak. Jika portofolio, harus full pamer hasil.\n\n'
                    'ATURAN MUTLAK:\n'
                    '1. BAHASA: WAJIB 100% BAHASA INDONESIA GAUL & ASYIK (Gen Z, santai, ala FYP TikTok). DILARANG KERAS menggunakan kalimat bahasa Inggris (kecuali istilah teknis/medsos) atau bahasa baku yang kaku!\n'
                    '2. PEDOMAN GAYA KONTEN ("$gaya") HARUS DIEKSEKUSI TOTALITAS MAKSIMAL:\n'
                    '   - Jika gaya adalah KOMEDI / TREN: KONTEN INI HARUS BIKIN NGAKAK! Jangan ada unsur jualan kaku. Buat skrip POV drama anak konveksi, komedi receh, meme absurd kekinian, atau tingkah kocak dengan "$aset". (Misal: "POV: Ketika Owner disuruh motong bahan tapi malah ketiduran di meja"). Harus murni komedi!\n'
                    '   - Jika gaya adalah EDUKASI: JANGAN JUALAN & JANGAN CUMA PAMER PROSES! Harus murni berbagi ILMU (Knowledge Sharing). Bongkar rahasia/fakta teknis di balik "$aset" yang bikin penonton bilang "Oh gitu pantesan bajunya awet!". (Misal: "Banyak yang gatau, ini bedanya jahitan/bordiran yang gampang lepas sama yang tahan banting bertahun-tahun"). Edukasi secara detail tapi santai!\n'
                    '   - Jika gaya adalah PROMOSI / JUALAN: Hard selling tapi elegan ala TikTok. Bikin audiens FOMO parah dan kebelet order custom baju angkatan/komunitasnya sekarang juga gara-gara ngeliat kecanggihan "$aset" ini.\n'
                    '   - Jika gaya adalah JOURNEY PO / BTS: Fokus 100% ke estetika dan cerita *behind the scene*. Kasih script ASMR satisfying, time-lapse keren, atau vibe riweuh kejar deadline pesanan ribuan pcs dengan "$aset".\n'
                    '   - Jika gaya adalah PORTOFOLIO: Murni pamer hasil! Flexing hasil akhir jahitan/sablon yang super rapi, mewah, dan sempurna yang dihasilkan berkat "$aset". Jangan melawak di sini!\n';

    if (isAlatMesin) {
      prompt += '3. ATURAN KHUSUS MESIN: Audiens kita adalah CALON KLIEN (brand/kampus yang mau order baju), BUKAN teknisi! DILARANG KERAS membuat konten tutorial cara merawat, memperbaiki, atau menyalakan mesin!\n\n';
    } else {
      prompt += '3. FOKUS ASET: Tonjolkan bagaimana "$aset" menjadi rahasia utama di balik kualitas tinggi produk custom Cigem Creative!\n\n';
    }

    prompt += 'PENTING: Pastikan "hook" sangat memikat, "caption" santai dan engaging, serta "script" visual sangat detail seolah ini adegan video TikTok sungguhan!\n'
              'ATURAN FORMAT (SANGAT KRITIKAL): Kamu WAJIB mengembalikan output dalam format JSON OBJEK TUNGGAL. JANGAN PERNAH membungkusnya dalam array "ideas". Gunakan struktur key persis seperti ini: {"title": "...", "hook": "...", "caption": "...", "script": "...", "hashtags": ["...", "..."], "CTA": "..."}\n';

    return prompt;
  }

  Future<void> generateAndSaveIdea() async {
    if (selectedAset == null || selectedGaya == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih Aset dan Gaya Konten terlebih dahulu!')));
      return;
    }
    if (!_isValidCombination(selectedAset!, selectedGaya!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Kombinasi "$selectedAset" + "$selectedGaya" tidak relevan. Silakan pilih gaya lain yang lebih cocok.'),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    setState(() {
      isLoading = true;
      generatedIdea = '';
      hasilRanking = [];
    });

    final key = '${selectedAset!}|${selectedGaya!}';

    // Hapus sistem cache di frontend agar setiap klik selalu memanggil API backend (dynamic AI)

    try {
      final contextualPrompt = _buildContextualPrompt(selectedAset!, selectedGaya!);
      final url = Uri.parse('https://cigem-universe-backend.vercel.app/api/simpan_ide');
      final body = json.encode({
        'aset': selectedAset,
        'gaya': selectedGaya,
        'custom_prompt': contextualPrompt,
      });

      if (_pendingRequests.contains(key)) {
        setState(() { isLoading = false; });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permintaan sedang diproses — tunggu sebentar.'), duration: Duration(seconds: 2)));
        return;
      }
      _pendingRequests.add(key);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ideKontenRaw = data['ide_konten'];
        String ideKonten = '';
        if (ideKontenRaw is String) {
          ideKonten = ideKontenRaw;
        } else if (ideKontenRaw is Map && ideKontenRaw['ideas'] != null) {
          final List ideas = ideKontenRaw['ideas'];
          if (ideas.isNotEmpty) {
            final first = ideas[0];
            final title = first['title'] ?? '';
            final hook = first['hook'] ?? '';
            final caption = first['caption'] ?? '';
            final script = first['script'] ?? '';
            final hashtags = first['hashtags'] is List ? (first['hashtags'] as List).join(' ') : (first['hashtags'] ?? '');
            final cta = first['CTA'] ?? first['cta'] ?? '';
            
            ideKonten = "📌 Judul: $title\n\n"
                        "🎯 Hook (3 Detik Pertama):\n$hook\n\n"
                        "📝 Caption:\n$caption\n\n"
                        "🎬 Skrip / Alur Visual:\n$script\n\n"
                        "🏷️ Hashtags: $hashtags\n\n"
                        "👉 Call to Action (CTA):\n$cta";
          } else {
            ideKonten = ideKontenRaw.toString();
          }
        } else if (ideKontenRaw is Map) {
          final title = ideKontenRaw['title'] ?? '';
          final hook = ideKontenRaw['hook'] ?? '';
          final caption = ideKontenRaw['caption'] ?? '';
          final script = ideKontenRaw['script'] ?? '';
          final hashtags = ideKontenRaw['hashtags'] is List ? (ideKontenRaw['hashtags'] as List).join(' ') : (ideKontenRaw['hashtags'] ?? '');
          final cta = ideKontenRaw['CTA'] ?? ideKontenRaw['cta'] ?? '';
          if (title.toString().isNotEmpty || hook.toString().isNotEmpty || caption.toString().isNotEmpty) {
            ideKonten = "📌 Judul: $title\n\n"
                        "🎯 Hook (3 Detik Pertama):\n$hook\n\n"
                        "📝 Caption:\n$caption\n\n"
                        "🎬 Skrip / Alur Visual:\n$script\n\n"
                        "🏷️ Hashtags: $hashtags\n\n"
                        "👉 Call to Action (CTA):\n$cta";
          } else {
            ideKonten = ideKontenRaw.toString();
          }
        } else {
          ideKonten = ideKontenRaw.toString();
        }
        final ranking = data['ranking'];
        final DateTime now = DateTime.now();
        final String tanggal = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
        final String waktu = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        final IdeKontenItem item = IdeKontenItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          aset: selectedAset!,
          gaya: selectedGaya!,
          ideKonten: ideKonten,
          tanggal: tanggal,
          waktu: waktu,
          ranking: List<Map<String, dynamic>>.from(ranking ?? []),
        );
        await HistoryService.saveIdeKonten(item);
        // cache result
        try { _ideaCache[key] = {'ide_konten': ideKonten, 'ranking': ranking, 'timestamp': DateTime.now().toIso8601String()}; } catch (_) {}
        setState(() {
          generatedIdea = ideKonten;
          hasilRanking = ranking ?? [];
          isLoading = false;
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Ide konten tersimpan di riwayat!'), duration: Duration(seconds: 2)));
        _pendingRequests.remove(key);
      } else {
        final responseBody = response.body;
        final serverMessage = response.statusCode == 503 || responseBody.contains('high demand')
            ? 'Server AI sedang sibuk. Coba lagi beberapa saat.'
            : responseBody;
        throw Exception('Gagal menyimpan ke server (${response.statusCode}): $serverMessage');
      }
    } catch (e) {
      _pendingRequests.remove(key);
      setState(() { isLoading = false; });
      if (mounted) {
        String errorMsg = 'Error: $e';
        if (e.toString().contains('SocketException')) {
          errorMsg = '🔴 Tidak bisa koneksi ke server. Cek WiFi/data internet';
        } else if (e.toString().contains('TimeoutException')) {
          errorMsg = '⏱️ Server lambat - coba lagi (batas waktu 15 detik)';
        } else if (e.toString().contains('Failed host lookup')) {
          errorMsg = '🌐 Domain ngrok tidak valid';
        } else if (e.toString().contains('HandshakeException')) {
          errorMsg = '🔒 SSL Certificate Error - coba restart server';
        } else if (e.toString().contains('Connection refused')) {
          errorMsg = '🔴 Backend offline - pastikan ngrok masih berjalan';
        } else {
          errorMsg = '❌ Error: ${e.toString()}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  FaIconData getPlatformIcon(String namaPlatform) {
    switch (namaPlatform.toLowerCase()) {
      case 'tiktok': return FontAwesomeIcons.tiktok;
      case 'instagram reels': return FontAwesomeIcons.instagram;
      case 'facebook': return FontAwesomeIcons.facebook;
      case 'linkedin': return FontAwesomeIcons.linkedin;
      case 'youtube shorts': return FontAwesomeIcons.youtube;
      case 'threads': return FontAwesomeIcons.threads;
      default: return FontAwesomeIcons.link;
    }
  }

  Color getPlatformColor(String namaPlatform) {
    switch (namaPlatform.toLowerCase()) {
      case 'tiktok': return Colors.black;
      case 'instagram reels': return const Color(0xFFE1306C);
      case 'facebook': return const Color(0xFF1877F2);
      case 'linkedin': return const Color(0xFF0A66C2);
      case 'youtube shorts': return const Color(0xFFFF0000);
      case 'threads': return Colors.black87;
      default: return cigemGreen;
    }
  }

  final List<DropdownItem> listAset = [
    DropdownItem(category: 'ALAT & ASET', title: 'Mesin Bordir', description: 'Mesin produksi bordir pakaian'),
    DropdownItem(category: 'ALAT & ASET', title: 'Alat Potong Bahan', description: 'Pemotong kain/material produksi'),
    DropdownItem(category: 'ALAT & ASET', title: 'Printer Sublim', description: 'Mesin cetak sublimasi'),
    DropdownItem(category: 'ALAT & ASET', title: 'Mesin Press Sublim', description: 'Pemanas cetak sublim'),
    DropdownItem(category: 'ALAT & ASET', title: 'Mesin Press DTF', description: 'Pemanas cetak sablon DTF'),
    DropdownItem(category: 'ALAT & ASET', title: 'Meja Sablon', description: 'Area cetak sablon manual'),
    DropdownItem(category: 'ALAT & ASET', title: 'Mesin Jahit', description: 'Alat jahit utama'),
    DropdownItem(category: 'ALAT & ASET', title: 'Mesin Kam', description: 'Mesin pengatur jahitan'),
    DropdownItem(category: 'ALAT & ASET', title: 'Mesin Bis', description: 'Mesin jahit pinggir kain'),
    DropdownItem(category: 'ALAT & ASET', title: 'Mesin Obras', description: 'Mesin finishing tepi kain'),
    DropdownItem(category: 'BAHAN MATERIAL', title: 'Cotton Combed', description: 'Kain katun standar kaos distro'),
    DropdownItem(category: 'BAHAN MATERIAL', title: 'Cvc Pique', description: 'Bahan kain untuk kaos polo'),
    DropdownItem(category: 'BAHAN MATERIAL', title: 'Fleece', description: 'Bahan tebal untuk jaket/sweater'),
    DropdownItem(category: 'BAHAN MATERIAL', title: 'Drill', description: 'Kain tebal seragam PDH/PDL'),
    DropdownItem(category: 'BAHAN MATERIAL', title: 'Canvas', description: 'Kain kanvas untuk tas & aksesori'),
    DropdownItem(category: 'BAHAN MATERIAL', title: 'Tissue Lanyard', description: 'Bahan halus untuk tali lanyard'),
    DropdownItem(category: 'INDIVIDU & TIM', title: 'Owner', description: 'Pemilik & pengambil keputusan'),
    DropdownItem(category: 'INDIVIDU & TIM', title: 'Kepala Produksi', description: 'Supervisor divisi produksi'),
    DropdownItem(category: 'INDIVIDU & TIM', title: 'Admin', description: 'Administrasi & pelayanan chat'),
    DropdownItem(category: 'INDIVIDU & TIM', title: 'HRD/Finance', description: 'SDM & keuangan perusahaan'),
    DropdownItem(category: 'INDIVIDU & TIM', title: 'Team Lanyard & Idcard', description: 'Tim cetak lanyard & id card PVC'),
    DropdownItem(category: 'INDIVIDU & TIM', title: 'Team Jahit', description: 'Divisi penjahitan pola pakaian'),
    DropdownItem(category: 'INDIVIDU & TIM', title: 'Team Potong', description: 'Tim pemotongan & persiapan bahan'),
    DropdownItem(category: 'INDIVIDU & TIM', title: 'Team Finishing', description: 'Tim pengecekan QC & packing'),
    DropdownItem(category: 'INDIVIDU & TIM', title: 'Team Sablon', description: 'Tim sablon manual & digital'),
  ];

  final List<DropdownItem> listGaya = [
    DropdownItem(title: 'Edukasi', description: 'Tips / Info Teknis seputar bahan & produksi'),
    DropdownItem(title: 'Promosi / Jualan', description: 'Hard Selling untuk kejar konversi/order'),
    DropdownItem(title: 'Journey PO / BTS', description: 'Proses produksi dari awal sampai akhir'),
    DropdownItem(title: 'Komedi / Tren', description: 'Konten lucu / viral mengikuti tren medsos'),
    DropdownItem(title: 'Portofolio', description: 'Pamer hasil jadi pakaian / produk'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: cigemGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: cigemGreen.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Icon(Icons.person_rounded, color: cigemGreen, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${_username.isNotEmpty ? _username[0].toUpperCase() + _username.substring(1) : 'User'}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Siap ngonten hari ini?',
                        style: TextStyle(fontSize: 12, color: textGrey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ide Konten', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textDark)),
                    const SizedBox(height: 8),
                    Text(
                      'Kalo kamu kebingungan mau konten apa, tinggal pilih aja aset dan gaya konten di bawah ya!',
                      style: TextStyle(
                        fontSize: 14,
                        color: textGrey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildInteractiveDropdown(title: 'Pilih Aset/Bahan', description: 'Pilih produk, alat, atau tim...', value: selectedAset, items: listAset, onChanged: _handleAsetChanged, isAsetDropdown: true),
                    _buildInteractiveDropdown(title: 'Gaya Konten', description: 'Pilih tema konten...', value: selectedGaya, items: listGaya, onChanged: _handleGayaChanged, isAsetDropdown: false),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : generateAndSaveIdea,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cigemGreen, 
                          padding: const EdgeInsets.symmetric(vertical: 18), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                        child: isLoading 
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                                  ),
                                  SizedBox(width: 12),
                                  Text('AI Cigem sedang meracik ide...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                                  SizedBox(width: 10),
                                  Text('Generate Ide Konten', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : _resetForm,
                        icon: Icon(Icons.refresh, color: cigemGreen, size: 20),
                        label: Text('Mulai Ulang', style: TextStyle(color: cigemGreen, fontWeight: FontWeight.bold, fontSize: 15)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: cigemGreen, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Proses ini memakan waktu 5-15 detik.\nMohon jangan tutup aplikasi...',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ] else ...[
                      const SizedBox(height: 40),
                    ],
                    if (generatedIdea.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: const Color(0xFFEFF4F9), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withValues(alpha: 0.3))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('IDE KONTEN UNTUK ANDA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3EB49F), letterSpacing: 1)),
                                GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ide berhasil disalin!')));
                                  },
                                  child: Icon(Icons.content_copy, color: cigemGreen, size: 18),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: cigemGreen.withValues(alpha: 0.2), width: 1.5),
                              ),
                              child: Text(
                                generatedIdea,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black,
                                  height: 1.6,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '💡 Tips: Pakai ide ini langsung di konten Anda atau sesuaikan dengan gaya bisnis Anda',
                              style: TextStyle(fontSize: 11, color: textGrey, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                    if (hasilRanking.isNotEmpty) ...[
                      const Text('SKOR KECOCOKAN MEDSOS:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 8),
                      Text(
                        'Persentase kecocokan antara gaya konten Anda dengan algoritma setiap platform',
                        style: TextStyle(fontSize: 12, color: textGrey),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 12,
                        ),
                        itemCount: hasilRanking.length,
                        itemBuilder: (context, index) {
                          final platform = hasilRanking[index];
                          double scoreBacked = double.tryParse(platform['skor_akhir_spk'].toString()) ?? 0.0;
                          int scorePercentage = ((scoreBacked / 5.0) * 100).round();
                          return _buildPlatformScoreCard(
                            ranking: index + 1,
                            totalPlatforms: hasilRanking.length,
                            platformName: platform['nama_platform'],
                            score: scorePercentage,
                            icon: getPlatformIcon(platform['nama_platform']),
                            color: getPlatformColor(platform['nama_platform']),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformScoreCard({required int ranking, required int totalPlatforms, required String platformName, required int score, required FaIconData icon, required Color color}) {
    String description = '';
    String getScoreLabel(int score) {
      if (score >= 80) return 'Sangat Cocok';
      if (score >= 60) return 'Cocok';
      if (score >= 40) return 'Cukup';
      return 'Kurang Cocok';
    }
    switch (platformName.toLowerCase()) {
      case 'tiktok':
        description = 'Skor kecocokan dengan algoritma medsos.';
        break;
      case 'instagram reels':
        description = 'Skor kecocokan dengan algoritma medsos.';
        break;
      case 'facebook':
        description = 'Skor kecocokan dengan algoritma medsos.';
        break;
      case 'linkedin':
        description = 'Skor kecocokan dengan algoritma medsos.';
        break;
      case 'youtube shorts':
        description = 'Skor kecocokan dengan algoritma medsos.';
        break;
      case 'threads':
        description = 'Skor kecocokan dengan algoritma medsos.';
        break;
      default:
        description = 'Skor kecocokan platform.';
    }
    double scorePercentage = (score / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              FaIcon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 12),
              Text(
                '$score%',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  widthFactor: scorePercentage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                platformName,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                getScoreLabel(score),
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 0.3),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                description,
                style: const TextStyle(fontSize: 8, color: Colors.white, height: 1.2),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveDropdown({required String title, required String description, required String? value, required List<DropdownItem> items, required bool Function(String?) onChanged, required bool isAsetDropdown}) {
    Map<String, List<DropdownItem>> groupedItems = {};
    bool hasCategories = false;
    for (var item in items) {
      if (item.category != null) {
        hasCategories = true;
        if (!groupedItems.containsKey(item.category!)) {
          groupedItems[item.category!] = [];
        }
        groupedItems[item.category!]!.add(item);
      } else {
        if (!groupedItems.containsKey('NO_CATEGORY')) {
          groupedItems['NO_CATEGORY'] = [];
        }
        groupedItems['NO_CATEGORY']!.add(item);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expandedCategory = (_expandedCategory == title) ? null : title),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark)),
                      Text(value ?? description, style: TextStyle(fontSize: 12, color: value != null ? cigemGreen : textGrey)),
                      if (value != null && _expandedCategory != title) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: cigemGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: cigemGreen.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '✓ $value',
                            style: TextStyle(
                              fontSize: 12,
                              color: cigemGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(_expandedCategory == title ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: cigemGreen, size: 24),
              ],
            ),
          ),
          if (_expandedCategory == title)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: groupedItems.entries.expand((entry) {
                      final categoryName = entry.key;
                      final categoryItems = entry.value;
                      List<Widget> widgets = [];

                      if (hasCategories && categoryName != 'NO_CATEGORY') {
                        widgets.add(
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                            child: Text(
                              categoryName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: cigemGreen,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        );
                      } else if (hasCategories) {
                        widgets.add(const SizedBox(height: 8));
                      } else {
                        widgets.add(const SizedBox(height: 8));
                      }

                      int itemIndex = 1;
                      for (var item in categoryItems) {
                        final isSelected = item.title == value;
                        final isDisabled = isAsetDropdown
                          ? selectedGaya != null && !_isValidCombination(item.title, selectedGaya!)
                          : selectedAset != null && !_isValidCombination(selectedAset!, item.title);
                        widgets.add(
                          GestureDetector(
                            onTap: () {
                              if (isDisabled) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('⚠️ "${item.title}" tidak bisa dipilih karena kombinasi dengan alat/mesin tidak cocok.'),
                                    duration: const Duration(seconds: 5),
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                );
                                setState(() => _expandedCategory = title);
                                return;
                              }
                              final didChange = onChanged(isSelected ? null : item.title);
                              setState(() => _expandedCategory = didChange ? null : title);
                            },
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 220),
                              opacity: isDisabled ? 0.45 : 1.0,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? cigemGreen.withValues(alpha: 0.05)
                                      : isDisabled
                                          ? Colors.grey.shade100
                                          : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? cigemGreen : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? cigemGreen : Colors.white,
                                        boxShadow: [
                                          if (!isSelected)
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          isSelected ? '✓' : '$itemIndex',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isSelected ? Colors.white : (isDisabled ? Colors.grey.shade600 : Colors.grey.shade700),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                              color: isSelected
                                                  ? cigemGreen
                                                  : isDisabled
                                                      ? Colors.grey.shade600
                                                      : textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.description,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isSelected
                                                  ? cigemGreen
                                                  : isDisabled
                                                      ? Colors.grey.shade500
                                                      : textGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                        itemIndex++;
                      }
                      widgets.add(const SizedBox(height: 8));
                      return widgets;
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}