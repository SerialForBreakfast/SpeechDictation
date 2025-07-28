# GitHub Copilot Instructions for SpeechDictation-iOS

## Project Context
This is a Swift iOS application for speech recognition and dictation with camera-based object detection and scene description capabilities.

## PR Summary Guidelines

When generating PR summaries, please follow these guidelines:

### 1. Focus Areas
- **Speech Recognition**: Changes to transcription, audio processing, or speech-to-text functionality
- **Camera Integration**: Updates to live camera feed, object detection, or scene description
- **UI/UX**: SwiftUI view changes, accessibility improvements, or user interface updates
- **ML Models**: CoreML model integration, object detection, or scene classification changes
- **Services**: Background services, managers, or data processing components
- **Testing**: Unit tests, UI tests, or build automation improvements

### 2. Summary Structure
```markdown
## Summary
Brief overview of what this PR accomplishes

## Key Changes
- List specific changes made
- Focus on user-facing improvements
- Mention any breaking changes

## Technical Details
- Implementation specifics
- Architecture changes
- Performance impacts

## Testing
- What was tested
- How to verify the changes
```

### 3. Code Pattern Recognition
- **Swift Files**: Identify if changes are to ViewModels, Views, Services, or Models
- **Camera Code**: Recognize AVFoundation, Vision framework, or CoreML changes
- **Speech Code**: Identify Speech framework or audio processing updates
- **UI Code**: SwiftUI view modifications or accessibility improvements

### 4. Impact Assessment
- **Breaking Changes**: Flag any API changes or deprecations
- **Performance**: Note any performance improvements or concerns
- **Accessibility**: Highlight accessibility enhancements
- **User Experience**: Describe user-facing improvements

### 5. Related Issues
- Always link to related GitHub issues
- Reference any bug fixes or feature implementations
- Mention any dependencies or prerequisites

## Example PR Summary Format

```markdown
## 🎯 Summary
Fixed redundant logging and enhanced tap-to-focus functionality in camera module.

## 🔧 Key Changes
- **Logging Optimization**: Implemented state-based logging to reduce console noise by 90%
- **Focus Enhancement**: Added comprehensive debugging for tap-to-focus issues
- **Performance**: Eliminated unnecessary string formatting overhead

## 📱 User Impact
- Cleaner development logs for better debugging experience
- Improved camera focus reliability (debugging added)
- No user-facing changes in this PR

## 🧪 Testing
- ✅ All builds pass
- ✅ Camera focus debugging logs added
- ✅ Logging reduction verified

## 📋 Files Changed
- `Models/YOLOv3Model.swift` - State-based object detection logging
- `Services/CameraSceneDescriptionViewModel.swift` - Frame processing optimization
- `Views/LiveCameraView.swift` - Enhanced focus debugging
```

## Automatic Tagging
Based on file patterns, suggest these labels:
- `swift` - Any .swift file changes
- `ui` - SwiftUI view or UI-related changes
- `camera` - Camera, Vision, or ML model changes
- `speech` - Speech recognition or audio processing
- `testing` - Test file modifications
- `documentation` - README or .md file updates
- `ci/cd` - GitHub Actions or build script changes
- `size/small` - < 50 lines changed
- `size/medium` - 50-200 lines changed
- `size/large` - > 200 lines changed 