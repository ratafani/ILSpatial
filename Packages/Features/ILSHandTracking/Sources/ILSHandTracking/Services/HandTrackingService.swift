import Foundation
import ARKit
import ILSFoundation

public protocol HandTrackingServiceProtocol: SpatialServiceProtocol {
    var isTracking: Bool { get }
    var latestLeftHand: HandAnchor? { get }
    var latestRightHand: HandAnchor? { get }
}

public final class HandTrackingService: HandTrackingServiceProtocol {
    public static let shared = HandTrackingService()
    private let session = ARKitSession()
    private let handTracking = HandTrackingProvider()
    private let logger = ILLogger(subsystem: .handTracking, category: "HandTrackingService")
    public private(set) var isTracking = false
    
    private var updateTask: Task<Void, Never>?
    
    public var latestLeftHand: HandAnchor?
    public var latestRightHand: HandAnchor?
    
    public init() {}
    
    public func start() async throws {
        guard HandTrackingProvider.isSupported else {
            logger.warning("Hand tracking not supported on this device.")
            return
        }
        
        // Request authorization from the user before running the session!
        // Without this, ARKit will silently drop all hand anchor updates.
        let authorizationResult = await session.requestAuthorization(for: [.handTracking])
        for (providerType, status) in authorizationResult {
            if status != .allowed {
                logger.warning("Authorization for \(providerType) denied or not determined.")
                return
            }
        }
        
        try await session.run([handTracking])
        isTracking = true
        logger.info("Hand Tracking Started")
        
        updateTask = Task {
            for await update in handTracking.anchorUpdates {
                let anchor = update.anchor
                if anchor.chirality == .left {
                    self.latestLeftHand = anchor
                } else if anchor.chirality == .right {
                    self.latestRightHand = anchor
                    // Log once every ~60 frames to avoid spamming, just to confirm stream
                    if Int.random(in: 1...60) == 1 {
                        self.logger.info("Streaming right hand anchor: tracked=\(anchor.isTracked)")
                    }
                }
            }
        }
    }
    
    public func stop() {
        updateTask?.cancel()
        updateTask = nil
        session.stop()
        isTracking = false
        logger.info("Hand Tracking Stopped")
    }
}
