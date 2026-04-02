# Character Pack Guide

## Folder Structure

```
CharacterPacks/{pack_id}/
├── pack.json                    # Pack configuration (required)
├── avatar.png                   # Avatar for popover header (square crop)
├── roast_bg.png                 # Toast background image
├── welcome.mp3                  # First-launch welcome voice
│
├── faces/                       # Face images for slap game
│   ├── idle.png                 # Normal state (level 0)
│   ├── hit_level_1.png          # Damage level 1 (1-3 hits)
│   ├── hit_level_2.png          # Flash on each slap impact
│   ├── hit_level_3.png          # Damage level 3 (8-12)
│   ├── hit_level_4.png          # Damage level 4 (13-20)
│   ├── hit_level_5.png          # Damage level 5 (21-30)
│   ├── hit_level_6.png          # Damage level 6 (31-40)
│   ├── hit_level_7.png          # Damage level 7 (41-49)
│   └── hit_ko.png               # Knockout state (50+)
│
├── emojis/                      # Toast notification avatars (random pick)
│   ├── {name}_00.png
│   ├── {name}_01.png
│   └── ... (recommended: 20-36 PNGs)
│
├── menubar_frames/              # Menu bar run-cycle animation
│   ├── frame_00.png
│   ├── frame_01.png
│   └── ... (recommended: 6-8 PNGs, 18x18 display size)
│
├── slap_voices/                 # Voice lines when slapped
│   ├── slap_voice_1.mp3
│   ├── slap_voice_2.mp3
│   └── ... (recommended: 20-32 MP3s)
│
├── milestone_voices/            # Milestone celebration voices
│   ├── 50_1.mp3, 50_2.mp3, 50_3.mp3
│   ├── 100_1.mp3, 100_2.mp3, 100_3.mp3
│   ├── 150_1.mp3, 150_2.mp3, 150_3.mp3
│   └── 200_1.mp3, 200_2.mp3, 200_3.mp3
│
├── sounds/                      # Sound effects
│   ├── slap_impact.mp3          # Normal slap sound
│   ├── slap_impact_heavy.mp3    # Heavy slap variant
│   ├── umph.mp3                 # Reaction grunt
│   ├── ko_falling.wav           # KO falling sound
│   └── ko_landing.wav           # KO landing thud
│
└── roasts/                      # Roast voice lines (optional)
    ├── roast_1.mp3
    └── ...
```

## pack.json Schema

```json
{
  "id": "pack_id",
  "displayName": "Character Name",
  "language": "en",
  "description": "Short description of the character personality",
  "icon": "idle",
  "slapLimit": 32,
  "slap": {
    "animationStyle": "shake",
    "slapSound": "slap_impact",
    "slapVoiceCount": 32,
    "faces": {
      "normal": "idle",
      "hit": "hit_level_2",
      "damaged1": "hit_level_1",
      "damaged2": "hit_level_2",
      "damaged3": "hit_level_3",
      "damaged4": "hit_level_4",
      "damaged5": "hit_level_5",
      "damaged6": "hit_level_6",
      "damaged7": "hit_level_7",
      "ko": "hit_ko",
      "rage": null
    },
    "reactions": [
      {
        "minHits": 1,
        "texts": [
          { "text": "Reaction line", "voice": "slap_voice_1" }
        ]
      },
      { "minHits": 4, "texts": [...] },
      { "minHits": 8, "texts": [...] },
      { "minHits": 16, "texts": [...] }
    ],
    "rageReaction": {
      "text": "Rage message!",
      "voice": "slap_voice_rage"
    }
  },
  "roasts": {
    "lid_open": [...],
    "lid_reopen": [...],
    "late_night": [...],
    "early_morning": [...],
    "thermal": [...],
    "idle": [...],
    "screen_time": [...],
    "app_switch": [...],
    "slap": [...]
  }
}
```

## Roast Template Format

```json
{
  "id": "unique_template_id",
  "text": "You opened this lid {count} times. Looking for meaning?",
  "variables": ["count"],
  "weight": 1.0,
  "voice": "roast_lid_1"
}
```

### Available Variables

| Variable | Trigger Types | Description |
|----------|--------------|-------------|
| `{count}` | lid_open, app_switch | Event count today |
| `{app}` | app_switch | Current app name |
| `{time}` | late_night, early_morning | Formatted time (h:mm a) |
| `{seconds_since_close}` | lid_reopen | Seconds since lid closed |
| `{idle_minutes}` | idle | Minutes idle |
| `{minutes}` | screen_time | Screen time minutes |
| `{thermal}` | thermal | Thermal state string |
| `{total_today}` | slap | Total roasts today |
| `{hour}` | late_night, early_morning | Current hour |

## Asset Counts (Trump Pack Reference)

| Category | Count | Format |
|----------|-------|--------|
| Roast templates | 96 | JSON (in pack.json) |
| Emojis | 36 | PNG |
| Slap voices | 32 | MP3 |
| Menubar frames | 7 | PNG |
| Face images | 9 | PNG |
| Milestone voices | 12 | MP3 (3 per milestone × 4) |
| Sound effects | 5 | MP3/WAV |
| Welcome voice | 1 | MP3 |
| UI assets | 2 | PNG (avatar, roast_bg) |
| **Total files** | **~170** | |

### Roast Templates by Trigger

| Trigger | Count | With Voice |
|---------|-------|------------|
| slap | 20 | 20 |
| lid_open | 15 | 15 |
| idle | 10 | 10 |
| late_night | 10 | 10 |
| screen_time | 10 | 10 |
| app_switch | 10 | 0 |
| thermal | 8 | 8 |
| lid_reopen | 7 | 7 |
| early_morning | 6 | 6 |

## Animation Styles

- `shake` — Horizontal shake on slap
- `bounce` — Bouncy vertical movement
- `jiggle` — Random jiggle
- `spin` — Rotation on slap

## Notes

- Face image paths in pack.json are **without extension** (`.png` added automatically)
- Voice paths in reactions are **without extension** (`.mp3` resolved by SoundPlayer)
- `slapVoiceCount` must match the number of `slap_voice_N.mp3` files
- Emojis are randomly picked for toast notifications — more variety = better
- Menubar frames play as run-cycle animation, speed scales with CPU usage
- `weight` in roast templates controls selection probability (default 1.0, with cooldown decay)
