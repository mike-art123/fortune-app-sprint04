# The Divan dataset — sourcing note (§9, §16)

Step one of the Hafez raw engine, done before any code, for the same reason the
audio licences were: a dataset is easy to drop in and hard to remove once forty
fortunes depend on it.

## What was found

**`github.com/ganjoor/ganjoor-db` — MIT licence.** Ganjoor is the reference
corpus for classical Persian poetry and the Divan sits inside it complete.

Two separate rights questions, and both have to be answered:

| | |
|---|---|
| The poem text | Hafez died in 1390. The verses are public domain everywhere; nobody can hold rights in them. |
| The database | The compilation — the numbering, the structure, the corrections — is Ganjoor's work, released under **MIT**. |

The second is the one people forget. Public-domain text does not make somebody
else's edition of it public domain.

## The obligation MIT actually creates

MIT is permissive but **not attribution-free**. It requires that the copyright
notice and permission text travel with the work. So if this data ships inside
BakhtNegar, Ganjoor must be credited — a line in the terms card or an "about
the sources" entry is enough, and it costs nothing.

Recorded now rather than discovered at release: the audio licences taught that
the paperwork is cheapest to do at the moment of choosing, not later.

## One thing to check before importing

The repo was **archived on 2021-10-03** and is read-only. The data is a
snapshot, not a maintained feed. Two consequences:

1. Corrections made to Ganjoor after 2021 are not in it. For the Divan — a
   settled text edited for a century — this matters far less than it would for
   a living corpus, but it should be a conscious choice rather than an
   accident.
2. Before importing, confirm the ghazal count in the dump. The Qazvini-Ghani
   edition has 495 ghazals; other editions differ. Whatever number the dump
   actually contains is the number to build against — do not assume 495 and
   discover later that the selection logic can pick a ghazal that is not there.

Ganjoor also publishes per-poet SQLite exports and a live API. If the archived
dump proves awkward, those are the alternatives to price — with their own
licence pages read, not assumed.

## Then, in order

1. `Ghazal` model in Prisma: number, opening line, verses, edition tag
2. A seed that imports the dump and asserts the count it claims to import
3. Stable selection — the same intention on the same day draws the same ghazal,
   because a fal that changes when you refresh is not a fal
4. The real ghazal into the prompt, at which point «بیت جعلی نساز» finally has
   something true to protect
5. The Hafez schema: `{ghazalId, poem, selectedVerses, messageOfThePoem,
   interpretationForIntention, hope, caution, practicalAdvice}`

## Status — 2026-07-27

Steps 1–2 of the order above are in the repo; the dump itself is a hand-off.

**Landed:** the `Ghazal` model (migration `20260727000000_hafez_ghazals`) —
`(edition, number)` unique, verses stored as JSON text, corpus rows written
only by the seed. `seedHafezGhazals()` in `prisma/seed.ts` reads
`prisma/data/hafez-ghazals.json`, asserts the count the file itself claims,
gapless numbering `1..count`, and opening-line/first-hemistich agreement,
then upserts per `(edition, number)`. While the JSON is absent the import
skips with one line, so the seed stays runnable everywhere today.

**Blocked on the dump** — the cloud workspace cannot download from GitHub,
so, by hand:

1. Download the archived repo: `github.com/ganjoor/ganjoor-db` → **Code →
   Download ZIP**.
2. Drop it, unextracted, at `data/hafez/ganjoor-db.zip` (`data/` is now
   gitignored). If the ZIP is unreasonably large, extract locally and drop
   only the `data/*.sql` dump files from inside it.
3. Next session: inspect the dump's real structure, write the extraction
   script against it (a MySQL dump, per that repo's README), emit the JSON
   with the same counts asserted at extraction time, and add the Ganjoor MIT
   attribution line to the terms card in the same change.

Open question, deliberately left undecided: how the corpus reaches the
production database. `railway.json` runs `prisma migrate deploy` on boot but
never the seed, so landing the JSON does not by itself populate prod. Options
priced so far: a data migration (rides the existing deploy, bloats migration
history), a boot-time import behind the engine's flag, or a one-off run. To
be settled when the selection step wires in.
