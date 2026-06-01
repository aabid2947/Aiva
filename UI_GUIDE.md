# AIVA UI Guide

The design system every screen must follow. It lives in `lib/core/theme/` +
`lib/core/widgets/`. **Golden rule: screens never hardcode colors, text styles, spacing,
or radii — read them from the theme/tokens below.** New screens that follow this stay
visually consistent and get light/dark for free.

## The one rule
- ❌ `Colors.blue`, `Color(0xFF...)`, `TextStyle(fontSize: 18)`, `EdgeInsets.all(16)`
- ✅ `AppColors.brandBlue` / `Theme.of(context).colorScheme.primary` / `context.palette.success`,
  `Theme.of(context).textTheme.titleMedium`, `AppSpacing.lg`, `AppRadii.rLg`
- Allowed exceptions: `Colors.transparent` (non-color), and the **call screen**'s `AppColors.call*`
  on-dark tokens (it's a permanently-dark surface). Both are centralized/justified.

## Colors — `core/theme/app_colors.dart`
- **Brand:** `brandBlue` #1E9BE6 (primary, from the robot logo), `bronze` #C08A4A (secondary,
  from the wordmark), `gold` #E8B563 (tertiary).
- **Semantic:** `success` #2BB673 · `warning` #E5A23B · `danger` #E5484D · `info` #3AA0FF · `neutral`.
- **Surfaces:** dark = #0B0E14 bg / #121723 surface / #1A2130 raised; light = #F7F9FC / #FFFFFF.
- `AppColors.light` / `AppColors.dark` are the `ColorScheme`s (built from these).
- **`AppPalette`** (ThemeExtension) holds semantics not in ColorScheme — `userBubble`, `aivaBubble`,
  `hairline`, `muted`, `success/warning/danger/info`. Read it with **`context.palette`**.

## Typography — `core/theme/app_typography.dart`
- Headings: **Plus Jakarta Sans**; body: **Inter** (via `google_fonts`).
- Scale (use these, don't invent sizes): `displaySmall` 34 · `headlineMedium` 28 · `headlineSmall` 22 ·
  `titleLarge` 20 · `titleMedium` 16 · `bodyLarge` 16 · `bodyMedium` 14 · `bodySmall` 12.5 ·
  `labelLarge/Medium/Small`. Color comes from the scheme; only override color via `copyWith`.

## Spacing / radii / motion — `core/theme/app_spacing.dart`
- **AppSpacing:** xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32 · xxxl 48.
- **AppRadii:** sm 8 · md 12 · lg 16 · xl 20 · pill 999, plus ready `rSm/rMd/rLg/rXl/rPill` BorderRadius.
- **AppMotion:** durations `fast` 150 · `base` 220 · `slow` 320; curves `standard` (easeOutCubic),
  `emphasized`. Every animation pulls timing from here.

## Theme assembly — `core/theme/app_theme.dart`
`AppTheme.light` / `AppTheme.dark` build `ThemeData` + all component themes (appbar transparent +
centered, filled inputs 16-radius, pill/rounded buttons, hairline cards, floating snackbars, rounded
drawer/bottom-sheet). `main.dart` wires `theme`/`darkTheme` + `themeMode` from `ThemeController`
(persisted system/light/dark; toggle in the drawer footer). App is edge-to-edge.

## Motion & navigation — `core/motion/page_transitions.dart`
- `sharedAxisRoute()` for forward nav into a sibling screen; `fadeThroughRoute()` for swapping
  unrelated destinations. Both are **reduce-motion aware** (fall back to fade). Don't use raw
  `MaterialPageRoute`.

## Reusable widgets — `core/widgets/`
- **AppCard** — surface + hairline border + rounded, optional tap.
- **StatusChip** — semantic-colored pill (`label`, `color`, `icon`).
- **SkeletonBox** — shimmer loading block (reduce-motion → static). Use for loading states, not spinners.
- **EmptyState** — icon + title + message + optional action.
- **SectionHeader** — small uppercase group label.
- **StaggerIn** — interval fade+slide entrance for lists (pass a shared controller + `order`).
- **GradientBackground** — auth backdrop. **BrandedSplash** — pulsing-logo loader.
- **AppToast** — semantic transient feedback. `AppToast.success/error/warning/info(context, msg)` from a
  widget, or `…Global(msg)` from non-widget code (push handler, deep links). Themed floating SnackBar:
  semantic icon + tinted surface + accent border, light/dark aware, auto-dismiss (errors linger longer).
  **Rule: never build a raw `SnackBar` — route all success/failure/warning messages through `AppToast`.**
  (Persistent, action-tied errors — e.g. the chat send-failure banner — stay inline, not toasts.)

## Accessibility & responsiveness
- Icon-only buttons carry a `tooltip` (also the semantic label). Touch targets ≥ 44–48dp.
- Forms are keyboard-safe (scroll + `viewInsets` padding); content is width-capped (`maxWidth`) on
  large screens. Reduce-motion is honored across transitions, skeletons, splash, and list staggers.

## Checklist for a new screen
1. Wrap content with theme tokens only (run `grep -rn "Colors\.\|Color(0x\|fontSize:" lib/features` → empty).
2. Use `AppCard` / `StatusChip` / `EmptyState` / `SkeletonBox` instead of bespoke equivalents.
   Surface transient outcomes with `AppToast` (no raw `SnackBar`).
3. Navigate with `sharedAxisRoute` / `fadeThroughRoute`.
4. Provide loading (skeleton), empty, and error states.
5. Verify it reads well in **both** light and dark.
