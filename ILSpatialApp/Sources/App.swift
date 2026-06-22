//
//  App.swift
//  ILSpatialApp
//

import SwiftUI
import RealityKit

// ── Import ALL feature modules ──
import ILSHandTracking
import ILSSpatialDraw
import ILSSpatialAudio

// ── Import Core packages needed for setup ──
import ILSEngine
import ILSFoundation

// MARK: - ILSpatial App
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// The App layer is the ONLY place that knows about ALL modules.
// It's the "wiring" layer — it creates dependencies, injects
// them into features, and registers ECS systems.
//
// Think of it as the root of a tree:
//
//   App (knows everything)
//   ├── ILSHandTracking (knows Core)
//   ├── ILSSpatialDraw (knows Core)
//   ├── ILSSpatialAudio (knows Core)
//   └── Core packages (know only each other)
//
// No other layer imports the App. Dependencies flow DOWNWARD.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@main
struct ILSpatialApp: App {
    
    // ── Shared dependencies (created once, injected everywhere) ──
    // Composition Root: Instantiate services as State to manage their lifecycle
    @State private var handTrackingService = HandTrackingService.shared
    @State private var spatialAudioService = SpatialAudioService()
    
    // The telemetry bridge connects ECS (90Hz) to SwiftUI (15Hz)
    // (A mock to show parity with VisionSampleModularArchitecture)
    @StateObject private var telemetryBridge = TelemetryBridgeMock()
    
    init() {
        // ★ Register all ECS systems at app startup ★
        // Centralized RealityKit Component & System Registration
        SystemRegistry.registerAllSystems()
        print("ILSpatial App Initialized & Systems Registered")
    }
    
    var body: some SwiftUI.Scene {
        // ── Main window (2D SwiftUI/Volumetric) ──
        WindowGroup {
            MainView()
                .environmentObject(telemetryBridge)
        }
        .defaultSize(width: 600, height: 400)
        
        // ── Immersive space (3D RealityKit) ──
        // Opened via openImmersiveSpace(id:)
        ImmersiveSpace(id: "ImmersiveSpace") {
            // In production, pass actual configuration data
            let sampleConfig = WorkspaceConfiguration(
                id: "workspace-demo",
                theme: .dark,
                enableCollision: true,
                maxDrawingEntities: 500
            )
            
            // Example of passing concrete dependencies and data flows, 
            // instead of just dropping services on a random RealityKit Entity.
            SpatialWorkspaceView(
                config: sampleConfig,
                handTracking: handTrackingService,
                audio: spatialAudioService
            )
        }
    }
}

// MARK: - Mock Examples for Parity
// These simulate how you should build robust dependencies

class TelemetryBridgeMock: ObservableObject {
    @Published var fps: Int = 90
    @Published var activeEntities: Int = 0
}

struct WorkspaceConfiguration {
    let id: String
    let theme: Theme
    let enableCollision: Bool
    let maxDrawingEntities: Int
    
    enum Theme { case light, dark }
}

struct SpatialWorkspaceView: View {
    let config: WorkspaceConfiguration
    let handTracking: HandTrackingService
    let audio: SpatialAudioService
    
    var body: some View {
        RealityView { content in
            // Apply config logic...
            print("Loaded Workspace: \(config.id) with limit \(config.maxDrawingEntities)")
            
            // 1. Hand tracking entities (From ILSHandTracking)
            let hands = HandEntitySpawner.spawnHands()
            for hand in hands {
                content.add(hand)
            }
            
            // 2. Canvas entity (From ILSSpatialDraw)
            let canvas = Entity()
            canvas.name = "Canvas"
            canvas.components.set(CanvasComponent())
            content.add(canvas)
            
            // 3. Draw controller (From ILSSpatialDraw)
            // It reads HandTracking via ECS without explicitly binding to it here!
            var drawComp = DrawingComponent()
            drawComp.currentColor = ILSColor.cyan.simd
            drawComp.sphereRadius = 0.01
            
            let drawController = Entity()
            drawController.name = "DrawController"
            drawController.components.set(drawComp)
            drawController.components.set(ILHandAnchorComponent())
            drawController.components.set(IsDrawingComponent())
            content.add(drawController)
            
        }
        .task {
            // Start the ARKit HandTracking Provider!
            // Without this, the ECS never gets joint updates.
            try? await handTracking.start()
        }
    }
}
