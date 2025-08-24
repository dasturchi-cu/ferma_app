import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceInputService {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _lastWords = '';

  Future<bool> initialize() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return false;
    }

    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech Status: $status'),
      onError: (error) => print('Speech Error: $error'),
    );
    
    return available;
  }

  Future<Map<String, dynamic>?> listenForEggData() async {
    if (!await initialize()) {
      return null;
    }

    try {
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
        },
        localeId: 'uz_UZ', // Uzbek locale
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        partialResults: false,
        onDevice: false,
      );

      // Wait for speech to complete
      await Future.delayed(const Duration(seconds: 5));
      
      if (_lastWords.isNotEmpty) {
        return _parseUzbekSpeech(_lastWords);
      }
    } catch (e) {
      print('Voice input error: $e');
    }
    
    return null;
  }

  Map<String, dynamic>? _parseUzbekSpeech(String speech) {
    // "yigirma sakkiz fletka tuxum yig'dim" -> 28
    // "besh fletka Akmalga sotdim" -> 5, "Akmal"
    // "ikki ta tovuq o'ldi" -> 2
    
    Map<String, int> numbers = {
      'bir': 1, 'ikki': 2, 'uch': 3, 'to\'rt': 4, 'tort': 4, 'besh': 5,
      'olti': 6, 'yetti': 7, 'sakkiz': 8, 'to\'qqiz': 9, 'toqqiz': 9,
      'o\'n': 10, 'on': 10, 'o\'n bir': 11, 'on bir': 11,
      'yigirma': 20, 'o\'ttiz': 30, 'ottiz': 30, 'qirq': 40,
      'ellik': 50, 'oltmish': 60, 'yetmish': 70, 'sakson': 80,
      'to\'qson': 90, 'toqson': 90, 'yuz': 100
    };
    
    // Speech parsing logic
    String lowerSpeech = speech.toLowerCase();
    
    if (lowerSpeech.contains('fletka') && (lowerSpeech.contains('yig\'dim') || lowerSpeech.contains('yigdim'))) {
      // Tuxum yig'ish
      int count = _extractNumber(lowerSpeech, numbers);
      return {'type': 'eggs_collected', 'count': count};
    }
    
    if (lowerSpeech.contains('sotdim')) {
      // Sotish
      int count = _extractNumber(lowerSpeech, numbers);
      String customer = _extractCustomerName(lowerSpeech);
      return {
        'type': 'eggs_sold', 
        'count': count, 
        'customer': customer
      };
    }
    
    if (lowerSpeech.contains('tovuq') && lowerSpeech.contains('o\'ldi')) {
      // Tovuq o'limi
      int count = _extractNumber(lowerSpeech, numbers);
      return {'type': 'chicken_death', 'count': count};
    }

    if (lowerSpeech.contains('siniq') || lowerSpeech.contains('buzilgan')) {
      // Siniq tuxum
      int count = _extractNumber(lowerSpeech, numbers);
      return {'type': 'broken_eggs', 'count': count};
    }

    if (lowerSpeech.contains('katta') && lowerSpeech.contains('tuxum')) {
      // Katta tuxum
      int count = _extractNumber(lowerSpeech, numbers);
      return {'type': 'large_eggs', 'count': count};
    }
    
    return null;
  }

  int _extractNumber(String speech, Map<String, int> numbers) {
    int extractedNumber = 0;
    
    // Extract digits first
    RegExp digitRegex = RegExp(r'\d+');
    Match? digitMatch = digitRegex.firstMatch(speech);
    if (digitMatch != null) {
      extractedNumber = int.tryParse(digitMatch.group(0)!) ?? 0;
    }
    
    // If no digits found, try to extract from Uzbek words
    if (extractedNumber == 0) {
      for (String word in numbers.keys) {
        if (speech.contains(word)) {
          extractedNumber += numbers[word]!;
        }
      }
    }
    
    return extractedNumber;
  }

  String _extractCustomerName(String speech) {
    // Simple extraction - look for common name patterns
    // This can be improved with more sophisticated NLP
    RegExp nameRegex = RegExp(r'(ga|ga sotdim|uchun)\s+(\w+)', caseSensitive: false);
    Match? match = nameRegex.firstMatch(speech);
    if (match != null) {
      return match.group(2) ?? '';
    }
    
    // Look for names before "ga" or "uchun"
    List<String> words = speech.split(' ');
    for (int i = 0; i < words.length - 1; i++) {
      if (words[i + 1].contains('ga') || words[i + 1].contains('uchun')) {
        return words[i];
      }
    }
    
    return '';
  }

  bool get isListening => _isListening;
  
  void stopListening() {
    _speech.stop();
    _isListening = false;
  }

  void cancel() {
    _speech.cancel();
    _isListening = false;
  }
} 