# Accessibility Audit Report

**Date:** 2026-03-12  
**Platform:** iOS (SwiftUI)  
**Framework:** swift-accessibility-agent  
**Scope:** SpeechDictation app UI surfaces

---

## Executive Summary

The app has **strong accessibility** in EntryView, CameraExperienceView, CameraPermissionsView, and MicSensitivityView. Several core flows (ContentView, SettingsView, SecureRecordingsView, SecurePlaybackView) have **P0 gaps** that block or degrade assistive-technology usability. This audit follows G-001 through G-015 and the Inspector Audit Checklist.

---

## Findings by Guideline

### G-001: Labels and Meaningful Names

| Location | Finding | Severity | Guideline |
|----------|---------|----------|-----------|
| **ContentView** | Transcript `Text` has no `.accessibilityLabel`; empty transcript is not announced | P1 | G-001 |
| **ContentView** | Jump to Live button uses `Label` (text + icon) — OK; no explicit hint | P2 | G-001 |
| **ContentView** | Utility buttons (Reset, Secure Recordings, Share, Audit, Settings) use `Label` — OK | Pass | G-001 |
| **ContentView** | Start controls (Transcribe/Stop, Record/Stop) use `Label` — OK | Pass | G-001 |
| **SettingsView** | "Settings" header has no `.accessibilityAddTraits(.isHeader)` | P1 | G-001 |
| **SecureRecordingsView** | Plus button (toolbar) is icon-only — needs `.accessibilityLabel("Add new recording")` | P0 | G-001 |
| **SecureRecordingsView** | Info button (SecureRecordingsSettingsView) is icon-only — needs label | P1 | G-001 |
| **SecurePlaybackView** | Play/pause, rewind 15s, forward 15s are icon-only — need labels | P0 | G-001 |
| **SecurePlaybackView** | Segmented Picker has text tags — OK | Pass | G-001 |
| **TextSizeSettingView** | Slider has no `.accessibilityLabel` or `.accessibilityHint` | P1 | G-001 |
| **ThemeSettingView** | Theme buttons have text — OK; selected state is color-only (see G-011) | Partial | G-001 |
| **SecureRecordingsSettingsView** | Toggle with `.labelsHidden()` — needs `.accessibilityLabel` | P0 | G-001 |
| **DepthBasedDistanceView** | Toggle with `.labelsHidden()` — needs `.accessibilityLabel` | P1 | G-001 |
| **NativeStyleShareView** | Handle bar (Capsule) — should be `.accessibilityHidden(true)` | P2 | G-001 |
| **TranscriptAuditView** | Toggles have visible labels — OK | Pass | G-001 |

---

### G-003: Values for Stateful Controls

| Location | Finding | Severity | Guideline |
|----------|---------|----------|-----------|
| **ContentView** | Transcribe/Record buttons change title with state — OK | Pass | G-003 |
| **TextSizeSettingView** | Slider has no `.accessibilityValue` — current font size not announced | P0 | G-003 |
| **ThemeSettingView** | Selected theme not exposed via `.accessibilityValue` or `.accessibilityAddTraits(.isSelected)` | P0 | G-003 |
| **SecureRecordingsSettingsView** | Toggle state (On/Off) not explicitly announced | P1 | G-003 |
| **DepthBasedDistanceView** | Toggle state not explicitly announced | P1 | G-003 |
| **SecurePlaybackView** | Playback slider has no `.accessibilityValue` (current time / duration) | P0 | G-003 |
| **SecurePlaybackView** | Speed Picker value not announced | P1 | G-003 |
| **MicSensitivityView** | Slider has no `.accessibilityValue` | P1 | G-003 |
| **VUMeterView** | Has `.accessibilityValue` — OK | Pass | G-003 |

---

### G-004: Traits and Roles

| Location | Finding | Severity | Guideline |
|----------|---------|----------|-----------|
| **SettingsView** | Header should use `.accessibilityHeading(.h1)` | P1 | G-004 |
| **ThemeSettingView** | Selected theme button should have `.accessibilityAddTraits(.isSelected)` | P0 | G-004 |
| **SecureRecordingsView** | Authentication buttons use `Button` + `Label` — OK | Pass | G-004 |
| **TranscriptAuditView** | Header stats — consider `.accessibilityElement(children: .combine)` for grouping | P2 | G-004 |

---

### G-005: Grouping and Containment

| Location | Finding | Severity | Guideline |
|----------|---------|----------|-----------|
| **ContentView** | Transcript area + ScrollView — consider `.accessibilityElement(children: .contain)` with label "Live transcript" | P1 | G-005 |
| **ContentView** | Settings overlay — tap-to-dismiss background; verify focus containment (G-013) | P1 | G-005 |
| **SettingsView** | ScrollView content — no grouping labels for sections | P2 | G-005 |
| **SecureRecordingRow** | Status labels (Encrypted, On-Device, Consent) — color-only (see G-011) | P1 | G-005 |

---

### G-006: Focus and Reading Order

| Location | Finding | Severity | Guideline |
|----------|---------|----------|-----------|
| **ContentView** | Settings presented as overlay — verify focus moves into overlay and returns on dismiss | P1 | G-006 |
| **EntryView** | NavigationView + ScrollView — order appears logical | Pass | G-006 |
| **SecureRecordingsView** | Modal sheet — verify focus containment | P1 | G-006 |

---

### G-010: Dynamic Type and Layout Resilience

| Location | Finding | Severity | Guideline |
|----------|---------|----------|-----------|
| **EntryView** | Uses `adaptiveSpacing`, `adaptiveTopPadding`, `minimumScaleFactor` — strong | Pass | G-010 |
| **ContentView** | Uses `minimumScaleFactor` on buttons — OK | Pass | G-010 |
| **ThemeSettingView** | Fixed font size (16) — consider `.dynamicTypeSize` scaling | P2 | G-010 |
| **SettingsView** | Mixed fixed and scalable text — verify at xxxLarge and accessibility sizes | P2 | G-010 |

---

### G-011: Color, Contrast, Non-Color Cues

| Location | Finding | Severity | Guideline |
|----------|---------|----------|-----------|
| **ThemeSettingView** | Selected theme indicated by accent color only — add `.accessibilityAddTraits(.isSelected)` | P0 | G-011 |
| **SecureRecordingRow** | "Encrypted", "On-Device", "Consent" use green/blue — ensure labels provide context | P1 | G-011 |
| **SecureRecordingsSettingsView** | Authentication status (green/orange) — text provides context | Pass | G-011 |
| **EntryView** | Uses `differentiateWithoutColor` for gradients and badges | Pass | G-011 |

---

### G-012: Reduced Motion

| Location | Finding | Severity | Guideline |
|----------|---------|----------|-----------|
| **EntryView** | Uses `reduceMotion` for shadow radius/offset | Pass | G-012 |
| **ContentView** | Jump to Live uses `.transition(.scale.combined(with: .opacity))` — verify with Reduce Motion | P2 | G-012 |

---

### G-013: Modal/Sheet Focus Containment

| Location | Finding | Severity | Guideline |
|----------|---------|----------|-----------|
| **ContentView** | Settings overlay — `onTapGesture` dismiss; VoiceOver may focus background | P1 | G-013 |
| **ContentView** | Sheets (Share, Secure Recordings, Transcript Audit) — native sheet behavior | Pass | G-013 |
| **SecureRecordingsView** | Presented as sheet — verify focus returns to trigger on close | P1 | G-013 |

---

## Summary by Severity

| Severity | Count | Description |
|----------|-------|-------------|
| P0 | 7 | Blocks task completion or high-risk mis-action |
| P1 | 18 | Materially degrades usability; workaround may exist |
| P2 | 8 | Minor clarity or consistency |

---

## Recommended Fixes (Priority Order)

### P0 (Blocking) — IMPLEMENTED 2026-03-12

1. **SecureRecordingsView** — Added `.accessibilityLabel("Add new recording")` to plus toolbar button.
2. **SecurePlaybackView** — Added labels to play/pause, rewind, forward; scrubber slider has `.accessibilityValue` and `.accessibilityHint`.
3. **TextSizeSettingView** — Added `.accessibilityLabel`, `.accessibilityValue`, `.accessibilityHint` to slider.
4. **ThemeSettingView** — Added `.accessibilityAddTraits(.isSelected)` when selected and `.accessibilityValue(theme.displayName)` to theme buttons.
5. **SecureRecordingsSettingsView** — Added `.accessibilityLabel`, `.accessibilityValue`, `.accessibilityHint` to auth toggle.

### P1 (High)

7. **SettingsView** — Add `.accessibilityAddTraits(.isHeader)` and `.accessibilityHeading(.h1)` to "Settings" header.
8. **ContentView** — Add `.accessibilityLabel("Live transcript")` and `.accessibilityValue(viewModel.transcribedText)` to transcript area; handle empty state.
9. **MicSensitivityView** — Add `.accessibilityValue` to slider.
10. **DepthBasedDistanceView** — Add `.accessibilityLabel` to toggle.
11. **SecureRecordingsView** — Add `.accessibilityLabel("Authentication information")` to info button.
12. **ContentView** — Verify Settings overlay focus containment; consider `.accessibilityHidden` on background when overlay is shown.

---

## Verification Plan

### Accessibility Inspector

1. Launch app in simulator.
2. Open Xcode Accessibility Inspector, target the app.
3. For each screen in the findings table, verify:
   - Every interactive element has non-empty label.
   - Stateful controls expose current value.
   - Decorative elements are hidden.

### VoiceOver Walkthrough

1. Enable VoiceOver.
2. Run Script 1 (VoiceOver Smoke Test) from `docs/testing/manual-test-scripts.md`.
3. Swipe through ContentView, SettingsView, SecureRecordingsView, SecurePlaybackView.
4. Activate primary actions; confirm state announcements.

### Dynamic Type Sweep

1. Set text size to largest accessibility category.
2. Traverse ContentView, EntryView, SettingsView.
3. Verify no clipped critical text.

### Contrast / Differentiate-Without-Color

1. Enable Differentiate Without Color.
2. Visit ThemeSettingView, SecureRecordingRow.
3. Confirm selection/status has non-color cue.

---

## References

- [G-001] Labels and meaningful names — `docs/swiftui/guidelines/g-001-labels-meaningful-names.md`
- [G-003] Values for stateful controls — `docs/swiftui/guidelines/g-003-values-stateful-controls.md`
- [G-004] Traits and roles — `docs/swiftui/guidelines/g-004-traits-roles.md`
- [G-011] Color/contrast/non-color cues — `docs/swiftui/guidelines/g-011-color-contrast-non-color-cues.md`
- Inspector checklist — `docs/testing/inspector-audit-checklist.md`
- Manual test scripts — `docs/testing/manual-test-scripts.md`
- Semantics taxonomy — `docs/core/taxonomy/semantics-checklist.md`
