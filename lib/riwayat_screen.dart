import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'services/history_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  // Palet warna Cigem
  final Color cigemGreen = const Color(0xFF3EB49F);
  final Color bgLight = const Color(0xFFF9FAFB);
  final Color textDark = const Color(0xFF1E1E1E);
  final Color textGrey = const Color(0xFF6B7280);

  // State Tab
  String activeTab = 'Media Sosial';
  bool isOrder = true; // Toggle Ya/Tidak
  String _username = ''; // Username yang login
  
  List<MediaSosialCheckItem> medsoHistory = [];
  List<IdeKontenItem> ideKontenHistory = [];
  bool isLoadingHistory = true;
  String? expandedItemId; // Track which item is expanded
  Map<String, Map<String, dynamic>> evaluationData = {}; // Store evaluation for each item
  Map<String, TextEditingController> viewsControllers = {}; // Controllers for views inputs
  Map<String, TextEditingController> notesControllers = {}; // Controllers for notes inputs

  Future<void> _loadUsername() async {
    final username = await HistoryService.getUsername();
    setState(() {
      _username = username ?? 'User';
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadHistory();
  }

  @override
  void dispose() {
    for (var controller in viewsControllers.values) {
      controller.dispose();
    }
    for (var controller in notesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => isLoadingHistory = true);
    final medsoList = await HistoryService.getMedsoChecks();
    final ideList = await HistoryService.getIdeKonten();
    setState(() {
      medsoHistory = medsoList;
      ideKontenHistory = ideList;
      isLoadingHistory = false;
    });
  }

  void _refreshHistory() {
    // Clear controllers and evaluation data
    for (var controller in viewsControllers.values) {
      controller.dispose();
    }
    for (var controller in notesControllers.values) {
      controller.dispose();
    }
    viewsControllers.clear();
    notesControllers.clear();
    evaluationData.clear();
    expandedItemId = null;
    
    _loadHistory();
  }

  Widget _buildInputChip(String label, int bobot) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cigemGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cigemGreen.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: Bobot $bobot',
        style: TextStyle(
          fontSize: 12,
          color: cigemGreen,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Title Section
                    const Text(
                      'Riwayat & Evaluasi',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. Tab Switcher (Ide Konten & Media Sosial)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildTabButton('Ide Konten'),
                          _buildTabButton('Media Sosial'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Refresh button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _refreshHistory();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cigemGreen,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '🔄 Refresh Riwayat',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. List Riwayat
                    if (activeTab == 'Media Sosial') ...[
                      if (isLoadingHistory)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (medsoHistory.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Column(
                              children: [
                                Icon(Icons.history, size: 48, color: textGrey),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada riwayat',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Lakukan cek medsos untuk melihat riwayat di sini',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...medsoHistory.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildMedsoHistoryItem(item),
                          );
                        }).toList(),
                    ] else if (activeTab == 'Ide Konten') ...[
                      if (isLoadingHistory)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (ideKontenHistory.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Column(
                              children: [
                                Icon(Icons.lightbulb, size: 48, color: textGrey),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada ide konten',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Hasilkan ide konten untuk melihat riwayat di sini',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...ideKontenHistory.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildIdeKontenHistoryItem(item),
                          );
                        }).toList(),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildTabButton(String label) {
    bool isActive = activeTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => activeTab = label);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? cigemGreen : textGrey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedsoHistoryItem(MediaSosialCheckItem item) {
    final isExpanded = expandedItemId == item.id;
    final iconColor = Colors.blue;
    
    if (!evaluationData.containsKey(item.id)) {
      evaluationData[item.id] = {
        'rating': item.rating > 0 ? item.rating : 0,
        'views': item.views,
        'isOrder': item.isOrder,
        'notes': item.notes,
      };
    }
    
    return GestureDetector(
      onTap: () => setState(() {
        expandedItemId = isExpanded ? null : item.id;
      }),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded
                ? cigemGreen.withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.2),
            width: isExpanded ? 1.5 : 1.0,
          ),
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: cigemGreen.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.smart_display,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.contentName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ),
                            if ((evaluationData[item.id]?['rating'] as int? ?? 0) > 0 || 
                                (evaluationData[item.id]?['notes'] as String? ?? '').isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Sudah Diulas',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.tanggal} • ${item.platform}',
                          style: TextStyle(
                            fontSize: 13,
                            color: textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: const Text('Hapus Riwayat?'),
                              content: const Text('Apakah Anda yakin ingin menghapus riwayat ini?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    await HistoryService.deleteMedsoCheck(item.id);
                                    _refreshHistory();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('✅ Riwayat berhasil dihapus!'), duration: Duration(seconds: 2)),
                                      );
                                    }
                                  },
                                  child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 22),
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: cigemGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Expanded Content
            if (isExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Input Kriteria
                    const Text(
                      'Kriteria Input Anda',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInputChip('Audience', item.skorAudience),
                        _buildInputChip('Tone', item.skorTone),
                        _buildInputChip('Visual', item.skorVisual),
                        _buildInputChip('Tujuan', item.skorTujuan),
                        _buildInputChip('Copy', item.skorCopy),
                        _buildInputChip('Interaksi', item.skorInteraksi),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Rating Performa
                    const Text(
                      'Rating Performa',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(
                        5,
                        (index) => GestureDetector(
                          onTap: () => setState(() {
                            evaluationData[item.id]!['rating'] = index + 1;
                          }),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.star,
                              color: index < (evaluationData[item.id]!['rating'] as int)
                                  ? Colors.orange
                                  : Colors.grey.shade300,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Jumlah Views & Order Toggle
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Jumlah Views',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildViewsTextField(item.id),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ada yang order?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildOrderToggle('Ya', item.id, true),
                                  const SizedBox(width: 8),
                                  _buildOrderToggle('Tidak', item.id, false),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Catatan Evaluasi
                    const Text(
                      'Catatan Evaluasi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildEvaluationTextField(item.id),
                    const SizedBox(height: 24),
                    
                    // Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => AlertDialog(
                                  title: const Text('Hapus Riwayat?'),
                                  content: const Text('Apakah Anda yakin ingin menghapus riwayat ini?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        await HistoryService.deleteMedsoCheck(item.id);
                                        _refreshHistory();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('✅ Riwayat berhasil dihapus!'), duration: Duration(seconds: 2)),
                                          );
                                        }
                                      },
                                      child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red.shade400),
                            ),
                            child: Text('Hapus', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final rating = evaluationData[item.id]!['rating'] as int;
                              final views = evaluationData[item.id]!['views'] as String;
                              final isOrder = evaluationData[item.id]!['isOrder'] as bool;
                              final notes = evaluationData[item.id]!['notes'] as String;
                              
                              await HistoryService.updateMedsoCheck(item.id, rating, views, isOrder, notes);
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('✅ Ulasan berhasil disimpan!'), duration: Duration(seconds: 2)),
                                );
                                setState(() => expandedItemId = null);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cigemGreen,
                              elevation: 0,
                            ),
                            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Platform Rankings
                    Text(
                      'Ranking Platform Medsos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...item.platformRecommendations.asMap().entries.map((entry) {
                      var platform = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: bgLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: getPlatformColor(platform['nama_platform'] ?? 'Platform'),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: FaIcon(
                                    getPlatformIcon(platform['nama_platform'] ?? 'Platform'),
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  platform['nama_platform'] ?? 'Platform',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: textDark,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: cigemGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Skor: ${platform['skor_akhir_spk']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: cigemGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIdeKontenHistoryItem(IdeKontenItem item) {
    final isExpanded = expandedItemId == item.id;
    
    if (!evaluationData.containsKey(item.id)) {
      evaluationData[item.id] = {
        'rating': item.rating,
        'notes': item.notes,
        'views': item.views,
        'isOrder': item.isOrder,
      };
    }
    
    return GestureDetector(
      onTap: () => setState(() {
        expandedItemId = isExpanded ? null : item.id;
      }),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded
                ? cigemGreen.withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.2),
            width: isExpanded ? 1.5 : 1.0,
          ),
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: cigemGreen.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cigemGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.lightbulb,
                      color: cigemGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.aset} - ${item.gaya}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if ((evaluationData[item.id]?['rating'] as int? ?? 0) > 0 || 
                                (evaluationData[item.id]?['notes'] as String? ?? '').isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Sudah Diulas',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.tanggal} • ${item.waktu}',
                          style: TextStyle(
                            fontSize: 13,
                            color: textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: const Text('Hapus Riwayat?'),
                              content: const Text('Apakah Anda yakin ingin menghapus riwayat ini?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    await HistoryService.deleteIdeKonten(item.id);
                                    _refreshHistory();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('✅ Riwayat berhasil dihapus!'), duration: Duration(seconds: 2)),
                                      );
                                    }
                                  },
                                  child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 22),
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: cigemGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Expanded Content
            if (isExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ide Konten Text
                    const Text(
                      'Ide Konten',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bgLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cigemGreen.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        item.ideKonten,
                        style: TextStyle(
                          fontSize: 13,
                          color: textDark,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Jumlah Views & Order Toggle
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Jumlah Views',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                onChanged: (value) {
                                  evaluationData[item.id]!['views'] = value;
                                },
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Masukkan jumlah views',
                                  hintStyle: TextStyle(color: textGrey),
                                  filled: true,
                                  fillColor: bgLight,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ada yang order?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        evaluationData[item.id]!['isOrder'] = true;
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: (evaluationData[item.id]!['isOrder'] as bool) ? cigemGreen : Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: (evaluationData[item.id]!['isOrder'] as bool) ? cigemGreen : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          'Ya',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: (evaluationData[item.id]!['isOrder'] as bool) ? Colors.white : textDark,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        evaluationData[item.id]!['isOrder'] = false;
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: !(evaluationData[item.id]!['isOrder'] as bool) ? cigemGreen : Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: !(evaluationData[item.id]!['isOrder'] as bool) ? cigemGreen : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          'Tidak',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: !(evaluationData[item.id]!['isOrder'] as bool) ? Colors.white : textDark,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Rating Ulasan
                    const Text(
                      'Rating Ulasan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(
                        5,
                        (index) => GestureDetector(
                          onTap: () => setState(() {
                            evaluationData[item.id]!['rating'] = index + 1;
                          }),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.star,
                              color: index < (evaluationData[item.id]!['rating'] as int)
                                  ? Colors.orange
                                  : Colors.grey.shade300,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Catatan Ulasan
                    const Text(
                      'Catatan Ulasan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (value) {
                        evaluationData[item.id]!['notes'] = value;
                      },
                      controller: TextEditingController(text: evaluationData[item.id]!['notes'] ?? ''),
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Catatan tentang ide konten ini...',
                        hintStyle: TextStyle(color: textGrey),
                        filled: true,
                        fillColor: bgLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => AlertDialog(
                                  title: const Text('Hapus Riwayat?'),
                                  content: const Text('Apakah Anda yakin ingin menghapus riwayat ini?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        await HistoryService.deleteIdeKonten(item.id);
                                        _refreshHistory();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('✅ Riwayat berhasil dihapus!'), duration: Duration(seconds: 2)),
                                          );
                                        }
                                      },
                                      child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red.shade400),
                            ),
                            child: Text('Hapus', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final rating = evaluationData[item.id]!['rating'] as int;
                              final notes = evaluationData[item.id]!['notes'] as String;
                              final views = evaluationData[item.id]!['views'] as String;
                              final isOrder = evaluationData[item.id]!['isOrder'] as bool;
                              
                              await HistoryService.updateIdeKonten(item.id, rating, notes, views, isOrder);
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('✅ Ulasan berhasil disimpan!'), duration: Duration(seconds: 2)),
                                );
                                setState(() => expandedItemId = null);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cigemGreen,
                              elevation: 0,
                            ),
                            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Platform Rankings
                    if (item.ranking != null && item.ranking!.isNotEmpty) ...[
                      Text(
                        'Ranking Platform Medsos',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...item.ranking!.asMap().entries.map((entry) {
                        var platform = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bgLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: getPlatformColor(platform['nama_platform'] ?? 'Platform'),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: FaIcon(
                                      getPlatformIcon(platform['nama_platform'] ?? 'Platform'),
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    platform['nama_platform'] ?? 'Platform',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: textDark,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cigemGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Skor: ${platform['skor_akhir_spk']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: cigemGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildViewsTextField(String itemId) {
    // Ensure controller exists for this item
    if (!viewsControllers.containsKey(itemId)) {
      viewsControllers[itemId] = TextEditingController(
        text: evaluationData[itemId]?['views'] ?? '',
      );
    }
    
    return TextField(
      controller: viewsControllers[itemId],
      onChanged: (value) {
        evaluationData[itemId]!['views'] = value;
      },
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: 'Masukkan jumlah views',
        hintStyle: TextStyle(color: textGrey),
        filled: true,
        fillColor: bgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildOrderToggle(String label, String itemId, bool value) {
    final isActive = evaluationData[itemId]!['isOrder'] == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          evaluationData[itemId]!['isOrder'] = value;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? cigemGreen : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? cigemGreen : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : textDark,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEvaluationTextField(String itemId) {
    // Ensure controller exists for this item
    if (!notesControllers.containsKey(itemId)) {
      notesControllers[itemId] = TextEditingController(
        text: evaluationData[itemId]?['notes'] ?? '',
      );
    }
    
    return TextField(
      controller: notesControllers[itemId],
      onChanged: (value) {
        evaluationData[itemId]!['notes'] = value;
      },
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Apa yang bisa ditingkatkan?',
        hintStyle: TextStyle(color: textGrey),
        filled: true,
        fillColor: bgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
