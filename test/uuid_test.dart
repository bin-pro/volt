import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:volt/core/utils/uuid_utils.dart';

void main() {
  // ── UUID 생성 ────────────────────────────────────────────────
  group('generateUuid', () {
    final _uuidRe = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('올바른 UUID v4 형식', () {
      expect(_uuidRe.hasMatch(generateUuid()), isTrue);
    });

    test('길이 36자', () {
      expect(generateUuid().length, 36);
    });

    test('100회 반복 — 모두 유효', () {
      for (var i = 0; i < 100; i++) {
        final uuid = generateUuid();
        expect(_uuidRe.hasMatch(uuid), isTrue, reason: 'iteration $i: $uuid');
      }
    });

    test('연속 두 번 호출 — 다른 값', () {
      expect(generateUuid(), isNot(equals(generateUuid())));
    });
  });

  // ── 시드 데이터 무결성 ────────────────────────────────────────
  group('exercises_seed.json', () {
    late List<Map<String, dynamic>> exercises;

    setUpAll(() {
      final raw = File('assets/data/exercises_seed.json').readAsStringSync();
      exercises = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    });

    test('로프 암풀다운 → 등', () {
      final ex = exercises.firstWhere((e) => e['name'] == '로프 암풀다운');
      expect(ex['group'], equals('등'));
    });

    test('모든 종목에 id·name·group 존재', () {
      for (final e in exercises) {
        expect(e['id'], isNotNull, reason: '${e['name']} id 누락');
        expect(e['name'], isNotNull);
        expect(e['group'], isNotNull, reason: '${e['name']} group 누락');
      }
    });

    test('유효한 그룹만 사용', () {
      const valid = {'가슴', '등', '어깨', '팔', '하체', '복근', '유산소'};
      for (final e in exercises) {
        expect(valid, contains(e['group']),
            reason: '${e['name']}: 잘못된 그룹 "${e['group']}"');
      }
    });

    test('id 중복 없음', () {
      final ids = exercises.map((e) => e['id']).toList();
      expect(ids.length, equals(ids.toSet().length));
    });

    test('chosung 필드 존재', () {
      for (final e in exercises) {
        expect(e['chosung'], isNotNull, reason: '${e['name']} chosung 누락');
      }
    });
  });
}
