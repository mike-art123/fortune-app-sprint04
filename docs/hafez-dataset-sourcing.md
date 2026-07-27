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

Steps 1–2 are done and the corpus is in the repo.

**Model + migration** `20260727000000_hafez_ghazals` and the counting seed
landed first. Then the dump itself: `ganjoor-db` at commit `7ce93971`
(data dated **2017-11-09**), fetched straight into `data/hafez/` on the
owner's machine; sha256
`b222390c610755eaeeff87c0854bd7450691cf208f9f47078e130f91ffc7deb1`,
verified identical after transfer to the workspace.

**Extraction** — `scripts/extract-hafez-ghazals.mjs` (node, zero
dependencies) parses the MySQL dump character by character and emits
`apps/api/prisma/data/hafez-ghazals.json`: **495 ghazals** — the
Qazvini-Ghani count — numbered 1..495 with no gaps, 4192 couplets. It
refuses to emit unless every check holds: the غزلیات category found by
content rather than remembered ids, each ghazal's number proved twice (the
url's `sh<N>` against the Persian numeral in its title), hemistich positions
alternating 0/1, nothing empty.

**Verified against the world:** the JSON round-trips byte-identically
through a real Postgres 16 `ghazals` table built from the committed
migration, and ghazals 1, 255 and 495 were compared with the live Ganjoor
API — word for word identical. One knowing difference: the live corpus has
gained tashkeel and punctuation since 2017 («یوسفِ گم‌گشته … کنعان، غم مخور»
against the dump's plain «یوسف گمگشته … کنعان غم مخور»). The plain text is
the classic form and ships as edition `ganjoor-db-2017`; if diacritics are
ever wanted, a re-import from the live API is a new edition tag — visible by
design, never a silent drift.

**Attribution (the MIT obligation):** the full licence text travels with the
repo at `docs/licenses/ganjoor-db-MIT.txt`, the JSON carries the copyright
line in its `source` field, and the terms card on the profile screen now
credits Ganjoor in plain Persian.

## The engine, wired — 2026-07-27, later that night

Steps 3–5 now exist on the server, behind the flag `hafez.raw-engine`
(off by default). `HafezReadingProvider` decorates the ordinary provider:
every fortune that is not Hafez — and Hafez itself while the flag is off —
passes through untouched, byte for byte.

**Selection is global, not per-user.** The Divan is one book: the same words
brought to it on the same day open the same page, and what differs between
two readers is the interpretation, which is where the person belongs. The
draw is SHA-256 over `edition + dateKey (app timezone) + normalized
intention` — Arabic variants folded, digits unified, whitespace collapsed,
so «سلامتي» and «سلامتی» are one intention — mapped into `1..count`.

**The corpus reaches production lazily**, which settles the open question
that used to sit here: the JSON already ships inside the deploy
(`prisma/data` is copied into the image), and the first reading with the
flag on validates the file and upserts all 495 rows idempotently. No seed
step in the deploy, no data bloating the migration history, and a fresh
environment heals itself. The seed keeps its own import for development
databases.

**The prompt carries the real ghazal**, and the reply is refused unless
every quoted verse is found in that poem — matching ignores spacing and
ZWNJ, and the canonical corpus text replaces whatever the model typed, so
«بیت جعلی نساز» is enforced by the parser rather than requested in prose.
The reply follows the step-5 schema; for now it is flattened into the
reading text (the whole ghazal first, then its reading, ending on
«برای امروز:») so the client needs no change today. Next: the client's own
Hafez surface, rendering the schema fields as parts, and storing them.

To turn it on later, from Railway → Postgres → Console (cached ~30s;
`updated_at` is not optional — same lesson as the notifications flag):

```sql
insert into feature_flags (key, enabled, note, updated_at)
values ('hafez.raw-engine', true, 'hafez raw engine on', now())
on conflict (key) do update set enabled = true, updated_at = now();
```
