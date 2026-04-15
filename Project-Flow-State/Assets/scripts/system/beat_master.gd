extends Node

@onready var audioPlayer = $AudioStreamPlayer

@export var bpm: int
@export var audioSource: AudioStream

var secondsPerBeat: float
var beatCount: int = 0

var songStartDSPTime: float
var started := false

func _ready() -> void:
	secondsPerBeat = 60.0 / bpm
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not started:
		return
	# DSP-based song time
	var dspTime = AudioServer.get_time_since_last_mix() + AudioServer.get_output_latency()
	var songTimeDSP = dspTime - songStartDSPTime

	# Actual playback position
	var playbackTime = audioPlayer.get_playback_position()
	
	# Fix drifting
	var drift = playbackTime - songTimeDSP

	if abs(drift) > 0.02: # 20 ms threshold
		songStartDSPTime -= drift

	# Calculate what beat we should be on
	var targetBeat = floor(songTimeDSP / secondsPerBeat)

	# Trigger missed beats safely
	while beatCount <= targetBeat:
		beatCount = beatCount + 1
		print("Beat:", beatCount)
func _on_start_buffer_timeout():
	audioPlayer.stream = audioSource
	audioPlayer.play()
	
	# Capture DSP start time with latency compensation
	songStartDSPTime = AudioServer.get_time_since_last_mix() + AudioServer.get_output_latency()

	started = true
