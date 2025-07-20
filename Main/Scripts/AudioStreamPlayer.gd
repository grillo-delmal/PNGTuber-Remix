extends AudioStreamPlayer

const MIN_DB: int = 80
var record_bus_index 
var record_effect : AudioEffectRecord

const VU_COUNT = 4
const HEIGHT = 40
const  MAX_FREQ = 11050.0
const MIC_RESTART_TIME: float = 1800
const MIC_RESTART_TIME_FIX: float = 600
var bar_stuff = []
var used_bar = 0

var t = {
	value = 0,
	actual_value = 0,
}

var actual_value : float = 0.0
var mic_restart_timer : Timer = Timer.new()


var _fingerprint := LipSyncFingerprint.new()
var _matches := []
# Called when the node enters the scene tree for the first time.
func _ready():
	mic_restart_timer.timeout.connect(mic_restart_timer_timeout)
	mic_restart_timer.one_shot = false
	add_child(mic_restart_timer)
	record_bus_index = AudioServer.get_bus_index("Mic")
	record_effect = AudioServer.get_bus_effect(record_bus_index, 0)
	await get_tree().current_scene.ready
	mic_restart_timer.wait_time = MIC_RESTART_TIME
	mic_restart_timer.start()
	global_lipsync()

func change_mic_restart_time(delay_fix := false) -> void:
	mic_restart_timer.wait_time = MIC_RESTART_TIME_FIX if delay_fix else MIC_RESTART_TIME

func mic_restart_timer_timeout():
	stop()
	record_effect.set_recording_active(false)
	await get_tree().physics_frame
	await get_tree().physics_frame # Added second frame just to be safe
	play()
	record_effect.set_recording_active(true)

func global_lipsync():
	_fingerprint.populate(LipSyncGlobals.speech_spectrum)

	# Calculate the matches
	LipSyncGlobals.file_data.match_phonemes(_fingerprint.values, _matches)

	# Populate the bars
	t = {
	value = 0,
	actual_value = 0,
	}
	
	
	for phoneme in Phonemes.PHONEME.COUNT:
		var deviation: float = _matches[phoneme]
		var value := 0.0 if deviation < 0.0 else 1.0 - deviation
		if get_tree().get_root().has_node("Main/LipsyncConfigurationPopup"):
			get_tree().get_root().get_node("Main/LipsyncConfigurationPopup/%PhBox").get_child(phoneme).value = value
			
		if value > t.value:
			t.value = value
			actual_value = phoneme
			t.actual_value = actual_value
			
	await get_tree().create_timer(0.05).timeout
	global_lipsync()
