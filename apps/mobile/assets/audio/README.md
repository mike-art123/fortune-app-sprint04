# Audio assets (scope §1)

The code is finished and silent. Dropping licensed files here is what turns
ambient sound on — nothing else needs writing.

## Where the files go

```
assets/audio/ambient/night.mp3        شب
assets/audio/ambient/rain.mp3         باران
assets/audio/ambient/candle.mp3       شمع
assets/audio/ambient/nature.mp3       طبیعت
assets/audio/ambient/persian.mp3      ایرانی
assets/audio/ambient/santur-ney.mp3   سنتور و نی
assets/audio/ambient/piano.mp3        پیانو

assets/audio/ritual/offering.mp3      the moment an offering is sealed
assets/audio/ritual/reveal.mp3        the moment a reading appears
```

Filenames are not negotiable — they are derived in
`lib/features/audio/domain/audio_theme.dart` from the theme id, so a typo shows
up as a theme that is simply never offered.

**Not all seven are needed.** One is enough: the app offers exactly the beds
whose files exist, and the settings card is absent entirely while none do.

## The two edits after adding files

1. `pubspec.yaml` → under `assets:` add the folders you actually filled:

   ```yaml
       - assets/audio/ambient/
       - assets/audio/ritual/
   ```

2. `AudioThemes.bundled` in `lib/features/audio/domain/audio_theme.dart` → list
   the exact paths you added.

`test/features/audio/ambient_audio_test.dart` compares those two lists and fails
if they disagree, naming which one is behind. It also fails on purpose the first
time `bundled` stops being empty — that test is the checklist for this file.

## What the files should be

| | |
|---|---|
| Format | mp3 (changing this means changing one line in `audio_theme.dart`) |
| Ambient length | 30–90 seconds; the element loops, so the head and tail must meet without a seam or an audible fade |
| Ambient loudness | quiet enough to sit under text — roughly −24 to −30 LUFS, so the default 40% volume is genuinely background |
| Ritual sounds | under two seconds, soft, no startle |
| Size | this ships as a Telegram Mini App over mobile data; keep each file well under 2 MB (mono, 96–128 kbps is plenty for ambience) |
| Channels | mono is fine and halves the download |

## Licence log

Ambient beds need commercial-use rights for a paid app. Record each one here as
it is added, so the paperwork lives with the files rather than in an inbox.

| File | Source | Licence | Purchased / obtained |
|---|---|---|---|
| _(none yet)_ | | | |
