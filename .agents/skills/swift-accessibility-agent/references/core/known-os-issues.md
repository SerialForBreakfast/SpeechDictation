# Known OS Accessibility Bugs and Regressions Catalog

Last updated: 2026-03-07
Scope: iOS, iPadOS, tvOS, macOS, visionOS (SwiftUI/UIKit/AppKit + accessibility tooling)

## Purpose

Track real-world framework and OS accessibility regressions with actionable engineering guidance.

## Version Metadata Contract (Per Entry)

- `introduced_in`: earliest reported affected version (or `unknown`)
- `affected_range`: currently known impacted versions
- `fixed_in`: first version with confirmed fix evidence (or `unknown`)
- `status`: `open`, `partially_fixed`, `fixed`, `configuration_dependent`, or `needs_revalidation`
- `evidence_confidence`: `high`, `medium`, or `low`

## Evidence Tiering for This Catalog

- Tier-1: Apple docs, WWDC, release notes
- Tier-2: Apple Developer Forums reproducible threads
- Tier-3: community watchdog reports (AppleVis, similar), used for impact confirmation and trend detection

## Triage Workflow (Use on Every Suspected Regression)

1. Classify symptom: focus/order, missing tree exposure, semantics mismatch, announcement anomaly, performance/hang, tooling mismatch.
2. Reproduce with: Accessibility Inspector + VoiceOver walkthrough + platform-specific manual script.
3. Record environment: OS build, device type, framework layer (SwiftUI/UIKit/AppKit), and interop boundary.
4. Apply known mitigation candidate from this catalog.
5. Re-test and document outcome.
6. Record unresolved cases in issue tracker with reproduction artifacts and source links.

## Catalog Entries

### AX-BUG-001: SwiftUI nested lazy containers can hang under Inspector/VoiceOver

- Platform/OS range: iOS/iPadOS
- Framework: SwiftUI
- Symptom class: performance/hang
- Version status:
  - introduced_in: iOS 26 (forum report timeframe)
  - affected_range: iOS 26.0+ (reported), earlier versions unknown
  - fixed_in: unknown
  - status: open
  - evidence_confidence: high
- Symptom: app may freeze when Accessibility Inspector or VoiceOver is enabled and nested lazy containers are present.
- Detection signals:
  - normal interaction works with accessibility off
  - hangs appear only during accessibility tree traversal/inspection
- Mitigation/workaround:
  - replace inner `LazyVStack` with `VStack` on affected views
  - simplify deeply nested lazy stacks on accessibility-critical screens
  - profile accessibility-enabled runs before release
- Source context:
  - Apple forum thread includes Apple staff engagement and Feedback ID (`FB21851974`)
- Sources:
  - [APPLE-FORUMS-THREAD-814208]
  - [APPLE-AX-INSPECTOR]

### AX-BUG-002: VoiceOver reads OCR-detected text inside images in addition to provided label

- Platform/OS range: iOS/iPadOS
- Framework: SwiftUI/UIKit
- Symptom class: unexpected extra announcements
- Version status:
  - introduced_in: unknown (user reports span multiple major versions)
  - affected_range: version-dependent and configuration-dependent
  - fixed_in: n/a when caused by VoiceOver Recognition setting
  - status: configuration_dependent
  - evidence_confidence: high
- Symptom: VoiceOver may read text discovered inside image content after announcing explicit accessibility labels.
- Detection signals:
  - duplicate/verbose speech output for image elements
  - occurs on images containing embedded text even when label is set
- Mitigation/workaround:
  - verify whether VoiceOver Recognition (Text Recognition/Image Descriptions) is enabled
  - for critical UI text, prefer real text views over text baked into images
  - regression-test image-heavy surfaces with VoiceOver settings matrix
- Source context:
  - forum accepted answer indicates behavior tied to VoiceOver Recognition settings, not necessarily framework semantic bug
- Sources:
  - [APPLE-FORUMS-THREAD-804448]
  - [APPLE-VOICEOVER-RECOGNITION-SUPPORT]
  - [APPLE-AX-TESTING]

### AX-BUG-003: SwiftUI Link trait behavior may not match expected role semantics

- Platform/OS range: iOS/iPadOS
- Framework: SwiftUI
- Symptom class: wrong semantics/traits
- Version status:
  - introduced_in: unknown
  - affected_range: at least iOS 17-era based on report date
  - fixed_in: unknown
  - status: needs_revalidation
  - evidence_confidence: medium
- Symptom: `Link` may announce traits in ways that confuse role expectations.
- Detection signals:
  - VoiceOver output diverges from intended control role
  - mixed/duplicated role language in announcements
- Mitigation/workaround:
  - verify role expectations on each target OS version
  - use alternate control + explicit semantics when behavior is ambiguous for core flows
  - add focused semantic checks in review/testing scripts
- Sources:
  - [APPLE-FORUMS-THREAD-750508]
  - [APPLE-VIEW-ACCESSIBILITY]

### AX-BUG-004: List reorder announcements regressed in iOS 15->16 era

- Platform/OS range: iOS/iPadOS
- Framework: SwiftUI
- Symptom class: missing or degraded state announcements
- Version status:
  - introduced_in: iOS 16.0 (reported regression from iOS 15.7 behavior)
  - affected_range: iOS 16.0 (reported), current status unknown
  - fixed_in: unknown
  - status: needs_revalidation
  - evidence_confidence: medium
- Symptom: VoiceOver may fail to announce moved cell context during list reorder operations.
- Detection signals:
  - reorder operation succeeds visually but lacks expected spoken context
- Mitigation/workaround:
  - provide supplemental status updates where feasible
  - test reorder flows explicitly in VoiceOver scripts before release
- Sources:
  - [APPLE-FORUMS-THREAD-725486]
  - [APPLE-AX-TESTING]

### AX-BUG-005: VoiceOver focus can become trapped in UIKit container compositions

- Platform/OS range: iOS/tvOS
- Framework: UIKit / hosted view-controller containers
- Symptom class: focus trap/order regression
- Version status:
  - introduced_in: unknown (legacy report, still relevant pattern)
  - affected_range: version-unspecified container-composition risk
  - fixed_in: unknown
  - status: needs_revalidation
  - evidence_confidence: medium
- Symptom: focus enters a container and fails to leave using expected swipe navigation.
- Detection signals:
  - no forward/backward escape from container
  - modal or child VC boundaries increase reproduction frequency
- Mitigation/workaround:
  - define explicit focus lifecycle ownership at interop boundaries
  - validate container accessibility behavior in host layer
  - add modal open/close focus restoration checks
- Sources:
  - [APPLE-FORUMS-THREAD-100449]
  - [APPLE-UIKIT-ACCESSIBILITY]

### AX-BUG-006: Accessibility tree exposure mismatches can break both users and XCUITest

- Platform/OS range: all
- Framework: SwiftUI/UIKit/AppKit + testing layer
- Symptom class: missing element exposure / automation mismatch
- Version status:
  - introduced_in: n/a (class of recurring regressions)
  - affected_range: all supported OS lines
  - fixed_in: n/a
  - status: open
  - evidence_confidence: high
- Symptom: element is visible but missing from accessibility tree and query APIs.
- Detection signals:
  - control visible in UI but absent in Inspector hierarchy
  - XCUITest fails to locate expected element despite visual presence
- Mitigation/workaround:
  - treat missing accessibility-tree exposure as release-blocking
  - add stable identifiers and inspect semantic tree after major OS updates
  - run focused accessibility smoke tests in CI
- Sources:
  - [APPLE-AX-INSPECTOR]
  - [APPLE-AX-TESTING]
  - [APPLE-FORUMS-SWIFTUI-TAG]

### AX-BUG-007: Major-release regressions (VoiceOver/Braille) require cross-version verification

- Platform/OS range: iOS/iPadOS and macOS major releases
- Framework: system accessibility services
- Symptom class: OS-level feature regressions
- Version status:
  - introduced_in: release-cycle dependent
  - affected_range: release-specific; must be validated per major/minor line
  - fixed_in: release-note dependent
  - status: open
  - evidence_confidence: medium
- Symptom: feature behavior changes outside app code can degrade user workflows after OS updates.
- Detection signals:
  - previously passing flows fail only on new OS major/minor builds
  - user-reported regressions cluster around release cycles
- Mitigation/workaround:
  - run release-gate verification matrix by OS version
  - track known regressions and temporary UX workarounds per OS range
  - keep documentation links to release-note and forum signals
- Sources:
  - [APPLEVIS-IOS18-VOICEOVER-BRAILLE]
  - [APPLE-IOS18-RELEASE-NOTES]
  - [APPLE-MACOS15-RELEASE-NOTES]

### AX-BUG-008: Web content accessibility regressions can impact in-app web experiences

- Platform/OS range: iOS/macOS Safari/WebKit surfaces
- Framework: web content layer (when app depends on it)
- Symptom class: announcement/navigation behavior changes from browser engine updates
- Version status:
  - introduced_in: release-cycle dependent
  - affected_range: browser/OS-version dependent
  - fixed_in: see Safari release-note deltas
  - status: open
  - evidence_confidence: medium
- Symptom: VoiceOver behavior in web content shifts across browser/OS releases.
- Detection signals:
  - regressions limited to web-based screens/content
  - release notes mention VoiceOver fixes/changes
- Mitigation/workaround:
  - monitor Safari release notes for VoiceOver changes
  - include web-content a11y checks in regression passes for hybrid apps
- Sources:
  - [APPLE-SAFARI18-RELEASE-NOTES]

## VisionOS Tracking Note

No visionOS-specific app-level regression entries are confirmed in this catalog yet.
Add entries as reproducible cases are confirmed with source links.

## Entry Template (For New Issues)

- ID:
- Platform/OS range:
- Affected framework(s):
- Symptom class:
- Version status:
  - introduced_in:
  - affected_range:
  - fixed_in:
  - status:
  - evidence_confidence:
- Symptom:
- Detection signals:
- Repro steps:
- Mitigation/workaround:
- Source link(s):
- Last verified:
