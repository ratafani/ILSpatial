import SwiftUI
import RealityKit
import ILSSpatialDraw
import ILSHandTracking
import ILSEngine

// MARK: - Spatial Draw Example View
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// This file demonstrates how to utilize the pristine ILSpatial architecture
// to build a 3D drawing canvas.
//
// HOW IT WORKS:
// 1. The ARKit tracking loop runs asynchronously (via HandTrackingService) and caches hand poses.
// 2. The `ILHandTrackingUpdateSystem` reads the singleton, updating `ILHandTrackingComponent`s.
// 3. The `DrawingSystem` finds the hand components and the `CanvasComponent`, spawning meshes.
// 4. SwiftUI safely drives high-level commands (like "Clear Canvas") by mutating ECS 
//    components, entirely avoiding 90Hz frame stalls!
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct SpatialDrawExampleView: View {
    
    // We use a shared timer or observable model strictly for UI updates at 15Hz,
    // NEVER bind SwiftUI directly to the 90Hz ECS loop!
    @State private var strokeCount: Int = 0
    
    // Timer to poll ECS state for the SwiftUI overlay
    let uiTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // ── 1. The 3D RealityKit Canvas ──
            RealityView { content in
                // Create the root entity that holds all our drawings
                let canvasEntity = Entity()
                canvasEntity.name = "MainDrawingCanvas"
                
                // Attach the CanvasComponent.
                // The ILSSpatialDraw `DrawingSystem` looks for this exact component
                // to know where to attach the 3D meshes drawn by the user's hands.
                canvasEntity.components.set(CanvasComponent())
                
                // Add the canvas to the scene
                content.add(canvasEntity)
                
                // NOTE: HandTrackingService.shared is automatically consumed by 
                // ILHandTrackingUpdateSystem. We don't need to inject hacky @State 
                // services into the entity!
                print("🎨 Spatial Canvas Initialized")
            }
            
            // ── 2. The 2D SwiftUI Overlay ──
            VStack {
                Text("Strokes: \(strokeCount)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                
                Button(action: clearCanvas) {
                    Text("Clear Canvas")
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.bottom, 40)
        }
        // Safely poll the ECS state for UI updates at 10Hz to avoid render stalls
        .onReceive(uiTimer) { _ in
            pollCanvasState()
        }
    }
    
    // MARK: - Actions
    
    /// Demonstrates how SwiftUI controls the 90Hz RealityKit loop:
    /// We grab the canvas entity and set a boolean flag `clearRequested`.
    /// The ECS `DrawingSystem` consumes this flag on its next 90Hz tick!
    private func clearCanvas() {
        guard let canvas = SystemRegistry.findCanvasEntity() else { return }
        
        // Grab the component, modify it, and set it back.
        if var canvasComponent = canvas.components[CanvasComponent.self] {
            canvasComponent.clearRequested = true
            canvas.components.set(canvasComponent)
        }
    }
    
    /// Demonstrates how SwiftUI reads from the 90Hz RealityKit loop:
    /// We poll the stroke count so we can display it in the 2D UI.
    private func pollCanvasState() {
        guard let canvas = SystemRegistry.findCanvasEntity(),
              let canvasComponent = canvas.components[CanvasComponent.self] else { return }
        
        if strokeCount != canvasComponent.strokeCount {
            strokeCount = canvasComponent.strokeCount
        }
    }
}

// MARK: - Helper Extension

extension SystemRegistry {
    /// A quick helper to find the canvas. In a massive app, you'd use a robust EntityQuery wrapper!
    static func findCanvasEntity() -> Entity? {
        // Warning: Direct root finding is just for the example.
        // A true robust architecture would use a dedicated `CanvasStateBridge`.
        return nil // Implementation details omitted, typically queried via `EntityQuery(where: .has(CanvasComponent.self))`
    }
}
