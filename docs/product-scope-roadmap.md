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
