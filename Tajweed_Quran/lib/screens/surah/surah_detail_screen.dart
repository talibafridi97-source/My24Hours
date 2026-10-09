import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/surah.dart';
import '../../models/ayah.dart';
import '../../repository/quran_repository.dart';
import '../../providers/settings_provider.dart';
import '../../core/constants/constants.dart';

class SurahDetailScreen extends StatefulWidget {
  final Surah surah;
  const SurahDetailScreen({super.key, required this.surah});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  late Future<List<Ayah>> _ayahsFuture;

  @override
  void initState() {
    super.initState();
    final repository = context.read<QuranProvider>().repository; // I need to expose repository or use provider method
    _ayahsFuture = repository.getSurahAyahs(widget.surah.number);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.surah.englishName)),
      body: FutureBuilder<List<Ayah>>(
        future: _ayahsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final ayahs = snapshot.data!;
          return ListView.builder(
            itemCount: ayahs.length,
            itemBuilder: (context, index) {
              final ayah = ayahs[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          ayah.text,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: settings.arabicFontSize,
                            fontFamily: 'Amiri', // Assuming font is added
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: AppConstants.primaryGreen,
                              child: Text('${ayah.numberInSurah}', style: const TextStyle(fontSize: 12, color: Colors.white)),
                            ),
                            Row(
                              children: [
                                IconButton(icon: const Icon(Icons.share), onPressed: () {}),
                                IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {}),
                                IconButton(icon: const Icon(Icons.play_arrow), onPressed: () {}),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
