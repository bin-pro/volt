// 한국어 초성 검색 유틸리티
// 완성형 한글: 가(0xAC00) ~ 힣(0xD7A3)
// 초성 28개: ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ (19 + 5쌍자음)

const _chosungList = [
  'ㄱ','ㄲ','ㄴ','ㄷ','ㄸ','ㄹ','ㅁ','ㅂ','ㅃ',
  'ㅅ','ㅆ','ㅇ','ㅈ','ㅉ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ',
];

String extractChosung(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    if (rune >= 0xAC00 && rune <= 0xD7A3) {
      final idx = (rune - 0xAC00) ~/ 588;
      buffer.write(_chosungList[idx]);
    }
  }
  return buffer.toString();
}

bool isChosungOnly(String query) {
  if (query.isEmpty) return false;
  return query.runes.every((c) => c >= 0x3131 && c <= 0x314E);
}

bool matchesQuery(String name, String chosung, String query) {
  if (query.isEmpty) return true;
  final q = query.trim().toLowerCase();
  if (isChosungOnly(q)) return chosung.contains(q);
  return name.toLowerCase().contains(q) || chosung.contains(q);
}
