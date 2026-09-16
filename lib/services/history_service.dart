import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ============= MEDSOS CHECK ITEM =============
class MediaSosialCheckItem {
  final String id;
  final String contentName;
  final String platform;
  final String tanggal;
  final String waktu;
  final int skorAudience;
  final int skorTone;
  final int skorVisual;
  final int skorTujuan;
  final int skorCopy;
  final int skorInteraksi;
  final List<Map<String, dynamic>> platformRecommendations;
  int rating = 0;
  String views = '';
  bool isOrder = false;
  String notes = '';

  MediaSosialCheckItem({
    required this.id,
    required this.contentName,
    required this.platform,
    required this.tanggal,
    required this.waktu,
    required this.skorAudience,
    required this.skorTone,
    required this.skorVisual,
    required this.skorTujuan,
    required this.skorCopy,
    required this.skorInteraksi,
    required this.platformRecommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contentName': contentName,
      'platform': platform,
      'tanggal': tanggal,
      'waktu': waktu,
      'skorAudience': skorAudience,
      'skorTone': skorTone,
      'skorVisual': skorVisual,
      'skorTujuan': skorTujuan,
      'skorCopy': skorCopy,
      'skorInteraksi': skorInteraksi,
      'platformRecommendations': platformRecommendations,
      'rating': rating,
      'views': views,
      'isOrder': isOrder,
      'notes': notes,
    };
  }

  factory MediaSosialCheckItem.fromJson(Map<String, dynamic> json) {
    return MediaSosialCheckItem(
      id: json['id'] ?? '',
      contentName: json['contentName'] ?? '',
      platform: json['platform'] ?? '',
      tanggal: json['tanggal'] ?? '',
      waktu: json['waktu'] ?? '',
      skorAudience: json['skorAudience'] ?? 0,
      skorTone: json['skorTone'] ?? 0,
      skorVisual: json['skorVisual'] ?? 0,
      skorTujuan: json['skorTujuan'] ?? 0,
      skorCopy: json['skorCopy'] ?? 0,
      skorInteraksi: json['skorInteraksi'] ?? 0,
      platformRecommendations: List<Map<String, dynamic>>.from(
        json['platformRecommendations'] ?? [],
      ),
    )..rating = json['rating'] ?? 0
    ..views = json['views'] ?? ''
    ..isOrder = json['isOrder'] ?? false
    ..notes = json['notes'] ?? '';
  }
}

// ============= IDE KONTEN ITEM =============
class IdeKontenItem {
  final String id;
  final String aset;
  final String gaya;
  final String ideKonten;
  final String tanggal;
  final String waktu;
  final List<Map<String, dynamic>>? ranking;
  int rating = 0;
  String notes = '';
  String views = '';
  bool isOrder = false;

  IdeKontenItem({
    required this.id,
    required this.aset,
    required this.gaya,
    required this.ideKonten,
    required this.tanggal,
    required this.waktu,
    this.ranking,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'aset': aset,
      'gaya': gaya,
      'ideKonten': ideKonten,
      'tanggal': tanggal,
      'waktu': waktu,
      'ranking': ranking ?? [],
      'rating': rating,
      'notes': notes,
      'views': views,
      'isOrder': isOrder,
    };
  }

  factory IdeKontenItem.fromJson(Map<String, dynamic> json) {
    return IdeKontenItem(
      id: json['id'] ?? '',
      aset: json['aset'] ?? '',
      gaya: json['gaya'] ?? '',
      ideKonten: json['ideKonten'] ?? '',
      tanggal: json['tanggal'] ?? '',
      waktu: json['waktu'] ?? '',
      ranking: List<Map<String, dynamic>>.from(json['ranking'] ?? []),
    )..rating = json['rating'] ?? 0
    ..notes = json['notes'] ?? ''
    ..views = json['views'] ?? ''
    ..isOrder = json['isOrder'] ?? false;
  }
}

// ============= HISTORY SERVICE =============

class HistoryService {
  static const String _medsosMsCheckKey = 'medsos_checks_history';
  static const String _ideKontenKey = 'ide_konten_history';
  static const String _usernameKey = 'current_username';

  // ============= MEDSOS CHECK METHODS =============

  static Future<void> saveMedsoCheck(MediaSosialCheckItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_medsosMsCheckKey) ?? '[]';
      final List<dynamic> jsonList = json.decode(jsonString);
      
      jsonList.insert(0, item.toJson());
      
      if (jsonList.length > 50) {
        jsonList.removeRange(50, jsonList.length);
      }
      
      await prefs.setString(_medsosMsCheckKey, json.encode(jsonList));
      print('✅ Saved to history: ${item.contentName}');
    } catch (e) {
      print('Error saving medsos check: $e');
    }
  }

  static Future<List<MediaSosialCheckItem>> getMedsoChecks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_medsosMsCheckKey) ?? '[]';
      final List<dynamic> jsonList = json.decode(jsonString);
      
      print('📊 Loaded from history: ${jsonList.length} items');
      return jsonList
          .map((item) => MediaSosialCheckItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting medsos checks: $e');
      return [];
    }
  }

  static Future<void> clearAllMedsoChecks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_medsosMsCheckKey);
    } catch (e) {
      print('Error clearing medsos checks: $e');
    }
  }

  static Future<void> deleteMedsoCheck(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_medsosMsCheckKey) ?? '[]';
      final List<dynamic> jsonList = json.decode(jsonString);
      
      jsonList.removeWhere((item) => item['id'] == id);
      
      await prefs.setString(_medsosMsCheckKey, json.encode(jsonList));
    } catch (e) {
      print('Error deleting medsos check: $e');
    }
  }

  static Future<void> updateMedsoCheck(String id, int rating, String views, bool isOrder, String notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_medsosMsCheckKey) ?? '[]';
      final List<dynamic> jsonList = json.decode(jsonString);
      
      for (var item in jsonList) {
        if (item['id'] == id) {
          item['rating'] = rating;
          item['views'] = views;
          item['isOrder'] = isOrder;
          item['notes'] = notes;
          break;
        }
      }
      
      await prefs.setString(_medsosMsCheckKey, json.encode(jsonList));
      print('✅ Updated medsos check: $id');
    } catch (e) {
      print('Error updating medsos check: $e');
    }
  }

  // ============= IDE KONTEN METHODS =============

  static Future<void> saveIdeKonten(IdeKontenItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_ideKontenKey) ?? '[]';
      final List<dynamic> jsonList = json.decode(jsonString);
      
      jsonList.insert(0, item.toJson());
      
      if (jsonList.length > 50) {
        jsonList.removeRange(50, jsonList.length);
      }
      
      await prefs.setString(_ideKontenKey, json.encode(jsonList));
      print('✅ Saved to history: ${item.aset} - ${item.gaya}');
    } catch (e) {
      print('Error saving ide konten: $e');
    }
  }

  static Future<List<IdeKontenItem>> getIdeKonten() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_ideKontenKey) ?? '[]';
      final List<dynamic> jsonList = json.decode(jsonString);
      
      print('📊 Loaded from history (Ide Konten): ${jsonList.length} items');
      return jsonList
          .map((item) => IdeKontenItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting ide konten: $e');
      return [];
    }
  }

  static Future<void> updateIdeKonten(String id, int rating, String notes, String views, bool isOrder) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_ideKontenKey) ?? '[]';
      final List<dynamic> jsonList = json.decode(jsonString);
      
      for (var item in jsonList) {
        if (item['id'] == id) {
          item['rating'] = rating;
          item['notes'] = notes;
          item['views'] = views;
          item['isOrder'] = isOrder;
          break;
        }
      }
      
      await prefs.setString(_ideKontenKey, json.encode(jsonList));
      print('✅ Updated ide konten: $id');
    } catch (e) {
      print('Error updating ide konten: $e');
    }
  }

  static Future<void> deleteIdeKonten(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_ideKontenKey) ?? '[]';
      final List<dynamic> jsonList = json.decode(jsonString);
      
      jsonList.removeWhere((item) => item['id'] == id);
      
      await prefs.setString(_ideKontenKey, json.encode(jsonList));
    } catch (e) {
      print('Error deleting ide konten: $e');
    }
  }

  // ============= USERNAME METHODS =============

  static Future<void> saveUsername(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usernameKey, username);
      print('✅ Saved username: $username');
    } catch (e) {
      print('Error saving username: $e');
    }
  }

  static Future<String?> getUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_usernameKey);
    } catch (e) {
      print('Error getting username: $e');
      return null;
    }
  }

  static Future<void> clearUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_usernameKey);
      print('✅ Cleared username');
    } catch (e) {
      print('Error clearing username: $e');
    }
  }
}
