# Project Flow State
A rhythm-driven FPS roguelike set in hand-crafted dungeons/levels, where every shot, dodge, and movement is synced to the beat of electronic music. Built in Godot.

Status: In active development (prototype stage)

# Concept
Players fight through roguelike dungeons where combat, movement, and dodging are timed to the beat of the soundtrack — missing the rhythm costs you precision and damage, while staying on-beat rewards higher damage and survivability. \
The long-term goal is both a quality hand-crafted singleplayer mode experienced through multiple hand-crafted levels complete with their own electronic soundtrack, and an endless mode where players can upload their own MP3s and generate looping dungeon runs synced to their own music.

# Planned / In-Progress Features
Rhythm-synced combat and movement — core gameplay loop built around timing actions to music \
FPS shooting and dodging mechanics — fast-paced first-person combat layered on top of the rhythm system \
Custom MP3 upload (planned) — endless mode where players can import their own music and generate levels/loops synced to it

# Tech Stack
Engine: Godot \
Key systems: finite state machines for character/enemy behavior, custom shader work for visual effects, character controller built for rhythm + FPS hybrid movement

# Running the Project
Install Godot (version 4.8 as of most recent commit) \
Clone the repo: \
git clone https://github.com/njalasin/Project-Flow-State.git \
Open the Project-Flow-State folder in the Godot editor and press Run

# Roadmap
Finalize core beat-detection and timing system \
Hand craft several levels for singleplayer content \
Build out enemy variety and combat encounters \
Add custom MP3 upload and endless mode \
Polish UI/UX and audio-visual feedback for beat accuracy

# About
This is a solo personal project built to explore rhythm-based game mechanics, finite and procedural level generation, as well as gameplay systems programming in Godot.