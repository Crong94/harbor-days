extends Node
## 배경음악과 효과음. 오토로드 이름: Sound
## 소리 파일은 바다 한 접시(이전 게임)에서 가져왔다. assets/audio/bgm, assets/audio/sfx
## 없는 소리 이름을 불러도 조용히 넘어간다.

const BGM_DIR := "res://assets/audio/bgm/"
const SFX_DIR := "res://assets/audio/sfx/"
const SFX_VOICES := 6

## 장면에서 쓰는 배경음악 이름
const BGM := ["title", "sea", "town", "market", "truck"]

var bgm_volume_db := -8.0
var sfx_volume_db := -4.0
## 설정 메뉴에서 켜고 끈다
var bgm_on := true
var sfx_on := true

var _music: AudioStreamPlayer
var _music_id := ""
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.volume_db = bgm_volume_db
	add_child(_music)
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.volume_db = sfx_volume_db
		add_child(p)
		_voices.append(p)


static func has_sfx(id: String) -> bool:
	return ResourceLoader.exists(SFX_DIR + id + ".ogg")


static func has_bgm(id: String) -> bool:
	return ResourceLoader.exists(BGM_DIR + id + ".ogg")


## 배경음악을 바꾼다. 같은 곡이면 이어서 튼다. 빈 문자열이면 멈춘다.
func play_bgm(id: String, fade := 0.8) -> void:
	if id == _music_id and _music.playing:
		return
	_music_id = id
	var tw := create_tween()
	if _music.playing:
		tw.tween_property(_music, "volume_db", -40.0, fade * 0.5)
	tw.tween_callback(func():
		_music.stop()
		if id.is_empty() or not has_bgm(id):
			return
		var s: AudioStream = _load(BGM_DIR + id + ".ogg")
		if s is AudioStreamOggVorbis:
			s.loop = true
		_music.stream = s
		_music.volume_db = -40.0
		_music.play())
	tw.tween_property(_music, "volume_db", _bgm_db(), fade)


func _bgm_db() -> float:
	return bgm_volume_db if bgm_on else -80.0


func set_bgm_on(on: bool) -> void:
	bgm_on = on
	if _music:
		_music.volume_db = _bgm_db()


func set_sfx_on(on: bool) -> void:
	sfx_on = on


func stop_bgm(fade := 0.8) -> void:
	play_bgm("", fade)


## 효과음을 한 번 튼다. pitch_jitter를 주면 같은 소리가 반복돼도 덜 단조롭다.
func play_sfx(id: String, pitch_jitter := 0.0, volume_offset_db := 0.0) -> void:
	if not sfx_on or not has_sfx(id):
		return
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	p.stream = _load(SFX_DIR + id + ".ogg")
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.volume_db = sfx_volume_db + volume_offset_db
	p.play()


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path)
	return _cache[path]


func _exit_tree() -> void:
	# 게임을 끌 때 재생 중인 소리를 놓아 준다 (종료 시 자원 남음 경고 방지)
	_music.stop()
	_music.stream = null
	for p in _voices:
		p.stop()
		p.stream = null
	_cache.clear()
