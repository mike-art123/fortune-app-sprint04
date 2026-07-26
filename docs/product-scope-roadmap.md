# BakhtNegar — Official Product Scope & Executable Roadmap

This document is the binding scope for the sixteen capability areas ordered by
the owner. **Nothing here may be dropped, simplified away, or silently
deferred.** Where full delivery needs multiple technical phases, every phase is
listed below; all capabilities remain in official scope.

References: fortune-app-visual-design-report.pdf, fortune-app-strategy-report,
the 50-document blueprint, and the existing Flutter Web + NestJS + Telegram
Mini App architecture (router/AppBack navigation, ApiClient, AI reading layer,
history, envelope contract). No decision below contradicts them.

## Codebase audit (current state, verified in source)

| Area | Exists today | Gap |
|---|---|---|
| User identity | `User` row per verified Telegram id; has `displayName` (Telegram-suggested), `locale` | No birth month, no onboarding state; login upsert overwrites name |
| Profile API | none (users module has service only) | GET/PATCH profile, onboarding endpoints |
| AI reading layer | `prompt-builder` (manifesto voice rules, JSON contract), mock + LLM providers | No profile context; no name personalization |
| Search / AI assistant | none (fortunes grid only) | Whole of section 2/3 |
| Audio | none | Whole of section 1 (also needs licensed sound assets — external) |
| Personalization | history exists (readings per user) | No preference profile, no engine |
| Recommendations | none post-reading | Section 5 |
| History summary | history list + reading fetch | AI summary/compare + cache |
| Notifications | Telegram bot webhook exists | Whole preference/scheduling layer |
| Reflection journal | none | Section 8 |
| Feature flags | `FEATURE_FLAGS_SOURCE` env plumbing on API | Per-feature flags to be defined |

Architecture decision (anti-duplication rule of this order): profile fields
extend the existing `User` model — `displayName`/`locale` already live there;
a parallel `UserProfile` table would duplicate them. `profileVersion` covers
optimistic concurrency. Reading personalization keeps `userId` as the owner
reference; the generated text is itself the historical snapshot (a reading is
never rewritten when the name later changes) — policy: history shows the text
as generated (snapshot-in-text), current name is used only for new readings.

## Phases (all in scope; flags default OFF except Phase 1)

- **Phase 1 — Onboarding + real-name personalization (§16)** — implemented
  now (this commit). Flag: `profile_onboarding` (ON).
- **Phase 2 — Ambient audio + ritual sound (§1)** — central AudioService,
  themes (شب/باران/شمع/طبیعت/ایرانی/سنتور-نی/piano), fades, focus handling,
  persisted prefs. Needs licensed audio assets (external dependency). Flag:
  `ambient_audio`.
- **Phase 3 — Universal AI bar (§2) + voice (§3)** — hybrid pipeline (exact →
  prefix → fuzzy → alias → intent → AI), fa normalization (ی/ك/نیم‌فاصله),
  action-schema navigation (never raw-text nav), guardrails; Web Speech API
  for fa voice with permission/timeout/cancel UX. Flags: `ai_bar`,
  `voice_search`.
  - **3a — deterministic core (done, this commit)**: fa folding, the in-app
    index over all 39 registry fortunes + curated aliases, bounded typo
    tolerance, the `SearchAction` guardrail and the search bar on «همه فال‌ها».
  - **3b — sentences by rule (done)**: trigger rules over folded tokens
    reaching four fixed screens and three fortunes, through the same guardrail.
  - **3c — voice (done)**: Web Speech API behind an injectable interface,
    fa-IR, interim words, permission/silence/stop handling, no audio kept.
  - **3d — AI fallback (done)**: `POST /search/interpret` behind the
    `search.ai-bar` flag, a closed action schema validated on both ends, and a
    client that asks only when the person taps «از دستیار بپرس».
- **Phase 4 — Personalization engine (§4) + next-fortune recs (§5)** —
  `UserPreferenceProfile`, time-of-day + category affinity, ≤3 premium cards
  with reason line, opt-out. Flags: `personalization`, `next_recs`.
- **Phase 5 — History AI summary/compare (§6) + smart notifications (§7)** —
  `AISummaryCache` (range-keyed), source-linked summaries, delete-respecting;
  notification prefs (categories, quiet hours, caps, tz) delivered via the
  existing Telegram bot first. Flags: `history_summary`, `smart_notifications`.
- **Phase 6 — Reflection journal (§8)** — per-reading reflection (feeling +
  text), private, timeline, search/filter, AI micro-questions with crisis-safe
  behaviour. Flag: `reflection_journal`.
- **Cross-cutting (§9–§15)** — shared design system/state/analytics/API
  envelope; data models below; analytics events (never raw private text);
  tests per feature; UX identity (Calm/Premium/Personal/Trustworthy/RTL).

## Data models (target inventory)

Done in Phase 1: `User.birthMonth (enum BirthMonth)`, `onboardingCompleted`,
`onboardingCompletedAt`, `profileVersion`.
Later phases: `UserAudioPreferences`, `AudioTheme` (static config),
`FortuneSearchIndex` + `FortuneAlias` (build-time index), `AIIntent`,
`AIAction` (schema, validated), `UserPreferenceProfile`,
`FortuneRecommendation` (event log), `ReflectionEntry`, `ReflectionSummary`,
`NotificationPreference`, `NotificationEvent`, `VoiceSearchSession`
(ephemeral, no audio retention), `AISummaryCache`. Each ships with schema,
validation, indexes, retention/privacy/deletion behaviour, endpoints, tests —
in its phase.

## API surface (Phase 1 delivered)

- `GET  /api/v1/profile` — current profile.
- `GET  /api/v1/profile/onboarding-status` — `{onboardingCompleted}`.
- `POST /api/v1/profile/onboarding` — idempotent; validates name/month;
  completes onboarding; repeat calls never corrupt data.
- `PATCH /api/v1/profile` — edit name/month; bumps `profileVersion`.
All authenticated; standard envelope.

## Privacy & guardrails (binding)

Name and birth month are personal data: never in analytics values, ad
callbacks, URLs/deep links, or production logs (masked); share text defaults
to name-free (client strips the leading name clause); AI treats
`displayName` strictly as data (injection-neutralized), never invents or
translates it, uses it at most once or twice, no «کاربر عزیز X». The
manifesto voice rules (no certainty, no fear, no medical/financial/legal
claims) bind every AI feature in all phases.

## Analytics (event names reserved; no private payloads)

audio_enabled/disabled/theme_selected, ritual_sound_played, search_started,
search_result_clicked, fuzzy_search_used, ai_intent_detected,
voice_search_started/completed/failed, recommendation_shown/clicked,
history_summary_generated, reflection_started/saved, notification_opt_in/
clicked, onboarding_started/name_completed/birth_month_completed/completed/
failed, profile_name_updated, profile_birth_month_updated.

## Known external dependencies & costs

- Licensed ambient/ritual audio files (Phase 2) — owner-provided.
- LLM cost: onboarding adds ~40 tokens/reading (name context). AI bar/summary
  phases add per-call costs; summaries cached per range to avoid repeats.
- Web Push / mobile push (Phase 5+) — service credentials when mobile ships.

## QA in Telegram (per phase)

Real-device pass: onboarding first-run, second-run skip, cross-device skip,
deep-link → onboarding → original destination, name in result, share without
name, profile edit reflected in next reading.

## Phase 1 delivery report (onboarding + real-name personalization)

Built new: `BirthMonth` enum and four `User` columns (`birth_month`,
`onboarding_completed`, `onboarding_completed_at`, `profile_version`) with
migration `20260726030000_user_profile_onboarding`; `ProfileController`
(`GET /profile`, `GET /profile/onboarding-status`, idempotent
`POST /profile/onboarding`, `PATCH /profile`) with `CompleteOnboardingDto` /
`UpdateProfileDto`; profile feature on the client (repository, domain with the
shared twelve months, controller, 3-step onboarding ritual, month pill,
edit sheet) plus the `/onboarding` route and its gate.

Extended (no parallel system): `UsersService` now normalizes and stores the
confirmed name — a Telegram first name stays a suggestion and is never allowed
to overwrite it after onboarding; `ReadingProvider.generate` gained an optional
`ReadingProfileContext`, threaded through the AI provider, the mock provider and
`ReadingsService`, which passes the name only when onboarding is complete;
`ReadingPage` share strips the leading name; the profile screen shows the real
name and birth month with an in-place editor.

Guarantees: the backend is the only source of onboarding truth (new device or
cleared cache never re-asks); repeat submits are idempotent; the app holds the
splash until the gate decides, so the main UI never flashes first; a deep link
rides along as `?next=` and resumes after the ritual; the name is neutralized
before reaching a prompt (quotes/newlines stripped, capped at 40 chars, marked
as data) and never appears in analytics values, ad callbacks, URLs or default
share text; readings keep the name they were written with (no rewrite on
rename).

Tests: `users.service.spec` (create/refresh/never-overwrite, normalization,
idempotence, markup stripping, validation, version bump, NOT_FOUND),
`prompt-builder.spec` (injection neutralized, persona omitted when absent),
`mock-reading.provider.spec` (name opens the reading exactly once; impersonal
without it), `route_guards_test` (full gate matrix incl. `?next=` encoding),
`onboarding_page_test` (all steps, validation, retry keeps choices,
already-onboarded skip, hand-off to `next` and to the fallback),
`user_profile_test` (share strip, months), `reading_page_test` (share hides the
name). Formatting verified with the real `dart format` (DartPad API) and
prettier 3.3.3 on every changed file or region.

Not in this phase (still in scope, later phases): ambient audio, AI bar, voice
search, personalization, recommendations, history summary, notifications,
reflection journal. No new environment variables; deploy is the usual CI
`prisma migrate deploy` + Pages build.

## Phase 3a delivery report (deterministic search core)

Scope covered: §2 first stage — "ask by name" beats browsing. A person types
what they call the fortune and lands on it, however they spell it.

What shipped: `fa_text.dart` (folding — Arabic ي/ك/ة/أ/إ/آ/ٱ/ؤ onto Persian
letters, tashkeel + superscript alef + tatweel dropped, Persian/Arabic-Indic
digits to ASCII, ZWNJ/punctuation/emoji as word boundaries, plus a bounded edit
distance that stops as soon as the ceiling is passed); `fortune_search.dart`
(index over all registry fortunes: full title, title words, subtitle words,
curated aliases, id — ranked exact 1000 → prefix 800−overshoot → contains 600 →
typo 500−60·distance, ties broken openable-first then shortest title then id);
`search_action.dart` (sealed `SearchAction`: open / soon / nothing);
`fortune_destinations.dart` (one shared map — the grid and search now read the
same source, so a card and a result can never disagree); `FortuneSearchBar` on
«همه فال‌ها» above the themed sections.

Guarantees: typed text never becomes a route — a tap resolves through
`SearchActions.forFortune`, which validates the id (`RouteParams.isValidId`),
then the shared destination map, and returns something that cannot navigate for
anything unknown or malformed. Typo tolerance is bounded by query length
(≤3 chars: none), so «گل» can never be guessed into «دل». Guided fortunes
(coffee, elements) resolve to their guide and are never labelled «به‌زودی».
Everything is offline and deterministic — no network, no model, no query text
logged anywhere.

Tests: `fa_text_test` (each folding rule, boundaries, digits, bounded
distance), `fortune_search_test` (index covers the registry; every fortune is
findable by its own Persian title; exact/prefix/alias/Arabic-keyboard/نیم‌فاصله
/typo; short-word safety; empty and gibberish ask nothing; limit and ordering;
action guardrails incl. "no searchable fortune is a dead end"),
`fortune_search_bar_test` (quiet until asked, partial name opens the ritual,
Arabic-keyboard alias lands, guided fortune opens its guide, calm empty state
and clearing), `fortune_destinations_test` (ritual vs guide vs nowhere; every
live fortune has a destination). Ranking was additionally replayed against the
real registry data before commit. Formatting verified with the real
`dart format` at the package language version (3.6) on all ten touched files.

Not in 3a: intent parsing and the AI fallback (3b), voice (3c).

## Phase 3b delivery report (sentences, answered by rules)

Scope covered: §2 second stage. People do not only type names — they type
«برام یه فال بگیر» or «تاریخچه‌ام رو ببین». The index answers names; this layer
answers sentences.

What shipped: `search_intent.dart` — trigger rules over folded tokens, scored
by how many words of the strongest trigger the sentence contains (every word
must be present, so «فال بگیر» never fires on «فال حافظ»); Persian possessives
and plurals glued to the noun («پروفایلم», «سابقه‌ام», «اشتراکم») match by
prefix, short words stay exact. Rules reach four fixed screens (تاریخچه،
پروفایل، اشتراک ویژه، همه فال‌ها) and three fortunes (فال روزانه، بله یا خیر،
تعبیر خواب). `OpenDestinationAction` joins the sealed action family; the search
bar now resolves every tap — a fortune row or an intent row — through one
`_run(SearchAction)`, and both row kinds are the same widget.

Guarantees: a route path is always a constant from `AppRoutes`, never assembled
from typed text, and a fortune intent still goes through the shared destination
map, so an intent can never outrank availability. The intent stage runs only
when the index found nothing, so names always win. Every match names its
destination and adds one calm line before anything opens. Rules only cover
phrasings the index cannot already answer — no alias is repeated as a rule.
Still offline, still free, still the same answer every time.

Tests: `search_intent_test` (eleven real sentences → the exact screen, the
possessive forms, label/hint always present, named fortunes left to the index,
small talk and noise ask nothing, and the guardrail that a sentence can never
invent a destination or misname a fortune), plus a bar test that types a whole
sentence and lands on the history screen. Rule reachability and every sentence
were replayed against the real registry before commit; `dart format` verified
at the package language version on all five touched files.

Not in 3b: the AI fallback for sentences no rule covers, and voice (3c).

## Phase 3c delivery report (speaking to the app)

Scope covered: §3. Saying «فال حافظ» is shorter than typing it, and for someone
who does not type Persian comfortably it is the only short path.

What shipped: `speech_event.dart` (what the microphone reports: interim and
settled words, or an ending with its reason), `speech_recognition.dart` with
the usual stub/web conditional export — the web file drives the browser's Web
Speech API through `dart:js_interop`, the stub simply reports "cannot listen"
so `flutter test`, `analyze` and native targets never load it —
`speech_input.dart` (the interface the search bar sees, plus the platform
implementation with a silence timeout that restarts on every word), and the
microphone button in the search bar: interim words appear in the box and are
searched as they arrive, the settled reading closes the microphone, and the
result rows are the ones already built for typing.

Guarantees: the microphone is offered only where the browser can actually
listen — no dead button, no pointless permission prompt. No audio is recorded,
stored or sent by the app; only recognised text crosses the boundary, and it
lives in the text field like anything typed. Cancelling the subscription
aborts recognition, so tapping stop, clearing, or leaving the screen all close
the microphone rather than forgetting it. Refusal, silence, an unsupported
browser and an unknown failure each get their own plain line that never blames
the person and always leaves a next step (بنویس).

Tests: `voice_search_test` with a fake microphone — the button appears only
when hearing is possible, a spoken name fills the box and opens the fortune it
meant, interim words are shown without closing the microphone, a refused
permission is explained calmly, silence says so, and tapping stop actually
cancels. `dart format` verified at the package language version on all seven
touched files.

Not in 3c: the AI fallback for sentences no rule covers (3d).

## Phase 3d delivery report (the AI stage, and its leash)

Scope covered: §2, last stage. Some sentences no honest rule can place. This
adds a model for exactly those — and nothing else.

Server: `POST /search/interpret`, authenticated, 20/min, query capped at 120
characters. `search-interpretation.ts` is the only door between the model and
navigation: an id the catalog knows, one of four named screens, or nothing.
An invented id, a path, a URL, prose or the wrong shape all become nothing.
`search-prompt.ts` writes the closed list out for the model and neutralizes
the typed question as DATA — quotes, newlines and fences stripped, then capped
— the rule the display name already follows. The route is dead unless the
`search.ai-bar` flag is on and a model is configured; one bounded round-trip,
no retries, temperature 0, 60 tokens. The question is never logged: only its
length, the outcome and the duration. `extractJsonObject` moved to
`common/json` and is shared with the reading provider rather than copied.

Client: `SearchRepository` re-validates the reply through the app's own
tables — an id goes through `FortuneDestinations`, a screen through
`kSearchScreens` — so a route cannot be invented at either end, and the screen
labels the rules use are now the same table the reply resolves against. The
bar asks only when someone taps «از دستیار بپرس», never on a keystroke, never
on silence, and never for a question it already answered this session. A
silent answer leaves the calm "nothing found" ending exactly as it was.

Tests: server — the guardrail across every catalog id and every refusal case,
the prompt carrying the whole list and surviving an injection attempt, and the
service across flag-off, no-model, good answer, fenced answer, invented id,
prose, upstream error, network failure, empty input and the no-logging
promise. Client — the re-validation table (fortune, screen, invented id,
unknown screen, path, a guide, an id the registry does not have) plus the bar:
never asks on its own, offers nothing when there is no assistant, asks once
and opens what came back, keeps the calm ending on silence, never pays twice
for the same question, and stays quiet entirely when the index already
answered. Formatting verified with two dart_style builds and prettier 3.3.3.

Phase 3 (§2 + §3) is now complete.

## Phase 4 delivery report (personalization §4 + next fortune §5)

Architecture decision (same anti-duplication rule as Phase 1): affinity is
**derived from the reader's own readings**, not stored in a second table. A
`UserPreferenceProfile` would have to be kept in sync with the history that
already exists, and would need its own deletion story; deriving means a deleted
reading also deletes its influence, with nothing to remember. What §4 requires —
category and time-of-day affinity, ≤3 explained cards, opt-out — is delivered in
full. The only stored preference is the opt-out itself, which must survive a
device change: `User.personalizationOptOut` (migration
`20260726120000_personalization_opt_out`), read and written through the existing
profile endpoints.

Rules (`next_fortunes.dart`, pure and offline): never the fortune just read,
never something that cannot be opened, never a repeat inside one strip, and at
most three. One card per kind of reason, so the strip says three different
things: the family of what was just read, then what this reader actually opens
at this part of the day (صبح/ظهر/عصر/شب — two readings before it counts as a
habit, once is not a pattern), then something never tried. Each card carries
its reason in one line; a suggestion without a reason is just an advertisement.

Client: `NextFortunesStrip` under the reading, opening through the shared
destination map like every other card. It reads history through the existing
repository and shows nothing at all while loading, on failure, or when
personalization is off — and when it is off, history is not even consulted. The
switch lives on the profile screen in plain words.

Tests: the rule table (no repeats, no dead ends, the family first, a habit named
as one, one reading not yet a habit, untried offered as untried, determinism,
the four day parts, and every fortune having a next step), the strip (offers
with reasons, opens through the map, silent and history-free when opted out),
and the server (opt-out stored and reported, untouched when an edit does not
mention it). Formatting verified with two dart_style builds and prettier 3.3.3.

Phase 4 (§4 + §5) is complete. Remaining: Phase 5 (§6, §7), Phase 6 (§8), and
Phase 2 (§1) once licensed audio assets exist.

## Phase 5a delivery report (history summary and compare, §6)

The server does the arithmetic and the model, if it is switched on at all, is
only allowed to phrase it. `history-digest.ts` counts the chosen window and the
identical window before it — totals, per-fortune tallies, first-times, active
days, and a time-of-day habit that is named only when there is an outright one
(a tie says nothing). `history-narrative.ts` turns that into Persian sentences
with no model involved; that is the floor, not a fallback, so a disabled flag, a
missing key or a slow upstream costs tone and nothing else.

Privacy: the prompt contains counts. No reading text, no name, no birth month,
no ids — there is nothing in it that could leak into a sentence even if the
model tried. The answer is rejected unless it is short, Persian, and free of
links and markup. `AiSummaryCache` is keyed by a fingerprint of the readings it
describes, so adding or deleting a reading retires the old summary by itself,
and the row is cascaded away with its user. The switch that silences suggestions
(§4) also closes this wire. Flag: `history.summary`, off by default.

Client: «نگاهی به گذشته» rides in the first slot of the journal list, so it
scrolls with the readings instead of pinning a panel over them. Three windows,
the sentence, and the counts behind it as pills. When a model wrote the
sentence the card says so. A failed summary is silence — the journal is already
on screen.

Anti-duplication: `PromptMessage` was declared twice and about to become three,
so it now lives once in `common/ai`; the readings repository owns the
`ReadingMoment` projection the summary counts, rather than a second door onto
that table.

## Monetization paused (temporary, reversible)

Ads (§ rewarded-ad mediation) and VIP are **paused, not dropped** — every model,
endpoint, test and screen remains in place and in scope. Two reasons: the owner
needs to walk the whole app end to end without a paywall interrupting a ritual,
and AdsGram's review raised a question that should be settled before their SDK
loads at all.

Mechanism: one compile-time constant, `kMonetizationEnabled`
(`lib/core/config/monetization_switch.dart`), false by default. While it is
false the access flow proceeds immediately without asking the server, the VIP
entries on home and profile are absent, `/vip` redirects to the fortunes list,
and search never offers a subscription screen. Because it is a compile-time
constant the ad paths are tree-shaken out, so no provider SDK can be fetched.
The API needs nothing: `ENFORCE_ACCESS_LIMITS` is unset in production, which
already means every reading is free.

To restore: build with `--dart-define=ENABLE_MONETIZATION=true` and set
`ENFORCE_ACCESS_LIMITS=true` on the API. `test/features/access/
monetization_paused_test.dart` fails deliberately when the switch flips, so the
assumptions written there are revisited rather than forgotten.

## Phase 5b delivery report — server (smart notifications, §7)

The decision is pure and the plumbing is thin. `notification-plan.ts` answers
one question — what, if anything, is worth saying to this reader right now —
from the clock, their own preferences and when they last read a fortune. Same
inputs, same answer, every time; a feature that reaches somebody when they are
not looking has to be inspectable rather than clever.

Every rule is a reason **not** to send: muted (a mute that expires by itself),
inside their own quiet hours (which may cross midnight), the daily cap reached,
already sent today, switched off, or simply nothing worth saying. Priority is
explicit, so when the cap allows one message it is the most useful one: a real
absence first (day three, then once a week — an absence is not an invitation to
ask every morning), then today's fortune (only after 09:00 local and only if
they have not already read one today), then the week's look-back on Friday.

Privacy: the copy carries no name, no birth month and never a line from a
reading — a message on a lock screen is read by whoever holds the phone. The
delivery row stores the kind and the local date, never the text. Logs record
the kind only.

Idempotency: `(user, kind, dateKey)` is unique and the row is written *before*
the send, so a sweep that runs twice — or two sweeps racing — cannot send the
same thing twice. The cost is that a refused send is not retried today, which
is the right trade for a courtesy message.

Delivery rides the existing Telegram bot; no second channel to Telegram was
opened. There is no timer inside the API: `POST /notifications/sweep` is driven
by an external scheduler and carries a shared secret compared in constant time.
While `NOTIFICATIONS_SWEEP_SECRET` is empty the route refuses every caller, so
a fresh deployment cannot message anybody by accident. Flag:
`notifications.smart`, off by default.

Preferences live at `GET/PATCH /notifications/preferences`, scoped to the
caller. Hours, caps and mute length are validated at the edge *and* clamped in
the service — a preference that silences someone forever by accident is worse
than a rejected request.

## Phase 5b delivery report — client (notification settings, §7)

«یادآوری‌ها» sits on the profile screen, under personalization. Three switches
(today's fortune, a nudge after a few days away, the weekly look-back), the
quiet-hours sentence written out in Persian digits so it can be checked at a
glance, and one tap for «یک هفته چیزی نفرست» — which the same tap undoes.

Two rules hold the surface honest. While the settings are unknown or the server
is unreachable the card shows **nothing at all**, rather than a switch resting
in a position nobody chose. And a refused save leaves every switch exactly where
it was: a control that lies about what the server holds is worse than no control.
Each change sends only the field that changed.

Tests cover the quiet-hours sentence, one-field-per-change, a refused save
leaving the switch alone, mute and un-mute, and silence while the settings are
unknown; plus the payload falling back to the same modest defaults the server
uses, and a mute being read against the clock so a past one needs no cleanup.

Phase 5 (§6 + §7) is complete. Remaining: Phase 6 (§8 reflection journal) and
Phase 2 (§1 ambient audio) once licensed audio assets exist. The notification
sweep still needs an external scheduler and `NOTIFICATIONS_SWEEP_SECRET` before
a single message can be sent.

## Phase 6a delivery report — server (reflection journal, §8)

The `note` column is the most private row in this database, and the service is
built around one rule: it is never input to anything. Not summarised, not
classified, not counted, never placed in a prompt, and never logged — not even
its length. The only thing that leaves the table is a page of entries, going
back to the person who wrote them. `reflection.saved` records the feeling and
nothing else, and the feeling is one of five words the app itself offered.

Deliberate deviation, recorded: the scope reserves a `ReflectionSummary` model.
There is none, and there should not be — summarising a diary means reading it.
The equivalent value is delivered without that cost: the follow-up line is
chosen from the **feeling alone**, so §8's "AI micro-questions" ship with the
model receiving one word from a closed list of five and nothing else.

Crisis-safe behaviour, without surveillance: the app does not scan anybody's
text to guess at their state. Instead the two heavier feelings — «نگران» and
«گرفته» — are never probed and never handed to a model at all. They are met with
a written line that makes room and says plainly that talking to someone real is
allowed. No diagnosis, no alarm, and nothing inferred from private words.

Shape: `PUT /reflections` writes or rewrites (coming back to a reading edits
rather than stacking), `GET /reflections` pages newest-first with an opaque
cursor, `GET /reflections/reading/:id` fetches the one attached to a reading,
`GET /reflections/prompt?feeling=` returns the line, and `DELETE` is immediate
and total — it is their diary. Every route is scoped to the caller; no request
shape can reach another person's entries. Flag: `reflection.journal`, off by
default, and the written lines are the floor rather than a fallback.
