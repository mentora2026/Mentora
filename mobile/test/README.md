# Mobile App Tests (Step 6)

Widget and unit tests for the Flutter patient app, covering the UI components
and data models most central to the Adaptive Interview chat experience.

## Running

```bash
cd mobile
flutter test
```

## Test Files

| File | Type | Covers |
|---|---|---|
| `test/presentation/shared/risk_badge_test.dart` | Widget | `RiskLevelBadge` - Arabic label rendering for all 5 risk levels, large/small variants, unknown-level fallback. |
| `test/presentation/chat/widgets/message_bubble_test.dart` | Widget | `MessageBubble` - bot vs. patient alignment/coloring (RTL-correct), timestamp formatting. |
| `test/presentation/chat/widgets/chat_input_bar_test.dart` | Widget | `ChatInputBar` - text submission + trimming, empty-input guard, 1-5 scale picker toggle and selection, disabled/sending states. |
| `test/data/models/interview_test.dart` | Unit | `ChatMessage`, `InterviewSession`, `InterviewTurnResult` `fromJson` parsing against representative backend payloads. |
| `test/core/app_strings_test.dart` | Unit | `AppStrings` label-map completeness (risk levels, mood values, recommendation categories, activity/social-support levels); also covers `InterviewProvider.reset()`. |

## Notes on Scope

- These tests focus on pure widgets and data models that don't require
  network access or platform channels.
- `InterviewProvider` / `AuthProvider` / etc. construct their repositories
  directly (no dependency injection), so their network-calling methods
  (`initialize`, `startNewSession`, `login`, ...) are exercised by the
  **backend integration tests** (`backend/tests/test_ai_engine.py`,
  `test_e2e_smoke.py`) via the real API contract, plus manual QA against a
  running backend (see `mobile/README.md`).
- A full `AuthGate` / `main.dart` smoke test was intentionally omitted: it
  would require mocking `flutter_secure_storage`'s platform channel, which
  adds test-harness complexity disproportionate to the value for this
  project's scope. The auth/onboarding routing logic is straightforward
  conditional rendering, documented in `mobile/README.md` Section 4.
