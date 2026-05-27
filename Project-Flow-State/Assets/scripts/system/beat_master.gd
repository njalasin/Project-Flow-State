##
##	Beat Master Script
##	After a confiugurable timer's delay this script uses Digital Signal Processing Time or DSP time
##	for audio scheduling
##

extends Node

@onready var audioPlayer = $AudioStreamPlayer

@export var bpm: int
@export var audioSource: AudioStream
@export var player_controller : PlayerController

var secondsPerBeat: float
var beatCount: int = 0

var songStartDSPTime: float
var started := false

func _ready() -> void: # Called once on this nodes instantiation
	player_controller = get_tree().get_first_node_in_group("player") # Find player and assign it to player_controller
	secondsPerBeat = 60.0 / bpm
func _process(delta): # Called every frame. 'delta' is the elapsed time since the previous frame.
	if not started:
		return
		
	# DSP-based song time
	var dspTime = AudioServer.get_time_since_last_mix() + AudioServer.get_output_latency()
	var songTimeDSP = dspTime - songStartDSPTime

	# Actual playback position
	var playbackTime = audioPlayer.get_playback_position()
	
	# Fix drifting
	var drift = playbackTime - songTimeDSP # Subtract the tracks elapsed time from the audio player

	if abs(drift) > 0.02: # 20 ms threshold
		songStartDSPTime -= drift

	# Calculate what beat we should be on
	var targetBeat = floor(songTimeDSP / secondsPerBeat)

	# Trigger missed beats safely
	while beatCount <= targetBeat:
		beatCount = beatCount + 1
		# print("Beat:", beatCount)
func _on_start_buffer_timeout(): # Timer is used here so it can delay the audio track from beginning before gameplay has begun
	audioPlayer.stream = audioSource
	audioPlayer.play()
	# Capture DSP start time with latency compensation
	songStartDSPTime = AudioServer.get_time_since_last_mix() + AudioServer.get_output_latency()

	started = true

func was_on_beat() -> bool:
	var dspTime = AudioServer.get_time_since_last_mix() + AudioServer.get_output_latency()
	var songTimeDSP = dspTime - songStartDSPTime
	
	# How far are we from the nearest beat?
	var beatInterval = fmod(songTimeDSP, secondsPerBeat)
	var distanceToNearestBeat = min(beatInterval, secondsPerBeat - beatInterval)
	
	print(distanceToNearestBeat)
	return distanceToNearestBeat <= .002
