import Foundation
import RealityKit
import ILSHandTracking
import ILSSpatialDraw
import ILSSpatialAudio

public struct PinkyGestureSystem: System {
    static let query = EntityQuery(where: .has(IsDrawingComponent.self) && .has(ILHandAnchorComponent.self) && .has(DrawingComponent.self))
    
    public init(scene: RealityKit.Scene) {}
    
    public func update(context: SceneUpdateContext) {
        let entities = context.entities(matching: Self.query, updatingSystemWhen: .rendering)
        
        for entity in entities {
            guard var isDrawingComp = entity.components[IsDrawingComponent.self],
                  let anchorComp = entity.components[ILHandAnchorComponent.self],
                  let anchor = anchorComp.rightHand,
                  let skeleton = anchor.handSkeleton else {
                
                if var idc = entity.components[IsDrawingComponent.self] {
                    idc.frameCount = 0
                    idc.isActive = false
                    entity.components.set(idc)
                }
                continue
            }
            
            // Detect gesture: pinky extended, all other fingers curled
            let isPinkyExtended = !ILHandPoseUtilities.isFingerCurled(
                skeleton: skeleton, tip: .littleFingerTip, knuckle: .littleFingerKnuckle
            )
            let thumbCurled  = ILHandPoseUtilities.isThumbCurled(skeleton: skeleton)
            let indexCurled  = ILHandPoseUtilities.isFingerCurled(skeleton: skeleton, tip: .indexFingerTip,  knuckle: .indexFingerKnuckle)
            let middleCurled = ILHandPoseUtilities.isFingerCurled(skeleton: skeleton, tip: .middleFingerTip, knuckle: .middleFingerKnuckle)
            let ringCurled   = ILHandPoseUtilities.isFingerCurled(skeleton: skeleton, tip: .ringFingerTip,   knuckle: .ringFingerKnuckle)
            
            let pinkyGestureActive = isPinkyExtended && thumbCurled && indexCurled && middleCurled && ringCurled
            
            // Anti-jitter: require 3 consecutive frames
            if pinkyGestureActive {
                isDrawingComp.frameCount = min(isDrawingComp.frameCount + 1, 10)
            } else {
                isDrawingComp.frameCount = max(isDrawingComp.frameCount - 1, 0)
            }
            
            isDrawingComp.isActive = (isDrawingComp.frameCount >= 3)
            
            if isDrawingComp.isActive {
                isDrawingComp.tipPosition = ILHandPoseUtilities.worldPosition(
                    of: .littleFingerTip, handAnchor: anchor, skeleton: skeleton
                )
            }
            
            entity.components.set(isDrawingComp)
        }
    }
}
