class_name Josa
extends RefCounted
##
## 한국어 조사 자동 선택(받침 판정). 단일 파일·무의존 — 다른 Godot 프로젝트에 이 파일만
## 복사하면 동작한다. 알고리즘은 josa-moa(https://github.com/josa-moa/josa-moa,
## Apache-2.0, Java)의 규칙을 GDScript 로 포팅한 것.
##
## 사용법 1 — 마커 치환(권장, 번역 템플릿용):
##   번역 문자열에 "%s{이가}", "%s{을를}" 처럼 마커를 심고, 포맷 후 Josa.apply(text) 호출.
##   마커 직전 문자의 받침으로 조사를 고른다. 마커 없는 문자열은 그대로(영어 무해).
##   예: Josa.apply("Edward{이가} 출정") → "Edward가 출정" / "Zondug{이가}" → "Zondug이"
## 사용법 2 — 직접 결합: Josa.attach("장갑", "을를") → "장갑을"
## 사용법 3 — 조사만: Josa.pick("철수", "은는") → "는"
##
## 받침 규칙: 한글 음절 = (code-0xAC00)%28 != 0. 숫자 = 수사 발음(0영·1일·3삼·6육·7칠·8팔 받침O).
## 영문자 = 알파벳 이름 발음(l엘·m엠·n엔·r알 받침O). 그 외 문자 = 받침 없음 취급.
## "으로/로"는 ㄹ 받침(및 l·r) 예외 — ㄹ 이면 '로'.
##

# 마커 키 → [받침 있음, 받침 없음]. "으로"는 ㄹ 예외를 pick 에서 별도 처리.
const PAIRS := {
	"이가": ["이", "가"],
	"은는": ["은", "는"],
	"을를": ["을", "를"],
	"와과": ["과", "와"],
	"아야": ["아", "야"],
	"이여": ["이", "여"],
	"이나": ["이나", "나"],
	"이랑": ["이랑", "랑"],
	"이며": ["이며", "며"],
	"으로": ["으로", "로"],
}

const _DIGIT_BATCHIM := { "0": true, "1": true, "2": false, "3": true, "4": false,
	"5": false, "6": true, "7": true, "8": true, "9": false }
const _LETTER_BATCHIM := ["l", "m", "n", "r"]   # 엘·엠·엔·알
const _LETTER_RYUL := ["l", "r"]                # ㄹ 발음 — '로' 예외 대상


# 마지막 유효 문자의 받침 여부. ryul=true 를 함께 반환하면 ㄹ 받침(으로→로 예외).
static func _batchim_of(ch: String) -> Dictionary:
	if ch == "":
		return { "batchim": false, "ryul": false }
	var code: int = ch.unicode_at(0)
	if code >= 0xAC00 and code <= 0xD7A3:   # 한글 음절
		var jong: int = (code - 0xAC00) % 28
		return { "batchim": jong != 0, "ryul": jong == 8 }
	var low: String = ch.to_lower()
	if _DIGIT_BATCHIM.has(low):
		return { "batchim": bool(_DIGIT_BATCHIM[low]), "ryul": false }
	if low >= "a" and low <= "z":
		return { "batchim": _LETTER_BATCHIM.has(low), "ryul": _LETTER_RYUL.has(low) }
	return { "batchim": false, "ryul": false }


# word 의 마지막 문자에 맞는 조사를 반환. pair 는 PAIRS 키("이가" 등).
static func pick(word: String, pair: String) -> String:
	if not PAIRS.has(pair):
		return ""
	var opts: Array = PAIRS[pair]
	var b: Dictionary = _batchim_of(word.substr(word.length() - 1, 1) if word.length() > 0 else "")
	if pair == "으로":
		return ("로" if (not bool(b["batchim"]) or bool(b["ryul"])) else "으로")
	return str(opts[0] if bool(b["batchim"]) else opts[1])


# word + 알맞은 조사.
static func attach(word: String, pair: String) -> String:
	return word + pick(word, pair)


# 텍스트 안의 "{이가}" 류 마커를 직전 문자의 받침에 맞춰 치환. 마커 없으면 원문 그대로.
static func apply(text: String) -> String:
	if not text.contains("{"):
		return text
	var out: String = ""
	var i: int = 0
	while i < text.length():
		var ch: String = text.substr(i, 1)
		if ch == "{":
			var close: int = text.find("}", i + 1)
			if close > i:
				var key: String = text.substr(i + 1, close - i - 1)
				if PAIRS.has(key):
					var prev: String = (out.substr(out.length() - 1, 1) if out.length() > 0 else "")
					out += pick(prev, key)
					i = close + 1
					continue
		out += ch
		i += 1
	return out
