# BakhtNegar — Navigation & Back-Behaviour Audit

Scope: every route in `apps/mobile`, the router, app bars, and the Telegram
integration. Goal: no dead ends, one consistent «back» across the in-app app
bar, the Telegram BackButton and browser/system back.

## How back works now (one shared brain)

- **`AppBack`** (`lib/app/navigation/app_back.dart`) is the single decision
  point: `goBack` pops when the router can pop, otherwise lands on the safe
  home base `«فال‌ها» /fortunes`. `showBack(location, canPop)` decides whether a
  back affordance belongs on a route at all.
- **`FortuneAppBar`** (`lib/design_system/components/fortune_app_bar.dart`)
  replaces the raw `AppBar` on every content page. It shows Flutter's
  `BackButton` (platform icon, **RTL-mirrored**, localized tooltip/semantics,
  48px target) on the leading — i.e. the **right** edge in Persian — only when
  `AppBack.showBack` is true, and routes its tap through `AppBack.goBack`.
- **Telegram BackButton** is driven by `TelegramBackObserver`
  (`lib/app/navigation/telegram_back_observer.dart`), a `NavigatorObserver`
  bound to the router. On every route change it shows/hides the native button
  and wires it — through a **single** handler — to the same `AppBack` logic.
  Off Telegram the bridge is a no-op. One JS listener is registered at most
  once (`telegram_web_bridge.dart`), and `dispose` clears it.
- **Browser / system / iOS-swipe back**: go_router already syncs pushed routes
  with browser history, so browser back pops correctly. A global `PopScope`
  was deliberately **not** added — placed above go_router's Navigator it would
  swallow in-app pops and break back. On the real targets (Flutter Web /
  Telegram) system back == browser back, and cold routes are covered by the
  fallback above.

## Route table

| Route (name) | Reached from | Back goes to | App-bar back? | Telegram back? | Browser/system back | Fallback (no history) |
|---|---|---|---|---|---|---|
| `/splash` (splash) | app launch | — | No | No | n/a | auto-redirect → `/fortunes` when ready |
| `/home` (home) | bottom nav | — (root) | No (no app bar) | Hidden | prev URL | n/a (home base) |
| `/fortunes` (allFortunes = Explore) | bottom nav / fallback | — (root) | No (no app bar) | Hidden | prev URL | is the fallback |
| `/ritual/:fortuneId` (ritual = fortune detail+entry) | Explore/Home push · cold deep link | pop → origin · cold → `/fortunes` | **Yes** | **Yes** | browser back | `/fortunes` |
| `/reading/:readingId` (reading = result) | ritual push · history push · cold deep link | pop → origin · cold → `/fortunes` | **Yes** (incl. loading/error) | **Yes** | browser back | `/fortunes` |
| `/vip` (vip) | ritual/home/profile push · cold | pop → origin · cold → `/fortunes` | **Yes** | **Yes** | browser back | `/fortunes` |
| `/history` (history) | bottom nav (root) · profile push | pop when pushed · none as tab root | Yes when pushed | Yes when pushed | browser back | `/fortunes` |
| `/profile` (profile) | bottom nav (root) | none as tab root | Yes when pushed | Yes when pushed | browser back | `/fortunes` |
| `/coffee` (coffee guide) | Home/Explore push · cold | pop · cold → `/fortunes` | **Yes** | **Yes** | browser back | `/fortunes` |
| `/elements` (elements guide) | Home/Explore push · cold | pop · cold → `/fortunes` | **Yes** | **Yes** | browser back | `/fortunes` |
| `/wallet` (wallet) | legacy link | — | n/a | n/a | n/a | redirects → `/vip` (never rendered) |
| `/explore` (legacy) | legacy link | — | n/a | n/a | n/a | redirects → `/fortunes` (never rendered) |
| error / NotFound | any invalid route | in-body action → `/fortunes` | No (bare recovery page) | Follows stack | browser back | `/fortunes` (explicit button) |

### Modals, sheets, dialogs

`access_sheet` (rewarded-ad / VIP bottom sheet) and the ad-limit / ads-exhausted
dialogs are pushed on the root navigator, so `canPop` is true while they are
open: the Telegram BackButton and browser/system back close the **modal first**
(via `AppBack.goBack` → `pop`), exactly like the barrier tap. No dead ends, no
double-pop.

### Loading / Empty / Error states

- Reading **loading** and **error** states now use `FortuneAppBar` (back
  present) instead of a bare `AppBar()`.
- Ritual **not-found** uses `FortuneAppBar`.
- Home / History / Explore **empty** states carry an in-body action to
  `/fortunes`.

## Pages intentionally without a back control

| Page | Why |
|---|---|
| `/splash` | Transient startup; it redirects to `/fortunes` the moment startup is ready — there is nothing to go back to. |
| `/home`, `/fortunes` | Bottom-navigation roots / the app's home base. They are reached by replacing the stack; a back here would only loop. Switching happens via the bottom nav. |
| `/history`, `/profile` **when they are the current tab** | Same as above — as a bottom-nav destination they are a stack root. When instead reached by a push (e.g. Profile → History), `canPop` is true and back appears automatically. |

## No dead ends — confirmation

Every route that is not a stack root offers a working back (pop, or a fallback
to `/fortunes`). Cold deep links to `/ritual/:id`, `/reading/:id`, `/vip`,
`/coffee`, `/elements` all present a back that lands on Explore. The NotFound
page has an explicit recovery action. The Telegram BackButton and the app-bar
button share one handler, so they can never disagree.

## Tests

`test/app/navigation_back_test.dart`:

- `AppBack.showBack` classifier (poppable, stack roots, cold deep routes).
- Cold deep link → back → Explore.
- Pushed route → back → origin.
- Stack root shows no back control.
- Telegram BackButton tracks the stack (hidden at root, one live handler on a
  deep route, tapping it pops, cleared on dispose — no duplicate handlers).
