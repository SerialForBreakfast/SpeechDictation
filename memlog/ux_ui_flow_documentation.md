# UX/UI Flow Documentation - SpeechDictation iOS

## Overview

This document provides comprehensive UX/UI flow diagrams for the SpeechDictation iOS app, documenting all user behaviors, decision points, and system responses. The diagrams use **Mermaid** format for easy maintenance and version control.

## Why Mermaid for UX/UI Documentation?

**Mermaid** is the ideal format for UX/UI flow documentation because:

- **Version Controllable** - Text-based format lives with your code
- **Easy to Update** - Simple syntax that developers can maintain
- **Professional Rendering** - Beautiful diagrams in documentation
- **Clear Decision Points** - Shows user choices and system responses
- **Multiple Diagram Types** - Flowcharts, state diagrams, user journeys
- **Collaboration Friendly** - Can be edited by entire team

## Diagram Types Used

### 1. **Overall User Flow** - Complete navigation structure
### 2. **State Diagram** - App states and transitions
### 3. **Activity Diagram** - Detailed user actions and system responses
### 4. **Speech Synthesis Flow** - Key feature behavior (YOLO vs Scene)
### 5. **User Journey Map** - Complete user experience across scenarios

---

## 1. Overall User Flow Diagram

**Purpose**: Shows the complete navigation structure and decision points across the entire app.

**Key Insights**:
- **Dual Entry Point**: Audio Transcription (recommended) vs Camera Experience (experimental)
- **Permission-Based Flow**: Camera experience requires permission checks
- **Settings Integration**: Both experiences have dedicated settings flows
- **Export System**: Multiple format options with unified sharing
- **Model Management**: Separate flow for ML model handling

**Usage**: Use this diagram to understand the complete user journey and plan new features.

---

## 2. State Diagram

**Purpose**: Shows all possible states the app can be in and valid transitions between them.

**Key Insights**:
- **Clear State Separation**: Audio and Camera experiences are separate state machines
- **Nested States**: Complex flows like Camera Active and Model Management have sub-states
- **Permission Handling**: Explicit permission states prevent invalid transitions
- **Settings States**: Both main flows have dedicated settings state machines

**Usage**: Use this diagram for testing state transitions and handling edge cases.

---

## 3. Activity Diagram

**Purpose**: Shows detailed user actions and system responses in sequence.

**Key Insights**:
- **User Actions vs System Responses**: Clear distinction between user inputs and system processing
- **Permission Flows**: Detailed permission request and handling sequences
- **ML Processing Pipeline**: Shows how camera frames are processed through ML models
- **Error Handling**: Error states and recovery paths are explicitly shown
- **Speech Synthesis**: Detailed flow showing when and how speech is generated

**Usage**: Use this diagram for implementation planning and debugging user flows.

---

## 4. Speech Synthesis Flow

**Purpose**: Shows the key differentiator - YOLO objects get distance information, scene descriptions don't.

**Key Insights**:
- **Distance Information**: YOLO objects include distance measurements (LiDAR, ARKit, ML models)
- **Scene Classification**: Scene descriptions are labels only (no distance)
- **Speech Timing**: 2-second minimum interval prevents repetitive announcements
- **User Control**: Audio descriptions can be disabled independently
- **Error Recovery**: Graceful handling of ML model failures

**Usage**: Use this diagram to understand the core speech synthesis behavior and troubleshoot audio issues.

---

## 5. User Journey Map

**Purpose**: Shows the complete user experience across different scenarios with satisfaction ratings.

**Key Insights**:
- **Permission Friction**: Camera and microphone permissions create low satisfaction points
- **Core Experience**: Recording and object detection are high satisfaction activities
- **Settings Complexity**: Model management and advanced settings are lower satisfaction
- **Export Success**: Sharing content is a high satisfaction endpoint
- **Error Recovery**: Permission and model errors create very low satisfaction

**Usage**: Use this diagram to prioritize UX improvements and identify pain points.

---

## Best Practices for UX/UI Flow Documentation

### 1. **Keep Diagrams Updated**
- Update diagrams when adding new features
- Include diagram updates in pull requests
- Review diagrams during design reviews

### 2. **Use Consistent Styling**
- Color-code different types of flows (audio, camera, settings)
- Use consistent symbols for decision points
- Highlight critical paths and error states

### 3. **Document Edge Cases**
- Include permission denied scenarios
- Show error recovery paths
- Document accessibility flows

### 4. **Make Diagrams Actionable**
- Link to implementation files
- Include user story references
- Add testing scenarios

### 5. **Version Control Integration**
- Store diagrams in memlog folder
- Include in documentation reviews
- Update changelog when flows change

## Implementation Notes

### Current Implementation Status
- **Overall Flow**: Implemented with EntryView and dual experience selection
- **Audio Transcription**: Complete implementation with settings and export
- **Camera Experience**: Implemented with ML models and speech synthesis
- **Speech Synthesis**: YOLO objects include distance, scene descriptions don't
- **Settings Management**: Comprehensive settings for both experiences
- **Export System**: Multiple format support with sharing
- **Model Management**: Basic model store and management (placeholder)

### Future Enhancements
- **Advanced Model Management**: Full model store with download/updates
- **Background Processing**: Continue processing when app is backgrounded
- **Cloud Sync**: Sync settings and recordings across devices
- **Enhanced Accessibility**: Additional VoiceOver and accessibility features
- **Performance Optimization**: Improved ML model loading and processing

---

## Usage Instructions

### For Developers
1. **Reference these diagrams** when implementing new features
2. **Update diagrams** when changing user flows
3. **Use for code reviews** to ensure UX consistency
4. **Test edge cases** documented in the diagrams

### For Designers
1. **Use as wireframe foundation** for new feature design
2. **Identify UX improvement opportunities** from user journey ratings
3. **Design for error states** and recovery paths
4. **Consider accessibility** in all user flows

### For Product Managers
1. **Use for feature prioritization** based on user satisfaction
2. **Identify bottlenecks** in user journeys
3. **Plan A/B tests** around low-satisfaction touchpoints
4. **Document requirements** using flow diagrams

### For QA Engineers
1. **Create test cases** from activity diagrams
2. **Test state transitions** documented in state diagrams
3. **Validate error handling** paths
4. **Verify accessibility** flows

---

## Maintenance

This documentation should be:
- **Reviewed monthly** for accuracy
- **Updated with new features** immediately
- **Validated against implementation** regularly
- **Referenced in technical discussions** and design reviews

---

## Related Documentation

- [Technical Architecture](../README.md)
- [Task Management](tasks.md)
- [Changelog](changelog.md)
- [Directory Structure](directory_tree.md)

---

*Last Updated: 2025-01-12*
*Version: 1.0.0* 