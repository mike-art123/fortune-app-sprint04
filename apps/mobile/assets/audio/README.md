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

All eight files came from **Pixabay** (sound effects and music) and **Mixkit**,
both of which the owner browsed on 2026-07-26. Terms below were read from the
sources on that date.

| File | Source | Licence |
|---|---|---|
| ambient/night.mp3 | Pixabay or Mixkit — see the gap below | Pixabay Content License / Mixkit Free License |
| ambient/rain.mp3 | Pixabay Sound Effects | Pixabay Content License |
| ambient/candle.mp3 | Pixabay Sound Effects (fireplace) | Pixabay Content License |
| ambient/persian.mp3 | Pixabay Music (oriental) | Pixabay Content License |
| ambient/santur-ney.mp3 | Pixabay or Mixkit — see the gap below | Pixabay Content License / Mixkit Free License |
| ambient/piano.mp3 | Pixabay Music (piano) | Pixabay Content License |
| ritual/offering.mp3 | Pixabay Sound Effects (chime or magic) | Pixabay Content License |
| ritual/reveal.mp3 | Pixabay Sound Effects (chime or magic) | Pixabay Content License |

### What the two licences allow

**Pixabay Content License** (read 2026-07-26 at
<https://pixabay.com/service/license-summary/>): free to use, **no attribution
required**, and modification is expressly allowed. The prohibition that matters
is selling or distributing content *standalone* — Pixabay defines standalone as
"where no creative effort has been applied to the Content and it remains in
substantially the same form as it exists on our website". These files are
re-levelled, re-encoded, one of them trimmed, and they play as a background
layer inside a larger work, so this use is not standalone distribution.

**Mixkit Free License** (read 2026-07-26 at <https://mixkit.co/license/> and
<https://mixkit.co/llm-info/>): commercial use allowed, no attribution required;
copies may not be sold without applying skill and effort, and items may not be
made available to third parties as items. Same conclusion.

### The honest gap

**The individual track pages were not recorded.** Both licences permit this use
without attribution, so nothing is blocked — but if a source is ever
questioned, "it came from Pixabay" is weaker evidence than a URL.

Worth five minutes before release: reopen the download history on each site and
paste the track URL and author into the table above. Two reasons beyond
tidiness — Pixabay hosts community uploads, so a track can occasionally be
re-uploaded by somebody who does not hold the rights, and a licence page can
change. A URL and a date make both answerable later.

## What was done to the delivered files

The originals were ~30 MB in total and their levels were 30 dB apart, which
would have made switching bed to bed a shock. Each file was:

- **levelled** to a common −26 LUFS (accents to −21, so they carry over the
  bed), two-pass, with a −2 dBTP ceiling — static gain, so nothing was
  compressed or squashed;
- **re-encoded** for mobile data: textural beds (شب/باران/شمع) to mono 64 kbps,
  where noise-like material is transparent; musical beds
  (ایرانی/سنتور و نی/پیانو) kept in stereo at 96 kbps;
- **candle trimmed** from five minutes to ninety seconds. Crackle has no melody,
  so a cut leaves no audible seam, and five minutes of it is more than a loop
  needs.

Total went from ~30 MB to 8.5 MB, and none of it is downloaded until somebody
turns sound on and picks a bed. The untouched originals are outside the repo.

«طبیعت» was not wanted, so its file is absent and the app does not offer it.
