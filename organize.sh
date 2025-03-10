#!/bin/bash

# Create platform-specific directories
mkdir -p src/macos
mkdir -p src/windows
mkdir -p shared

# Move current macOS implementation
mv AnyTalk/* src/macos/

# Create shared code directory structure
mkdir -p shared/models
mkdir -p shared/services
mkdir -p shared/utilities

# Move platform-independent code to shared
mv src/macos/Models/* shared/models/
mv src/macos/Services/WhisperService.swift shared/services/
mv src/macos/Services/HistoryManager.swift shared/services/
mv src/macos/Utilities/* shared/utilities/
