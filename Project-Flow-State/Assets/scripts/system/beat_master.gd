##
##	Beat Master Script
##	After a configurable timer's delay, this script uses Digital Signal Processing Time or DSP time
##	for audio scheduling
##

extends Node

@onready var audioPlayer = $AudioStreamPlayer
@onready var debug_label: Label = $CanvasLayer/DebugLabel  # adjust path

@export var bpm: int
@export var beatWindow: float
@export var audioSource: AudioStream
@export var player_controller : PlayerController
@export var debug : bool = false

var secondsPerBeat: float
var beatCount: int = 0
var songStartUsec: int = 0        # Monotonic clock start time (microseconds)
var songStartDSPTime: float
var started : bool = false

func _ready() -> void: # Called once on this nodes instantiation
	secondsPerBeat = 60.0 / bpm
	if debug:
		if debug_label:
			print("Label global position: ", debug_label.global_position, " visible: ", debug_label.visible, " in tree: ", debug_label.is_inside_tree())

func _process(delta): # Called every frame. 'delta' is the elapsed time since the previous frame.
	if !started:
		return

	# Stable, monotonic elapsed time since song start (in seconds)
	var songTimeDSP = (Time.get_ticks_usec() - songStartUsec) / 1_000_000.0

	# Actual playback position, latency-compensated
	# get_playback_position() is only updated once per mix, so we add the
	# small gap since the last mix to interpolate forward, then subtract
	# output latency to estimate what's actually audible right now.
	var playbackTime = audioPlayer.get_playback_position() \
		+ AudioServer.get_time_since_last_mix() \
		- AudioServer.get_output_latency()

	# Fix drifting
	var drift = playbackTime - songTimeDSP # Subtract the tracks elapsed time from the audio player

	if abs(drift) > 0.01: # 10 ms threshold
		# Re-anchor our monotonic clock's start point to absorb the drift
		songStartUsec -= int(drift * 1_000_000.0)

	# Calculate what beat we should be on
	var targetBeat = floor(songTimeDSP / secondsPerBeat)
	# Trigger missed beats safely
	while beatCount <= targetBeat:
		beatCount = beatCount + 1
		print("Beat:", beatCount)
	if debug:
		if debug_label:
			debug_label.text = "Beat: %d | Target: %.2f | Drift: %.4f | SongDSP: %.3f | Playback: %.3f" % [
				beatCount, targetBeat, drift, songTimeDSP, playbackTime
			]

func _on_start_buffer_timeout(): # Timer is used here so it can delay the audio track from beginning before gameplay has begun
	audioPlayer.stream = audioSource
	audioPlayer.play()
	# Capture the monotonic start time. We add output latency (converted to usec)
	# so our clock accounts for the delay before the first sample is actually heard.
	songStartUsec = Time.get_ticks_usec() - int(AudioServer.get_output_latency() * 1_000_000.0)
	started = true

func was_on_beat() -> bool:
	var songTimeDSP = (Time.get_ticks_usec() - songStartUsec) / 1_000_000.0
	# How far are we from the nearest beat?
	var beatInterval = fmod(songTimeDSP, secondsPerBeat)
	var distanceToNearestBeat = min(beatInterval, secondsPerBeat - beatInterval)

	return distanceToNearestBeat <= beatWindow
