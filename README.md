# godot-josa

받침 유무에 따라 올바른 한국어 조사를 자동으로 골라 붙이는 **Godot 4 GDScript 모듈**.
파일 하나(`Josa.gd`)를 복사하면 끝 — 의존성 없음, 오토로드 불필요.

A single-file GDScript module for Godot 4 that picks the correct Korean
particle (조사) based on the final consonant (받침) of the preceding word.
Port of [josa-moa](https://github.com/josa-moa/josa-moa)'s algorithm (Java, Apache-2.0).

런타임에 이름이 템플릿에 삽입되는 게임에서 특히 유용하다:
`"%s 이(가)"` 같은 병기 대신 `"Edward가"` / `"Zondun이"`를 자동 생성.

## 설치 / Install

`Josa.gd`를 프로젝트의 아무 스크립트 폴더에 복사.
`class_name Josa` + static 함수라 어디서든 바로 호출 가능.

## 사용법 / Usage

### 1. 마커 치환 — `Josa.apply(text)` (번역 템플릿에 권장)

문자열에 `{조사쌍}` 마커를 심고, 포맷 후 `apply()` 호출.
마커 **직전 문자**의 받침으로 조사를 고른다. 마커 없는 문자열은 그대로(영어 무해).

```gdscript
Josa.apply("Edward{이가} 출정")     # → "Edward가 출정"
Josa.apply("Zondun{이가} 출정")     # → "Zondun이 출정"   (n = '엔', 받침 있음)
Josa.apply("장갑{을를} 얻었다")      # → "장갑을 얻었다"
Josa.apply("서울{으로} 진군")        # → "서울로 진군"      (ㄹ 받침 예외)

# 번역 CSV/템플릿과 함께:
var text := tr("%s seizes %s") % [name, castle]   # ko: "%s{이가} %s{을를} 점령"
label.text = Josa.apply(text)
```

### 2. 직접 결합 — `Josa.attach(word, pair)`

```gdscript
Josa.attach("영철", "은는")   # → "영철은"
Josa.attach("철수", "은는")   # → "철수는"
Josa.attach("장갑", "을를")   # → "장갑을"
```

### 3. 조사만 — `Josa.pick(word, pair)`

```gdscript
Josa.pick("철수", "이가")     # → "가"
Josa.pick("영철", "이가")     # → "이"
```

## 지원 조사쌍 / Particle pairs

| 키 | 받침 있음 | 받침 없음 | 예 |
|---|---|---|---|
| `이가` | 이 | 가 | 영철이 / 철수가 |
| `은는` | 은 | 는 | 영철은 / 철수는 |
| `을를` | 을 | 를 | 장갑을 / 모자를 |
| `와과` | 과 | 와 | 성과 / Riva와 |
| `아야` | 아 | 야 | 영철아 / 철수야 |
| `이여` | 이 | 여 | — |
| `이나` | 이나 | 나 | 밥이나 / 차나 |
| `이랑` | 이랑 | 랑 | 형이랑 / 누나랑 |
| `이며` | 이며 | 며 | — |
| `으로` | 으로 | 로 | 집으로 / 학교로 / 서울로(ㄹ 예외) |

## 받침 판정 규칙 / Batchim rules

| 문자 종류 | 규칙 |
|---|---|
| 한글 음절 (가–힣) | `(유니코드 - 0xAC00) % 28 != 0` 이면 받침 있음. `% 28 == 8` 이면 ㄹ 받침(`으로` → `로`) |
| 숫자 | 수사 발음 — 받침 있음: 0(영)·1(일)·3(삼)·6(육)·7(칠)·8(팔), 없음: 2(이)·4(사)·5(오)·9(구) |
| 영문자 | 알파벳 이름 발음 — 받침 있음: l(엘)·m(엠)·n(엔)·r(알), 그 외 없음. l·r 은 ㄹ 취급 |
| 그 외(기호·공백·문두) | 받침 없음 취급 |

## 통합 팁 / Integration tip

포맷된 텍스트가 지나가는 촉 포인트(예: 이벤트 로그의 `add()`) 한두 곳에서만
`Josa.apply()`를 호출하면 전체 UI가 커버된다. `apply()`는 멱등이라 이중 호출 안전.

주의: 마커는 `%s`에 **공백 없이** 붙일 것 (`%s{이가}` ⭕ / `%s {이가}` ❌ —
조사는 직전 문자를 보므로 공백이 끼면 오판).

## License

Apache License 2.0 — see [LICENSE](LICENSE).
Algorithm derived from [josa-moa](https://github.com/josa-moa/josa-moa) (Apache-2.0); see [NOTICE](NOTICE).
