import '../models/surah.dart';
import '../models/ayah.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../models/resume_data.dart';

class QuranRepository {
  final ApiService _apiService;
  final LocalStorageService _localStorageService;

  QuranRepository(this._apiService, this._localStorageService);

  Future<List<Surah>> getAllSurahs() => _apiService.getAllSurahs();

  Future<List<Ayah>> getSurahAyahs(int surahNumber) => _apiService.getSurahDetail(surahNumber);

  Future<List<Ayah>> getTranslation(int surahNumber, String lang) => _apiService.getTranslation(surahNumber, lang);

  Future<void> saveResumePoint(ResumeData data) => _localStorageService.saveResumeData(data);

  ResumeData? getResumePoint() => _localStorageService.getResumeData();
}
