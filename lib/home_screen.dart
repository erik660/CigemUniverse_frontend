import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'cek_medsos_screen.dart';
import 'ide_konten_screen.dart';
import 'riwayat_screen.dart';
import 'services/history_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color cigemGreen = const Color(0xFF3EB49F);
  final Color bgLight = const Color(0xFFF9FAFB);
  final Color textDark = const Color(0xFF1E1E1E);
  final Color textGrey = const Color(0xFF6B7280);

  int _currentIndex = 0;
  int _weeklyIdeCount = 0;
  int _percentageIncrease = 0;
  List<Map<String, dynamic>> _weeklyIdeas = [];
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadStatistics();
  }

  Future<void> _loadUsername() async {
    final username = await HistoryService.getUsername();
    setState(() {
      _username = username ?? 'User';
    });
  }

  Future<void> _loadStatistics() async {
    final ideKontenList = await HistoryService.getIdeKonten();
    final medsoCheckList = await HistoryService.getMedsoChecks();
    
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = weekAgo.subtract(const Duration(days: 7));
    
    int thisWeekCount = 0;
    int lastWeekCount = 0;
    List<Map<String, dynamic>> thisWeekIdeas = [];
    
    for (var idea in ideKontenList) {
      try {
        final parts = idea.tanggal.split('/');
        if (parts.length == 3) {
          final date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          if (date.isAfter(weekAgo) && date.isBefore(now)) {
            thisWeekCount++;
            thisWeekIdeas.add({'type': 'ide_konten', 'item': idea, 'date': date});
          } else if (date.isBefore(weekAgo) && date.isAfter(twoWeeksAgo)) {
            lastWeekCount++;
          }
        }
      } catch (e) {
      }
    }
    
    for (var medso in medsoCheckList) {
      try {
        final parts = medso.tanggal.split('/');
        if (parts.length == 3) {
          final date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          if (date.isAfter(weekAgo) && date.isBefore(now)) {
            thisWeekCount++;
            thisWeekIdeas.add({'type': 'cek_medsos', 'item': medso, 'date': date});
          } else if (date.isBefore(weekAgo) && date.isAfter(twoWeeksAgo)) {
            lastWeekCount++;
          }
        }
      } catch (e) {
      }
    }
    
    thisWeekIdeas.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    
    int increase = lastWeekCount > 0 ? ((thisWeekCount - lastWeekCount) ~/ lastWeekCount * 100) : 0;
    if (increase > 100) increase = 100;
    
    setState(() {
      _weeklyIdeCount = thisWeekCount;
      _percentageIncrease = increase;
      _weeklyIdeas = thisWeekIdeas;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildBeranda(),
          const CekMedsosScreen(),
          const IdeKontenScreen(),
          const RiwayatScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: cigemGreen,
        unselectedItemColor: textGrey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            _loadStatistics();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Media Sosial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'Ide',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        ],
      ),
    );
  }

  Widget _buildBeranda() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
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
            const SizedBox(height: 24),
            Text(
              'CIGEM UNIVERSE',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cigemGreen,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Teman andalan buat nemuin ide dan strategi kontenmu',
              style: TextStyle(fontSize: 14, color: textGrey),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = 3;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cigemGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'RINGKASAN MINGGUAN',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              _percentageIncrease >= 0 ? Icons.trending_up : Icons.trending_down,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_percentageIncrease >= 0 ? '+' : ''}${_percentageIncrease}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_weeklyIdeCount Aktivitas Minggu Ini',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Container(
                          height: 6,
                          width: (200 * (_weeklyIdeCount / 20)).clamp(0, 200).toDouble(),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _weeklyIdeCount > 0
                          ? '"Terus semangat! Anda sudah membuat $_weeklyIdeCount ide minggu ini!"'
                          : '"Mulai ciptakan ide konten hari ini!"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (_weeklyIdeas.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white30),
                      const SizedBox(height: 12),
                      const Text(
                        'Terbaru:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._weeklyIdeas.take(3).map((ideData) {
                        final type = ideData['type'];
                        final item = ideData['item'];
                        
                        String displayText = '';
                        if (type == 'ide_konten') {
                          displayText = '📝 ${item.aset} - ${item.gaya}';
                        } else if (type == 'cek_medsos') {
                          displayText = '📱 ${item.contentName} (${item.platform})';
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  displayText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      if (_weeklyIdeas.length > 3)
                        Text(
                          '+${_weeklyIdeas.length - 3} lagi →',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Mau apa hari ini?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih aksi cepat untuk memulai aktivitas Anda.',
              style: TextStyle(fontSize: 14, color: textGrey),
            ),
            const SizedBox(height: 24),
            _buildActionCard(
              icon: Icons.business_outlined,
              iconBg: const Color(0xFFE6F7F5),
              iconColor: cigemGreen,
              title: 'Media Sosial',
              desc: 'Cocokkan kriteria konten dengan platform yang tepat',
              onTap: () => setState(() => _currentIndex = 1),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              icon: Icons.lightbulb_outline_rounded,
              iconBg: const Color(0xFFFFF7E6),
              iconColor: Colors.orange,
              title: 'Ide Konten',
              desc: 'Temukan inspirasi konten yang pas buat audiensmu',
              onTap: () => setState(() => _currentIndex = 2),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 13,
                      color: textGrey,
                      height: 1.4,
                    ),
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