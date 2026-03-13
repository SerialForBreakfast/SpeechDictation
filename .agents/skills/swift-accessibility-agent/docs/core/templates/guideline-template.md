# Accessibility Guideline Template

Use this template for every guideline.

---

## Title

Short, specific rule name.

## Problem Statement

What user impact happens when this is done incorrectly.

## Rule

Normative instruction written as a testable requirement.

## Rationale

Why this rule matters for assistive technology behavior and usability.

## How To Implement

### SwiftUI

- Primary modifiers/APIs to use.
- Preferred control semantics over custom views when possible.

### UIKit/AppKit Interop Notes

- Equivalent UIKit/AppKit properties/APIs.
- Any `UIHostingController` / representable / `NSHostingView` caveats.

## How To Test

### Accessibility Inspector

- Exact property or tree checks to perform.

### VoiceOver Walkthrough

- Expected focus order and spoken output.

### Optional XCUITest Hook

- What can be asserted automatically (identifier/label/value/order surrogate).

## Do / Don't

- Do: concise positive example (pseudocode allowed).
- Don't: concise anti-pattern example.

## Citations

At least one Tier-1 source is required.

- [SOURCE_ID] URL
- [SOURCE_ID] URL

## Quote Snippets (Optional)

Use only when clarifying a rule. Keep each quote short and compliant.

- `[SOURCE_ID]` "<=25-word quote"

## Metadata

- Status: Draft | Accepted | Deprecated
- Last Reviewed: YYYY-MM-DD
- Platforms: iOS | iPadOS | macOS | watchOS | tvOS
- Confidence: High | Medium | Low
