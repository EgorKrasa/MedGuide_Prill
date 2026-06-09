import '../config/api_config.dart';

/// URL фото препарата на сервере (Render / local API).
class DrugImageUrls {
  DrugImageUrls._();

  static const _ext = ['jpg', 'jpeg', 'png', 'webp'];

  static const Map<String, int> indexByDrugId = {
    'парацетамол': 1,
    'ибупрофен': 2,
    'нимесулид': 3,
    'омепразол': 4,
    'панкреатин': 5,
    'амброксол': 6,
    'лоратадин': 7,
    'дротаверин': 8,
    'лоперамид': 9,
    'сертралин': 10,
    'флуоксетин': 11,
    'амитриптилин': 12,
    'диазепам': 13,
    'феназепам': 14,
    'кветиапин': 15,
    'венлафаксин': 16,
    'эсциталопрам': 17,
    'буспирон': 18,
    'тразодон': 19,
    'арипипразол': 20,
    'метформин': 21,
    'амоксициллин': 22,
    'азитромицин': 23,
    'цефтриаксон': 24,
    'левофлоксацин': 25,
    'кларитромицин': 26,
    'моксифлоксацин': 27,
    'фуросемид': 28,
    'спиронолактон': 29,
    'бисопролол': 30,
    'лозартан': 31,
    'амлодипин': 32,
    'эналаприл': 33,
    'рамиприл': 34,
    'аторвастатин': 35,
    'розувастатин': 36,
    'клопидогрел': 37,
    'ацетилсалициловаякислота': 38,
    'варфарин': 39,
    'ривароксабан': 40,
  };

  static int? resolveIndex(String drugId, int? imageIndex) {
    return imageIndex ?? indexByDrugId[drugId.trim().toLowerCase()];
  }

  /// Порядок: /media/drugs/{n} (рабочий эндпоинт), затем image_url из API, затем /static/drugs/.
  static List<String> serverCandidates({
    required String drugId,
    int? imageIndex,
    String? imageUrl,
  }) {
    final out = <String>[];
    final seen = <String>{};
    final base = ApiConfig.baseUrl.trim().replaceAll(RegExp(r'/$'), '');
    final idx = resolveIndex(drugId, imageIndex);

    void add(String url) {
      final u = url.trim();
      if (u.isEmpty || seen.contains(u)) return;
      seen.add(u);
      out.add(u);
    }

    if (idx != null) {
      add('$base/media/drugs/$idx');
    }

    final fromApi = imageUrl?.trim() ?? '';
    if (fromApi.isNotEmpty && !fromApi.contains('example.com')) {
      add(fromApi);
    }

    if (idx != null) {
      for (final e in _ext) {
        add('$base/static/drugs/$idx.$e');
      }
    }

    return out;
  }
}
