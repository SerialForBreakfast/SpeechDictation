# SwiftUI Semantics Checklist Taxonomy

Last updated: 2026-03-07

## Canonical Semantic Fields

Every meaningful UI element should be validated for:

- Label
- Value
- Hint
- Traits/Role
- Actions

## Field Mapping

### Label

- SwiftUI APIs:
  - `.accessibilityLabel(_:)`
  - Text content (implicit label when accurate)
  - `Image(decorative:)` for non-semantic imagery
- UIKit equivalents:
  - `accessibilityLabel`
- Common failure modes:
  - Icon-only controls without labels.
  - Duplicate labels for sibling controls.
  - Vague labels ("Tap here", "Button").

### Value

- SwiftUI APIs:
  - `.accessibilityValue(_:)`
  - Control-native values for `Toggle`, `Slider`, etc.
- UIKit equivalents:
  - `accessibilityValue`
- Common failure modes:
  - Stateful controls that announce no state.
  - Visual state differs from spoken state.

### Hint

- SwiftUI APIs:
  - `.accessibilityHint(_:)`
- UIKit equivalents:
  - `accessibilityHint`
- Common failure modes:
  - Hint repeats label/value with no added action context.
  - Critical interaction detail omitted.

### Traits/Role

- SwiftUI APIs:
  - `.accessibilityAddTraits(_:)`
  - `.accessibilityRemoveTraits(_:)`
  - Native control semantics where possible
  - `.accessibilityHeading(_:)` for heading structure
- UIKit equivalents:
  - `accessibilityTraits`
- Common failure modes:
  - Generic `View` used where semantic control should be used.
  - Missing heading traits for section landmarks.
  - Incorrect trait combinations causing misleading announcements.

### Actions

- SwiftUI APIs:
  - `.accessibilityAction(_:)`
  - `.accessibilityActions { ... }`
  - `.accessibilityAdjustableAction(_:)`
- UIKit equivalents:
  - `accessibilityCustomActions`
  - `accessibilityIncrement` / `accessibilityDecrement`
- Common failure modes:
  - Gesture-only behavior inaccessible to assistive tech.
  - Missing adjustable actions for increment/decrement controls.
  - Hidden destructive actions with unclear spoken context.

## Grouping and Containment Taxonomy

- `Combine`: treat children as one accessible element when they represent one concept.
- `Contain`: keep parent and children navigable as related content.
- `Ignore`: remove noisy/decorative descendants from traversal.

SwiftUI APIs:

- `.accessibilityElement(children: .combine)`
- `.accessibilityElement(children: .contain)`
- `.accessibilityElement(children: .ignore)`
- `.accessibilityHidden(_:)`

Failure modes:

- Over-grouping that hides actionable children.
- Under-grouping that causes repetitive noise.
- Decorative elements remaining in focus order.

## Focus and Reading Order Taxonomy

Core checks:

- Logical top-to-bottom, left-to-right progression (or equivalent visual hierarchy).
- No focus traps in sheets/modals.
- Headings and landmarks are discoverable.

SwiftUI APIs:

- `.accessibilitySortPriority(_:)`
- Structural order in view hierarchy
- Focus-state modifiers when custom focus handling is required

Interop risks:

- UIKit containers changing presentation order.
- Representables introducing detached subtrees.

## Verification Matrix

For each field in this taxonomy, each guideline should include:

- Inspector check: what to look for in hierarchy/properties.
- VoiceOver check: what should be spoken and in what order.
- Automation hook: possible XCUITest assertion (identifier/label/state).
