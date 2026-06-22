# ILSpatial

ILSpatial is a modular visionOS training application built to demonstrate advanced spatial computing architectures, RealityKit ECS (Entity Component System) patterns, and strict dependency management in Swift.

## Overview

The application serves as an example of building scalable, modular spatial apps using SwiftUI and RealityKit. It heavily leverages Swift Packages to separate features and core utilities, ensuring that the main App layer acts purely as a composition root.

## Architecture

The project follows a strict modular architecture inspired by Apple's best practices for visionOS development:

```
App (Composition Root)
 ├── ILSHandTracking (Feature)
 ├── ILSSpatialDraw (Feature)
 ├── ILSSpatialAudio (Feature)
 └── Core Packages
      ├── ILSEngine (ECS Systems, RealityKit Integration)
      └── ILSFoundation (Shared Utilities, Types)
```

- **App Layer**: The only layer that knows about all modules. It acts as the "wiring" layer, injecting dependencies downward.
- **Feature Modules**: Encapsulate distinct domains like Hand Tracking or Spatial Audio. They depend on Core modules but not on each other.
- **Core Packages**: Foundational utilities and engines that handle heavy lifting without any knowledge of the features that use them.

## Key Features

- **Entity Component System (ECS)**: Centralized system registration and lifecycle management via RealityKit.
- **Hand Tracking (`ILSHandTracking`)**: Implements ARKit hand anchors for immersive interaction.
- **Spatial Audio (`ILSSpatialAudio`)**: Immersive audio setups for RealityKit entities.
- **Spatial Draw (`ILSSpatialDraw`)**: Core logic for drawing dynamically in 3D space.
- **Telemetry Bridge**: Connects the 90Hz ECS loop to SwiftUI's 15Hz rendering cycle for smooth data flow.

## Getting Started

### Prerequisites
- macOS 14.0+
- Xcode 15.0+ (with visionOS 1.0+ SDK installed)
- Apple Vision Pro Simulator or Physical Device

### Building and Running

1. Open `ILSpatial.xcodeproj` or generate the project if using XcodeGen (`xcodegen`).
2. Select the **ILSpatialApp** scheme.
3. Choose a destination (e.g., Apple Vision Pro Simulator).
4. Run the project (`Cmd + R`).

## Assets & RealityKit Content

This project incorporates custom `.rkassets` via Reality Composer Pro, containing:
- Environment and terrain materials (PBR shaders, Cloud shaders, Riverbed, etc.)
- 3D Geometries (Canyons, Trails, Hikers, Signposts)
- Custom IBLs and texture maps

These are managed within the `ILSRealityAssets` package.

## License

This project is part of a VisionOS training curriculum and is intended for educational purposes.
