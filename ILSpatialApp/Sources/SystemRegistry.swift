import Foundation
import RealityKit
import ILSEngine
import ILSHandTracking
import ILSSpatialDraw
import ILSSpatialAudio

public struct SystemRegistry {
    public static func registerAllSystems() {
        // Core/Engine Components
        ILHittableComponent.registerComponent()
        ILHitEventComponent.registerComponent()
        ILSquashAnimationComponent.registerComponent()
        ILSquashIntentComponent.registerComponent()
        
        // Core/Engine Systems
        ILSquashAnimationSystem.registerSystem()
        
        // Feature Systems
        ILFeatureHandTrackingSetup.registerSystems()
        ILFeatureSpatialDrawSetup.registerSystems()
    }
}
