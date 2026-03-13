# Sources of Truth Registry

Last updated: 2026-03-07
Owner: SwiftUI Accessibility Agent project

## Registry Format

Each source entry must include:

- `source_id`: Stable short ID (for citations in guideline docs).
- `title`: Human-readable title.
- `url`: Canonical URL.
- `authority_tier`: Tier-1, Tier-2, or Tier-3.
- `last_reviewed`: Date reviewed for freshness.
- `scope`: What this source is used to validate.
- `notes`: Caveats, version context, or follow-ups.

## Authority Tiers

- Tier-1: Apple platform truth. Use as the baseline source for rules.
- Tier-2: High-quality community sources. Use for implementation practice and examples.
- Tier-3: Reference-only sources. Use with caution and always cross-check.

## Tier-1 Sources (Seed, Validated)

| source_id | title | url | authority_tier | last_reviewed | scope | notes |
|---|---|---|---|---|---|---|
| APPLE-SWIFTUI-ACCESSIBILITY | SwiftUI: Accessibility | https://developer.apple.com/documentation/swiftui/accessibility | Tier-1 | 2026-03-07 | SwiftUI accessibility APIs and modifiers | Primary SwiftUI accessibility API reference hub. |
| APPLE-VIEW-ACCESSIBILITY | Accessibility Modifiers (View Accessibility) | https://developer.apple.com/documentation/swiftui/view-accessibility | Tier-1 | 2026-03-07 | Modifier-level behavior for SwiftUI view semantics | Use for labels, values, hints, traits, actions, grouping, and sort priority guidance. |
| APPLE-ACCESSIBILITY-ELEMENT-CHILDREN | accessibilityElement(children:) | https://developer.apple.com/documentation/swiftui/view/accessibilityelement%28children%3A%29 | Tier-1 | 2026-03-07 | SwiftUI grouping behavior (`combine`/`contain`/`ignore`) | Primary source for compound element grouping strategy. |
| APPLE-ACCESSIBILITY-CHILDREN | accessibilityChildren(children:) | https://developer.apple.com/documentation/swiftui/view/accessibilitychildren%28children%3A%29 | Tier-1 | 2026-03-07 | Synthetic accessibility child elements for complex visuals | Use for chart/canvas and custom visual semantic decomposition. |
| APPLE-ACCESSIBILITY-REPRESENTATION | accessibilityRepresentation(representation:) | https://developer.apple.com/documentation/swiftui/view/accessibilityrepresentation%28representation%3A%29 | Tier-1 | 2026-03-07 | Alternate semantic representations for non-standard UI | Use when visual UI needs a dedicated accessible representation. |
| APPLE-CREATING-ACCESSIBLE-VIEWS | Enhancing the Accessibility of Your SwiftUI App | https://developer.apple.com/documentation/accessibility/enhancing-the-accessibility-of-your-swiftui-app | Tier-1 | 2026-03-07 | End-to-end SwiftUI accessibility implementation guidance | Canonical Apple implementation walkthrough. |
| APPLE-HIG-ACCESSIBILITY | Apple Human Interface Guidelines: Accessibility | https://developer.apple.com/design/human-interface-guidelines/accessibility | Tier-1 | 2026-03-07 | Product-level accessibility behavior expectations | Use for rationale and UX expectations. |
| APPLE-AX-HUB | Accessibility Documentation Hub | https://developer.apple.com/documentation/accessibility | Tier-1 | 2026-03-07 | Assistive technologies, testing resources, and broad guidance | Canonical docs hub URL (developer.apple.com/accessibility redirects here). |
| APPLE-AX-INSPECTOR | Accessibility Inspector | https://developer.apple.com/documentation/accessibility/accessibility-inspector | Tier-1 | 2026-03-07 | Tooling workflows and audit checks | Basis for enforceable verification steps. |
| APPLE-AX-TESTING | Performing Accessibility Testing for Your App | https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app | Tier-1 | 2026-03-07 | Manual and tool-assisted accessibility testing guidance | Use to define verification workflows. |
| APPLE-WWDC-AX-INDEX | WWDC Accessibility and Inclusion Sessions | https://developer.apple.com/videos/accessibility-inclusion/ | Tier-1 | 2026-03-07 | Session-driven updates and platform changes | Use as discovery index; cite specific sessions for rules. |
| APPLE-WWDC24-SWIFTUI | Catch Up on Accessibility in SwiftUI (WWDC24) | https://developer.apple.com/videos/play/wwdc2024/10073/ | Tier-1 | 2026-03-07 | SwiftUI semantics, modifiers, and interaction updates | High-value session for modern SwiftUI guidance. |
| APPLE-WWDC21-SWIFTUI-BEYOND | SwiftUI Accessibility: Beyond the Basics (WWDC21) | https://developer.apple.com/videos/play/wwdc2021/10119/ | Tier-1 | 2026-03-07 | Advanced SwiftUI grouping, representation, and interaction patterns | Use for deeper SwiftUI semantics and complex control coverage. |
| APPLE-WWDC23-SWIFTUI-UIKIT | Build Accessible Apps with SwiftUI and UIKit (WWDC23) | https://developer.apple.com/videos/play/wwdc2023/10036/ | Tier-1 | 2026-03-07 | Interop guidance for mixed SwiftUI/UIKit apps | Anchor interop-focused guidelines. |
| APPLE-WWDC23-AUDITS | Perform Accessibility Audits for Your App (WWDC23) | https://developer.apple.com/videos/play/wwdc2023/10035/ | Tier-1 | 2026-03-07 | Practical auditing approach and tooling | Anchor Inspector/test-plan guidance. |
| APPLE-UIKIT-ACCESSIBILITY | Accessibility for UIKit | https://developer.apple.com/documentation/uikit/accessibility-for-uikit | Tier-1 | 2026-03-07 | UIKit accessibility API guidance for iOS/tvOS | Primary UIKit accessibility hub for view/control semantics and behavior. |
| APPLE-TVOS-FOCUS | About Focus Interactions for Apple TV | https://developer.apple.com/documentation/uikit/about-focus-interactions-for-apple-tv | Tier-1 | 2026-03-07 | tvOS focus engine behavior and navigation expectations | Primary source for focus-first navigation guidance in tvOS tracks. |
| APPLE-MACOS-NSACCESSIBILITY | NSAccessibility | https://developer.apple.com/documentation/appkit/nsaccessibility-swift.struct | Tier-1 | 2026-03-07 | AppKit accessibility protocol and role/value/action contracts | Primary AppKit source for macOS semantic exposure and notifications. |
| APPLE-WWDC25-MAC-ACCESSIBILITY | Make your Mac app more accessible to everyone (WWDC25) | https://developer.apple.com/videos/play/wwdc2025/229/ | Tier-1 | 2026-03-07 | macOS-specific patterns and modern platform recommendations | Use to shape macOS track guidance and migration notes. |
| APPLE-IOS18-RELEASE-NOTES | iOS/iPadOS 18 Release Notes | https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-18-release-notes | Tier-1 | 2026-03-07 | Official release-note signal for accessibility fixes/regressions | Use for release-gate known-issue verification planning. |
| APPLE-MACOS15-RELEASE-NOTES | macOS 15 Release Notes | https://developer.apple.com/documentation/macos-release-notes/macos-15-release-notes | Tier-1 | 2026-03-07 | Official release-note signal for platform regressions and fixes | Use for macOS regression tracking updates. |
| APPLE-SAFARI18-RELEASE-NOTES | Safari 18 Release Notes | https://developer.apple.com/documentation/safari-release-notes/safari-18-release-notes | Tier-1 | 2026-03-07 | VoiceOver and web accessibility change tracking | Use when app behavior depends on web content surfaces. |
| APPLE-VOICEOVER-RECOGNITION-SUPPORT | Use VoiceOver Recognition on iPhone/iPad | https://support.apple.com/en-us/111799 | Tier-1 | 2026-03-07 | System behavior for image/text recognition and related announcements | Use when diagnosing extra announcements caused by VoiceOver Recognition settings. |
| ADA-2025-WINNERS | Apple Design Awards 2025 Winners and Finalists | https://www.apple.com/newsroom/2025/06/apple-unveils-winners-and-finalists-of-the-2025-apple-design-awards/ | Tier-1 | 2026-03-07 | Apple-recognized inclusive product exemplars | Use for external landscape exemplars and product-pattern discovery. |
| ADA-2024-WINNERS | Apple Design Awards 2024 Winners and Finalists | https://developer.apple.com/design/awards/2024/ | Tier-1 | 2026-03-07 | Apple-recognized inclusive product exemplars | Use for cross-year pattern comparison and landscape references. |
| ADA-2023-WINNERS | Apple Design Awards 2023 Winners and Finalists | https://developer.apple.com/design/awards/2023/ | Tier-1 | 2026-03-07 | Apple-recognized inclusive product exemplars | Use for historical trend context in inclusive product design. |
| ASC-ANL-OVERVIEW | App Store Connect: Overview of Accessibility Nutrition Labels | https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/ | Tier-1 | 2026-03-07 | Label feature definitions and policy framing | Use for feature-scope definitions and app-store reporting context. |
| ASC-ANL-MANAGE | App Store Connect: Manage Accessibility Nutrition Labels | https://developer.apple.com/help/app-store-connect/manage-app-accessibility/manage-accessibility-nutrition-labels/ | Tier-1 | 2026-03-07 | Operational guidance for declaring accessibility support | Use for process and maintenance checks. |

## Tier-2 Sources (Seed)

| source_id | title | url | authority_tier | last_reviewed | scope | notes |
|---|---|---|---|---|---|---|
| SWIFTLEE-A11Y | SwiftLee Accessibility Articles | https://www.avanderlee.com | Tier-2 | 2026-03-07 | Pragmatic Swift/SwiftUI techniques | Find and pin specific article URLs before citation in rules. |
| HWS-SWIFTUI-A11Y | Hacking with Swift: SwiftUI Accessibility | https://www.hackingwithswift.com | Tier-2 | 2026-03-07 | Practical examples and beginner-to-mid workflows | Must be anchored to Tier-1 when promoted to rules. |
| MAJID-A11Y | Swift with Majid: Accessibility Topics | https://swiftwithmajid.com | Tier-2 | 2026-03-07 | Advanced SwiftUI patterns (e.g., representations/rotors) | Pin exact posts in topic-specific docs. |
| USEYOURLOAF-A11Y | Use Your Loaf: Accessibility Updates | https://useyourloaf.com | Tier-2 | 2026-03-07 | API changes and migration notes | Confirm recency before relying on old modifiers. |
| CVS-SWIFTUI-A11Y-TECHNIQUES | CVS Health iOS SwiftUI Accessibility Techniques | https://github.com/cvs-health/ios-swiftui-accessibility-techniques | Tier-2 | 2026-03-07 | Open-source technique examples | Cross-reference each adopted pattern to Tier-1. |
| CVS-COMBINING-FOCUS | CVS Health: Combining Focus Example | https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/CombiningFocus.md | Tier-2 | 2026-03-07 | Concrete grouping/focus example for compound elements | Use as implementation reference; keep Tier-1 grouping docs as authority. |
| SWIFTLEE-SWIFTUI-UIKIT-A11Y | SwiftLee: Accessibility in SwiftUI for UIKit Developers | https://www.avanderlee.com/swiftui/accessibility-uikit-developers/ | Tier-2 | 2026-03-07 | Interop-oriented SwiftUI/UIKit implementation patterns | Practical examples; validate rule claims against Tier-1 Apple sources. |
| CASHAPP-ACCESSIBILITYSNAPSHOT | AccessibilitySnapshot (Cash App) | https://github.com/cashapp/AccessibilitySnapshot | Tier-2 | 2026-03-07 | Snapshot-style accessibility regression testing techniques | Use for optional automation patterns; validate assertions against Tier-1 behavior expectations. |
| APPLE-FORUMS-ACCESSIBILITY-TAG | Apple Developer Forums: Accessibility Tag | https://developer.apple.com/forums/tags/accessibility | Tier-2 | 2026-03-07 | Discovery index for emerging accessibility regressions | Use for reproducible bug discovery and trend tracking; validate against Tier-1 when possible. |
| APPLE-FORUMS-SWIFTUI-TAG | Apple Developer Forums: SwiftUI Tag | https://developer.apple.com/forums/tags/swiftui | Tier-2 | 2026-03-07 | Discovery index for SwiftUI accessibility regressions | Use for symptom discovery and repro collection. |
| APPLE-FORUMS-A11Y-INCLUSION-HUB | Apple Developer Forums: Accessibility and Inclusion Topic | https://developer.apple.com/forums/forums/topics/accessibility-and-inclusion | Tier-2 | 2026-03-07 | Official forum hub for platform accessibility bug discussions | Use as a recurring bug-harvest source. |
| APPLE-FORUMS-THREAD-100449 | VoiceOver Focus Trapped in Container View (Forum Thread) | https://developer.apple.com/forums/thread/100449 | Tier-2 | 2026-03-07 | UIKit container focus-trap symptom and mitigation discussion | Reference for interop/container focus risk class. |
| APPLE-FORUMS-THREAD-750508 | SwiftUI Link Trait Behavior (Forum Thread) | https://developer.apple.com/forums/thread/750508 | Tier-2 | 2026-03-07 | Role/trait mismatch symptom report | Use to flag semantic verification checks on Link-heavy surfaces. |
| APPLE-FORUMS-THREAD-804448 | VoiceOver Reads Text Inside Image (Forum Thread) | https://developer.apple.com/forums/thread/804448 | Tier-2 | 2026-03-07 | OCR-style extra announcement symptom | Use for image-text risk identification and testing. |
| APPLE-FORUMS-THREAD-814208 | SwiftUI Lazy Stack Hang with Accessibility Tools (Forum Thread) | https://developer.apple.com/forums/thread/814208 | Tier-2 | 2026-03-07 | Accessibility-enabled hang/performance regression with nested lazy stacks | Use for performance regression triage playbooks. |
| APPLE-FORUMS-THREAD-725486 | SwiftUI List Reorder Announcement Regression (Forum Thread) | https://developer.apple.com/forums/thread/725486 | Tier-2 | 2026-03-07 | Reorder announcement context loss symptom | Use for reorder-specific VoiceOver regression checks. |
| AXE-CON-SUPPORT | axe-con Accessibility Conference Support Page | https://www.deque.com/axe-con/support/ | Tier-2 | 2026-03-07 | Conference accessibility details and session resource entry point | Use for curated external learning resources with accessibility support. |
| A11YSIG-RECORDINGS | A11ySIG/A11yNYC Recording Archive Example | https://www.a11ysig.org/recording-a11ynyc-digital-accessibilitys-gap-ai-to-bridge-mobile-and-web-barriers-michael-bervell-jason-tan/ | Tier-2 | 2026-03-07 | Community practitioner session archive signal | Use as supplemental conference/community learning source. |

## Tier-3 Sources (Seed)

| source_id | title | url | authority_tier | last_reviewed | scope | notes |
|---|---|---|---|---|---|---|
| COMMUNITY-CONFERENCE-SLIDES | Conference Slide Decks | N/A | Tier-3 | 2026-03-07 | Background context only | Do not cite as sole source for any rule. |
| COMMUNITY-VENDOR-BLOGS | Vendor Blogs | N/A | Tier-3 | 2026-03-07 | Supplemental examples | Require Tier-1 corroboration before adoption. |
| COMMUNITY-FORUM-POSTS | Community Posts/Threads | N/A | Tier-3 | 2026-03-07 | Edge-case discovery | Treat as anecdotal until validated. |
| APPLEVIS-IOS18-VOICEOVER-BRAILLE | AppleVis: iOS 18/iPadOS 18 VoiceOver and Braille Summary | https://www.applevis.com/blog/ios-18-ipados-18-accessibility-summary-voiceover-braille-issues-improvements | Tier-3 | 2026-03-07 | Community trend/impact reporting for OS-level regressions | Use for impact confirmation; pair with Apple release notes/forums. |
| APPLEVIS-RC-THREAD | AppleVis Beta/RC Accessibility Threads | https://www.applevis.com/forum/apple-beta-releases/release-candidates-ios-ipados-182-macos-sequoia-152-tvos-182-visionos-22 | Tier-3 | 2026-03-07 | Early signal for release-cycle regression patterns | Use as early warning only; require corroboration before rule changes. |
| APPLEVIS-HOF | AppleVis App Hall of Fame | https://www.applevis.com/applevis-ios-ipados-app-hall-fame | Tier-3 | 2026-03-07 | Community-recognized examples of sustained accessibility quality | Use for landscape discovery; corroborate implementation rules with Tier-1/Tier-2 sources. |
| STACKOVERFLOW-VO-FOCUS-RESET | VoiceOver Focus Reset Discussion (Stack Overflow) | https://stackoverflow.com/questions/79860389/voiceover-focus-does-not-reset-to-top-when-navigating-between-screens-in-swiftui | Tier-3 | 2026-03-07 | Supplemental symptom report for navigation focus behavior | Treat as anecdotal discovery; validate with Apple sources. |

## Tiering Policy Notes

- Open-source repos can be Tier-2 when maintained and consistent with Apple guidance.
- Any repo-derived technique must map to at least one Tier-1 Apple source before it becomes a project rule.
- When Tier-1 and Tier-2 conflict, Tier-1 wins.

## Freshness Policy

- Apple docs: review quarterly and at each major OS release (iOS, tvOS, macOS).
- WWDC sources: review annually after WWDC season.
- Community sources: review annually and downgrade if stale.

## Stale-Source Downgrade Rules (Actionable)

Apply these rules during freshness review:

1. Trigger conditions:
   - `last_reviewed` exceeds freshness interval for source tier/type.
   - Link is dead, redirected to unrelated content, or materially changed.
   - Guidance conflicts with current Tier-1 Apple documentation.
2. Required actions:
   - Mark source notes with stale/conflict reason and review date.
   - Remove source from new guideline citations until revalidated.
   - If source is Tier-2 and remains stale after one review cycle, downgrade to Tier-3.
   - If source is irrecoverably outdated or unavailable, remove from registry.
3. Guideline impact handling:
   - For each guideline citing a downgraded/removed source, open a follow-up to replace citation.
   - Do not keep a guideline in `Accepted` status if its required Tier-1 citation is invalid.
4. Completion criteria:
   - Registry entry updated (`last_reviewed`, notes, tier if changed).
   - Affected guideline files updated or follow-up issues recorded.
