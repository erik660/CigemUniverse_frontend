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
  DropdownItem({required this.title, required this.description});
}

class CekMedsosScreen extends StatefulWidget {
  const CekMedsosScreen({super.key});
  @override
  State<CekMedsosScreen> createState() => _CekMedsosScreenState();
}

class _CekMedsosScreenState extends State<CekMedsosScreen> {
  final Color cigemGreen = const Color(0xFF3EB49F);
  final Color bgLight = const Color(0xFFF9FAFB);
  final Color textDark = const Color(0xFF1E1E1E);
  final Color textGrey = const Color(0xFF6B7280);
  
  final GlobalKey _audienceKey = GlobalKey();
  final GlobalKey _tujuanKey = GlobalKey();
  final GlobalKey _toneKey = GlobalKey();
  final GlobalKey _visualKey = GlobalKey();
  final GlobalKey _copyKey = GlobalKey();
  final GlobalKey _interaksiKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  
  String? selectedAudience;
  String? selectedTujuan;
  String? selectedTone;
  String? selectedVisual;
  String? selectedCopy;
  String? selectedInteraksi;
  String? _expandedCategory;
  String _username = ''; 
  
  bool isLoading = false;
  List<dynamic> hasilRekomendasi = [];
  Set<String> _emptyFields = {};

  final List<DropdownItem> listAudience = [
    DropdownItem(title: 'Sangat Spesifik', description: 'Untuk kalangan ahli/profesional/bisnis to bisnis/formal'),
    DropdownItem(title: 'Spesifik', description: 'Untuk orang yang sudah punya brand atau paham bisnis konveksi'),
    DropdownItem(title: 'Menengah', description: 'Campuran orang awam dan orang yang sudah tahu konveksi'),
    DropdownItem(title: 'Luas', description: 'Semua orang yang suka fashion atau butuh baju secara umum'),
    DropdownItem(title: 'Sangat Luas', description: 'Konten hiburan massal yang bisa ditonton siapa saja tanpa batas usia/minat khusus'),
  ];
  
  final List<DropdownItem> listTujuan = [
    DropdownItem(title: 'Branding Murni', description: 'Berbagi cerita atau ilmu tanpa ada ajakan membeli sama sekali'),
    DropdownItem(title: 'Soft Selling', description: 'Cerita dulu baru di akhir disebutin jasa Cigem secara tipis-tipis'),
    DropdownItem(title: 'Edukasi-Sales', description: 'Memberi tips sambil menawarkan solusi menggunakan jasa Cigem'),
    DropdownItem(title: 'Sales', description: 'Menunjukkan katalog produk secara jelas agar orang tertarik memesan'),
    DropdownItem(title: 'Hard Selling', description: 'Fokus ke harga, promo terbatas, dan langsung nyuruh orang klik link order'),
  ];
  
  final List<DropdownItem> listTone = [
    DropdownItem(title: 'Sangat Formal', description: 'Serius, kaku, menggunakan bahasa baku'),
    DropdownItem(title: 'Formal', description: 'Sopan dan profesional, tapi masih enak dibaca'),
    DropdownItem(title: 'Netral', description: 'Bahasa informatif biasa, tidak terlalu kaku tapi tidak terlalu gaul'),
    DropdownItem(title: 'Santai', description: 'Akrab, menggunakan kata "lu-gue" atau bahasa sehari-hari'),
    DropdownItem(title: 'Sangat Santai', description: 'Mengikuti tren viral, menggunakan banyak bahasa gaul (slangword), atau humor receh'),
  ];
  
  final List<DropdownItem> listVisual = [
    DropdownItem(title: 'Sangat Dasar', description: 'Rekam pakai HP seadanya, tanpa lampu tambahan, dan tanpa editing'),
    DropdownItem(title: 'Sederhana', description: 'Pakai HP, ada sedikit filter atau pemotongan durasi video yang simpel'),
    DropdownItem(title: 'Standar', description: 'Pencahayaan cukup, ada tulisan (teks) di video, dan suara terdengar jelas'),
    DropdownItem(title: 'Bagus', description: 'Pakai transisi rapi, musik latar yang pas, dan editing aplikasi (kaya CapCut) yang niat'),
    DropdownItem(title: 'Profesional', description: 'Kualitas sinematik, pakai kamera profesional, color grading, dan audio studio'),
  ];
  
  final List<DropdownItem> listCopy = [
    DropdownItem(title: 'Sangat Singkat', description: 'Hanya satu kata atau hanya kumpulan hashtag'),
    DropdownItem(title: 'Singkat', description: 'Satu kalimat pendek yang cuma menjelaskan isi foto/video'),
    DropdownItem(title: 'Menengah', description: 'Menjelaskan spesifikasi produk (bahan, ukuran, cara pesan)'),
    DropdownItem(title: 'Storytelling', description: 'Tulisan panjang yang nyeritain tentang proses atau masalah tertentu'),
    DropdownItem(title: 'Persuasif', description: 'Tulisan lengkap dengan alur: Masalah > Solusi > Testimoni > Ajakan Klik'),
  ];
  
  final List<DropdownItem> listInteraksi = [
    DropdownItem(title: 'Sangat Pasif', description: 'Hanya posting informasi, ga peduli orang mau komen atau ngga'),
    DropdownItem(title: 'Pasif', description: 'Sama kaya skor 1 tapi jarang ada yang balas'),
    DropdownItem(title: 'Menengah', description: 'Ada ajakan standar seperti "Jangan lupa like dan share"'),
    DropdownItem(title: 'Aktif', description: 'Bertanya di akhir caption (contoh: "Kalian lebih suka bahan A atau B?")'),
    DropdownItem(title: 'Sangat Aktif', description: 'Mengadakan kuis, giveaway, atau membalas setiap komen dengan pertanyaan baru agar ramai'),
  ];

  @override
  void initState() {
    super.initState();
    _loadUsername();
    HttpOverrides.global = _MyHttpOverrides();
  }

  Future<void> _loadUsername() async {
    final username = await HistoryService.getUsername();
    setState(() {
      _username = username ?? 'User';
    });
  }

  int getScore(String? selectedValue, List<DropdownItem> list) {
    if (selectedValue == null) return 3; 
    int index = list.indexWhere((item) => item.title == selectedValue);
    return index == -1 ? 3 : index + 1;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      selectedAudience = null;
      selectedTujuan = null;
      selectedTone = null;
      selectedVisual = null;
      selectedCopy = null;
      selectedInteraksi = null;
      _expandedCategory = null;
      hasilRekomendasi = [];
      _emptyFields.clear();
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

  Future<void> hitungSPK() async {
    // Check if ALL fields are empty
    bool allEmpty = selectedAudience == null &&
        selectedTujuan == null &&
        selectedTone == null &&
        selectedVisual == null &&
        selectedCopy == null &&
        selectedInteraksi == null;

    if (allEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Mohon isi semua kriteria'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _emptyFields = {'Audience', 'Tujuan', 'Tone', 'Visual', 'Copy', 'Interaksi'};
      });
      return;
    }

    // Find first empty field and highlight all empty fields
    GlobalKey? emptyFieldKey;
    String emptyFieldName = '';
    
    if (selectedAudience == null) {
      emptyFieldKey = _audienceKey;
      emptyFieldName = 'Audience';
    } else if (selectedTujuan == null) {
      emptyFieldKey = _tujuanKey;
      emptyFieldName = 'Tujuan Konten';
    } else if (selectedTone == null) {
      emptyFieldKey = _toneKey;
      emptyFieldName = 'Tone konten';
    } else if (selectedVisual == null) {
      emptyFieldKey = _visualKey;
      emptyFieldName = 'Visual';
    } else if (selectedCopy == null) {
      emptyFieldKey = _copyKey;
      emptyFieldName = 'Copywriting';
    } else if (selectedInteraksi == null) {
      emptyFieldKey = _interaksiKey;
      emptyFieldName = 'Interaksi';
    }
    
    if (emptyFieldKey != null) {
      // Update empty fields set for highlighting
      setState(() {
        _emptyFields.clear();
        if (selectedAudience == null) _emptyFields.add('Audience');
        if (selectedTujuan == null) _emptyFields.add('Tujuan');
        if (selectedTone == null) _emptyFields.add('Tone');
        if (selectedVisual == null) _emptyFields.add('Visual');
        if (selectedCopy == null) _emptyFields.add('Copy');
        if (selectedInteraksi == null) _emptyFields.add('Interaksi');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Pilih $emptyFieldName terlebih dahulu!'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red.shade700,
        ),
      );
      
      await Future.delayed(const Duration(milliseconds: 100));
      final RenderObject? renderObject = emptyFieldKey.currentContext?.findRenderObject();
      if (renderObject != null) {
        _scrollController.animateTo(
          _scrollController.position.pixels + (renderObject as RenderBox).localToGlobal(Offset.zero).dy - 120,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      return;
    }

    // Clear empty fields when all are filled
    setState(() {
      _emptyFields.clear();
    });

    setState(() {
      isLoading = true;
      hasilRekomendasi = [];
    });
    try {
      final url = backendApiUri('/api/rekomendasi_dinamis');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'K01': getScore(selectedAudience, listAudience),
          'K02': getScore(selectedTone, listTone),
          'K03': getScore(selectedVisual, listVisual),
          'K04': getScore(selectedTujuan, listTujuan),
          'K05': getScore(selectedCopy, listCopy),
          'K06': getScore(selectedInteraksi, listInteraksi),
        }),
      ).timeout(const Duration(seconds: 15)); 

      if (response.statusCode == 200 || response.statusCode == 404) {
        List<Map<String, dynamic>> finalData = [];
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          finalData = List<Map<String, dynamic>>.from(data['data'] ?? []);
        }

        // FALLBACK: Jika backend berjalan tapi database kosong (data[] empty), 
        // ATAU jika API belum dibuat di Vercel (404),
        // kita hitung SPK secara lokal agar UI tetap muncul sesuai request.
        if (finalData.isEmpty) {
          Map<String, int> dictAktual = {
            'K01': getScore(selectedAudience, listAudience),
            'K02': getScore(selectedTone, listTone),
            'K03': getScore(selectedVisual, listVisual),
            'K04': getScore(selectedTujuan, listTujuan),
            'K05': getScore(selectedCopy, listCopy),
            'K06': getScore(selectedInteraksi, listInteraksi),
          };

          List<Map<String, dynamic>> platforms = [
            {'id_platform': 1, 'nama_platform': 'TikTok', 'targets': {'K01': 5, 'K02': 5, 'K03': 3, 'K04': 4, 'K05': 1, 'K06': 5}, 'core': ['K01', 'K02']},
            {'id_platform': 2, 'nama_platform': 'Instagram Reels', 'targets': {'K01': 4, 'K02': 4, 'K03': 5, 'K04': 3, 'K05': 2, 'K06': 3}, 'core': ['K03', 'K04']},
            {'id_platform': 3, 'nama_platform': 'Facebook', 'targets': {'K01': 2, 'K02': 3, 'K03': 3, 'K04': 5, 'K05': 4, 'K06': 4}, 'core': ['K04', 'K06']},
            {'id_platform': 4, 'nama_platform': 'LinkedIn', 'targets': {'K01': 1, 'K02': 1, 'K03': 4, 'K04': 2, 'K05': 5, 'K06': 5}, 'core': ['K04', 'K05']},
            {'id_platform': 5, 'nama_platform': 'YouTube Shorts', 'targets': {'K01': 3, 'K02': 3, 'K03': 5, 'K04': 2, 'K05': 1, 'K06': 2}, 'core': ['K01', 'K02']},
            {'id_platform': 6, 'nama_platform': 'Threads', 'targets': {'K01': 4, 'K02': 5, 'K03': 2, 'K04': 2, 'K05': 5, 'K06': 5}, 'core': ['K05', 'K06']}
          ];

          double hitungBobotGap(int gap) {
            Map<int, double> pemetaan = {0: 5.0, 1: 4.5, -1: 4.0, 2: 3.5, -2: 3.0, 3: 2.5, -3: 2.0, 4: 1.5, -4: 1.0, 5: 0.5, -5: 0.0};
            return pemetaan[gap] ?? 0.0;
          }

          for (var platform in platforms) {
            double totalBobotCore = 0; int countCore = 0;
            double totalBobotSecondary = 0; int countSecondary = 0;
            Map<String, int> targets = platform['targets'];
            List<String> coreFactors = platform['core'];
            
            targets.forEach((idKriteria, nilaiTarget) {
              int gap = (dictAktual[idKriteria] ?? 3) - nilaiTarget;
              double bobot = hitungBobotGap(gap);
              if (coreFactors.contains(idKriteria)) { 
                totalBobotCore += bobot; 
                countCore++; 
              } else { 
                totalBobotSecondary += bobot; 
                countSecondary++; 
              }
            });

            double ncf = countCore > 0 ? (totalBobotCore / countCore) : 0;
            double nsf = countSecondary > 0 ? (totalBobotSecondary / countSecondary) : 0;
            double nilaiTotal = (0.6 * ncf) + (0.4 * nsf);
            
            finalData.add({
              'id_platform': platform['id_platform'],
              'nama_platform': platform['nama_platform'],
              'ncf': double.parse(ncf.toStringAsFixed(2)),
              'nsf': double.parse(nsf.toStringAsFixed(2)),
              'skor_akhir_spk': double.parse(nilaiTotal.toStringAsFixed(2))
            });
          }
          finalData.sort((a, b) => b['skor_akhir_spk'].compareTo(a['skor_akhir_spk']));
        }
        
        final now = DateTime.now();
        final tanggal = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
        final waktu = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        
        final historyItem = MediaSosialCheckItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          contentName: 'Cek Medsos',
          platform: finalData.isNotEmpty 
              ? finalData[0]['nama_platform'] ?? 'Tidak Terpilih'
              : 'Tidak Terpilih',
          tanggal: tanggal,
          waktu: waktu,
          skorAudience: getScore(selectedAudience, listAudience),
          skorTone: getScore(selectedTone, listTone),
          skorVisual: getScore(selectedVisual, listVisual),
          skorTujuan: getScore(selectedTujuan, listTujuan),
          skorCopy: getScore(selectedCopy, listCopy),
          skorInteraksi: getScore(selectedInteraksi, listInteraksi),
          platformRecommendations: finalData,
        );
        
        await HistoryService.saveMedsoCheck(historyItem);
        
        setState(() {
          hasilRekomendasi = finalData;
          isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Hasil disimpan ke riwayat!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        final responseBody = response.body;
        final serverMessage = response.statusCode == 503 || responseBody.contains('high demand')
            ? 'Server AI sedang sibuk. Coba lagi beberapa saat.'
            : responseBody;
        throw Exception('Gagal memuat data (${response.statusCode}): $serverMessage');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        String errorMsg = 'Error: $e';
        if (e.toString().contains('SocketException')) {
          errorMsg = '🔴 Tidak bisa koneksi ke server. Cek WiFi/data internet';
        } else if (e.toString().contains('TimeoutException')) {
          errorMsg = '⏱️ Server lambat - coba lagi';
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

  String getPlatformDescription(String namaPlatform) {
    switch (namaPlatform.toLowerCase()) {
      case 'tiktok': return 'Viralitas konten pendek kreatif';
      case 'instagram reels': return 'Visual storytelling & Reels';
      case 'facebook': return 'Komunitas & Ads targeting';
      case 'linkedin': return 'Jaringan profesional & B2B';
      case 'youtube shorts': return 'Jangkauan video global masif';
      case 'threads': return 'Percakapan berbasis teks real-time';
      default: return 'Platform media sosial';
    }
  }

  Gradient? getPlatformGradient(String namaPlatform) {
    if (namaPlatform.toLowerCase() == 'instagram reels') {
      return const LinearGradient(
        colors: [Color(0xFFf09433), Color(0xFFe6683c), Color(0xFFdc2743), Color(0xFFcc2366), Color(0xFFbc1888)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER BARU ---
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
            // --- END HEADER ---

            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Media Sosial',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kalo kamu udah punya konten, masukin kriteria kontennya di bawah ya!',
                      style: TextStyle(
                        fontSize: 14,
                        color: textGrey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      key: _audienceKey,
                      child: _buildInteractiveDropdown(
                        title: 'Target Audience',
                        description: 'Pilih demografi audiens yang paling sesuai.',
                        hint: 'Pilih target audiens...',
                        value: selectedAudience,
                        items: listAudience,
                        onChanged: (val) => setState(() {
                          selectedAudience = val;
                          if (val != null) _emptyFields.remove('Audience');
                        }),
                        isEmpty: _emptyFields.contains('Audience'),
                      ),
                    ),
                    Container(
                      key: _tujuanKey,
                      child: _buildInteractiveDropdown(
                        title: 'Tujuan Konten',
                        description: 'Apa hasil akhir yang ingin dicapai dari konten ini?',
                        hint: 'Pilih tujuan konten...',
                        value: selectedTujuan,
                        items: listTujuan,
                        onChanged: (val) => setState(() {
                          selectedTujuan = val;
                          if (val != null) _emptyFields.remove('Tujuan');
                        }),
                        isEmpty: _emptyFields.contains('Tujuan'),
                      ),
                    ),
                    Container(
                      key: _toneKey,
                      child: _buildInteractiveDropdown(
                        title: 'Tone Konten',
                        description: 'Bagaimana gaya komunikasi konten ini?',
                        hint: 'Pilih tone konten...',
                        value: selectedTone,
                        items: listTone,
                        onChanged: (val) => setState(() {
                          selectedTone = val;
                          if (val != null) _emptyFields.remove('Tone');
                        }),
                        isEmpty: _emptyFields.contains('Tone'),
                      ),
                    ),
                    Container(
                      key: _visualKey,
                      child: _buildInteractiveDropdown(
                        title: 'Kualitas Visual',
                        description: 'Seberapa kompleks visual yang ditampilkan?',
                        hint: 'Pilih kualitas visual...',
                        value: selectedVisual,
                        items: listVisual,
                        onChanged: (val) => setState(() {
                          selectedVisual = val;
                          if (val != null) _emptyFields.remove('Visual');
                        }),
                        isEmpty: _emptyFields.contains('Visual'),
                      ),
                    ),
                    Container(
                      key: _copyKey,
                      child: _buildInteractiveDropdown(
                        title: 'Copywriting',
                        description: 'Bagaimana gaya penulisan teks atau caption-nya?',
                        hint: 'Pilih gaya penulisan...',
                        value: selectedCopy,
                        items: listCopy,
                        onChanged: (val) => setState(() {
                          selectedCopy = val;
                          if (val != null) _emptyFields.remove('Copy');
                        }),
                        isEmpty: _emptyFields.contains('Copy'),
                      ),
                    ),
                    Container(
                      key: _interaksiKey,
                      child: _buildInteractiveDropdown(
                        title: 'Sifat Interaksi',
                        description: 'Tindakan apa yang diharapkan dari audiens?',
                        hint: 'Pilih target interaksi...',
                        value: selectedInteraksi,
                        items: listInteraksi,
                        onChanged: (val) => setState(() {
                          selectedInteraksi = val;
                          if (val != null) _emptyFields.remove('Interaksi');
                        }),
                        isEmpty: _emptyFields.contains('Interaksi'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : hitungSPK,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cigemGreen,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Cek Platform',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _resetForm,
                        icon: Icon(Icons.refresh, color: cigemGreen, size: 20),
                        label: Text('Mulai Ulang', style: TextStyle(color: cigemGreen, fontWeight: FontWeight.bold, fontSize: 15)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: cigemGreen, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    if (hasilRekomendasi.isNotEmpty) ...[
                      Text(
                        'Peringkat Platform',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...hasilRekomendasi.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> platform = entry.value as Map<String, dynamic>;
                        String namaMedsos = platform['nama_platform'].toString();
                        double skor = double.tryParse(platform['skor_akhir_spk'].toString()) ?? 0.0;
                        int percentage = ((skor / 5.0) * 100).round();

                        String baseDesc = getPlatformDescription(namaMedsos);
                        String detailDesc = 'Skor SPK: ${skor.toStringAsFixed(2)} / 5.00';

                        return _buildPlatformCard(
                          title: namaMedsos,
                          desc: '$baseDesc\n$detailDesc',
                          iconWidget: FaIcon(
                            getPlatformIcon(namaMedsos),
                            color: Colors.white,
                            size: 28,
                          ),
                          bgColor: getPlatformColor(namaMedsos),
                          gradient: getPlatformGradient(namaMedsos),
                          percentage: '$percentage%',

                          percentageBadgeColor: Colors.white,
                          isTop: index == 0,
                        );
                      }).toList(),
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

  Widget _buildInteractiveDropdown({
    required String title,
    required String description,
    required String hint,
    required String? value,
    required List<DropdownItem> items,
    required ValueChanged<String?> onChanged,
    bool isEmpty = false,
  }) {
    int? selectedScore;
    if (value != null) {
      selectedScore = items.indexWhere((item) => item.title == value) + 1;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: isEmpty
                ? BoxDecoration(
                    border: Border.all(color: Colors.red.shade500, width: 2.0),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            padding: isEmpty ? const EdgeInsets.all(12) : null,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_expandedCategory == title) {
                    _expandedCategory = null;
                  } else {
                    _expandedCategory = title;
                  }
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isEmpty ? Colors.red.shade600 : textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(fontSize: 12, color: isEmpty ? Colors.red.shade400 : textGrey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                              '✓ $value (Bobot: $selectedScore)',
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
                  const SizedBox(width: 12),
                  Icon(
                    _expandedCategory == title
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: isEmpty ? Colors.red.shade500 : cigemGreen,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_expandedCategory == title)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1.0),
              ),
              child: Column(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = item.title == value;

                  return GestureDetector(
                    onTap: () {
                      if (isSelected) {
                        onChanged(null);
                      } else {
                        onChanged(item.title);
                      }
                      setState(() {
                        _expandedCategory = null;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: isSelected
                            ? Border.all(color: cigemGreen, width: 2.0)
                            : Border.all(
                                color: Colors.grey.shade200,
                                width: 1.0,
                              ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected
                            ? cigemGreen.withValues(alpha: 0.05)
                            : Colors.grey.shade100,
                      ),
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cigemGreen
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                isSelected ? '✓' : '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : textGrey,
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
                                    fontSize: 13,
                                    color: isSelected ? cigemGreen : textDark,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? cigemGreen : textGrey,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlatformCard({
    required String title,
    required String desc,
    required Widget iconWidget,
    Color? bgColor,
    Gradient? gradient,
    required String percentage,
    required Color percentageBadgeColor,
    bool isTop = false,
  }) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgColor,
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (bgColor ?? Colors.black).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(width: 44, height: 44, child: Center(child: iconWidget)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: percentageBadgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: percentageBadgeColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  percentage,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isTop)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cigemGreen,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Text(
                '#1 TOP',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
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