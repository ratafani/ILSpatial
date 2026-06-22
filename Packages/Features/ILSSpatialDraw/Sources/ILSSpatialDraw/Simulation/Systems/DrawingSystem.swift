import Foundation
import RealityKit

class DrawingResourceCache {
    private var materials: [SIMD4<Float>: UnlitMaterial] = [:]

    func material(for color: SIMD4<Float>) -> UnlitMaterial {
        if let existing = materials[color] { return existing }
        var newMaterial = UnlitMaterial()
        newMaterial.color = .init(tint: .init(
            red:   CGFloat(color.x),
            green: CGFloat(color.y),
            blue:  CGFloat(color.z),
            alpha: CGFloat(color.w)
        ))
        materials[color] = newMaterial
        return newMaterial
    }
    
    func clear() {
        materials.removeAll()
    }
}

public struct DrawingSystem: System {
    static let drawQuery     = EntityQuery(where: .has(DrawingComponent.self) && .has(IsDrawingComponent.self))
    static let canvasQuery   = EntityQuery(where: .has(CanvasComponent.self))
    static let receiverQuery = EntityQuery(where: .has(SharePlayReceiverComponent.self))

    /// Min distance between spawned points
    static let minSpacing: Float = 0.003
    
    private let resourceCache = DrawingResourceCache()
    
    // Remote stroke tracking
    private var remoteStrokeEntities: [UUID: Entity] = [:]
    private var remoteStrokePoints: [UUID: [SIMD3<Float>]] = [:]

    public init(scene: RealityKit.Scene) {}

    public mutating func update(context: SceneUpdateContext) {
        let canvasEntities   = context.entities(matching: Self.canvasQuery,   updatingSystemWhen: .rendering)
        let receiverEntities = context.entities(matching: Self.receiverQuery, updatingSystemWhen: .rendering)
        let drawEntities     = context.entities(matching: Self.drawQuery,     updatingSystemWhen: .rendering)

        guard let canvas = canvasEntities.first(where: { _ in true }) else { return }

        // 1. Check for a local clear request written into CanvasComponent
        if var canvasComp = canvas.components[CanvasComponent.self], canvasComp.clearRequested {
            clearCanvas(canvas)
            canvasComp.clearRequested = false
            canvas.components.set(canvasComp)
        }

        // 2. Process incoming SharePlay strokes
        if let receiver = receiverEntities.first(where: { _ in true }),
           let manager  = receiver.components[SharePlayReceiverComponent.self]?.manager {
            let remoteStrokes = manager.consumeRemoteStrokes()
            for stroke in remoteStrokes {
                switch stroke.action {
                case .addPoint:
                    let id = stroke.strokeID
                    if remoteStrokePoints[id] == nil {
                        remoteStrokePoints[id] = []
                    }
                    remoteStrokePoints[id]?.append(stroke.position)
                    
                    updateMesh(
                        points: remoteStrokePoints[id]!,
                        color: stroke.color,
                        radius: stroke.radius,
                        entityRef: &remoteStrokeEntities[id],
                        on: canvas
                    )
                case .endStroke:
                    let id = stroke.strokeID
                    remoteStrokePoints.removeValue(forKey: id)
                    // We keep the entity in the scene, but remove it from the active tracking maps
                    remoteStrokeEntities.removeValue(forKey: id)
                case .clear:
                    clearCanvas(canvas)
                }
            }
        }

        // 3. Handle local drawing — reads from IsDrawingComponent set by a gesture system
        for entity in drawEntities {
            guard var dc = entity.components[DrawingComponent.self],
                  let isDrawingComp = entity.components[IsDrawingComponent.self] else {
                continue
            }

            if isDrawingComp.isActive {
                let tipPos = isDrawingComp.tipPosition
                
                if dc.currentStrokeID == nil {
                    dc.currentStrokeID = UUID()
                }

                let shouldSpawn: Bool
                if let lastPos = dc.lastPlacedPosition {
                    shouldSpawn = simd_distance(tipPos, lastPos) > Self.minSpacing
                } else {
                    shouldSpawn = true
                }

                if shouldSpawn {
                    dc.lastPlacedPosition = tipPos
                    dc.activeStrokePoints.append(tipPos)
                    
                    if !dc.isGeneratingMesh {
                        dc.isGeneratingMesh = true
                        updateMeshAsync(
                            points: dc.activeStrokePoints,
                            color: dc.currentColor,
                            radius: dc.sphereRadius,
                            entityRef: &dc.activeStrokeEntity,
                            on: canvas,
                            owner: entity
                        )
                    }

                    // Broadcast via SharePlay if active (throttle to ~10Hz)
                    let currentTime = Date().timeIntervalSince1970
                    if currentTime - dc.lastSharePlaySyncTime > 0.1 {
                        dc.lastSharePlaySyncTime = currentTime
                        if let receiver = receiverEntities.first(where: { _ in true }),
                           let manager  = receiver.components[SharePlayReceiverComponent.self]?.manager,
                           manager.isSharing,
                           let strokeID = dc.currentStrokeID {
                            let msg = StrokeMessage.addPoint(
                                strokeID: strokeID,
                                senderID: manager.localParticipantID,
                                position: tipPos,
                                color:    dc.currentColor,
                                radius:   dc.sphereRadius
                            )
                            Task { await manager.sendStroke(msg) }
                        }
                    }

                    // Increment canvas stroke count
                    if var canvasComp = canvas.components[CanvasComponent.self] {
                        canvasComp.strokeCount += 1
                        canvas.components.set(canvasComp)
                    }
                }
            } else {
                // Stroke ended
                if let strokeID = dc.currentStrokeID,
                   let receiver = receiverEntities.first(where: { _ in true }),
                   let manager  = receiver.components[SharePlayReceiverComponent.self]?.manager,
                   manager.isSharing {
                    let msg = StrokeMessage.endStroke(strokeID: strokeID, senderID: manager.localParticipantID)
                    Task { await manager.sendStroke(msg) }
                }
                
                dc.lastPlacedPosition = nil
                dc.activeStrokeEntity = nil
                dc.currentStrokeID = nil
                dc.activeStrokePoints.removeAll()
            }

            entity.components.set(dc)
        }
    }

    // MARK: - Helpers

    private func updateMeshAsync(points: [SIMD3<Float>], color: SIMD4<Float>, radius: Float, entityRef: inout Entity?, on canvas: Entity, owner: Entity) {
        if points.count < 2 {
            if entityRef == nil {
                let material = resourceCache.material(for: color)
                let sphereMesh = MeshResource.generateSphere(radius: radius)
                let strokeEntity = ModelEntity(mesh: sphereMesh, materials: [material])
                strokeEntity.setPosition(.zero, relativeTo: nil) // We will supply world-space vertices
                canvas.addChild(strokeEntity)
                entityRef = strokeEntity
            }
            if var dc = owner.components[DrawingComponent.self] {
                dc.isGeneratingMesh = false
                owner.components.set(dc)
            }
            return
        }

        guard let strokeEntity = entityRef as? ModelEntity else { 
            if var dc = owner.components[DrawingComponent.self] {
                dc.isGeneratingMesh = false
                owner.components.set(dc)
            }
            return 
        }

        Task { @MainActor in
            let descriptor = await Task.detached(priority: .userInitiated) {
                TubeMeshBuilder.generateMeshDescriptor(from: points, radius: radius)
            }.value
            
            do {
                if let existingMesh = strokeEntity.model?.mesh {
                    try existingMesh.replace(with: [descriptor])
                } else {
                    strokeEntity.model?.mesh = try MeshResource.generate(from: [descriptor])
                }
            } catch {
                print("Failed to replace mesh: \(error)")
            }
            
            if var dc = owner.components[DrawingComponent.self] {
                dc.isGeneratingMesh = false
                owner.components.set(dc)
            }
        }
    }

    private mutating func clearCanvas(_ canvas: Entity) {
        canvas.children.removeAll()
        remoteStrokeEntities.removeAll()
        remoteStrokePoints.removeAll()
    }
}
