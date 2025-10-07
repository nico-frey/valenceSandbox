import SwiftUI
import RealityKit
import RealityKitContent
import simd

// Coordinator to own subscriptions and avoid capturing the SwiftUI View in escaping closures.
final class AtomSandboxController {
    var updateSubscription: EventSubscription?

    func ensureSubscription(content: RealityViewContent, group: Entity, hydrogen: Entity, oxygen: Entity) {
        guard updateSubscription == nil else { return }
        updateSubscription = content.subscribe(to: SceneEvents.Update.self) { [weak group, weak hydrogen, weak oxygen] event in
            guard let group = group, let h = hydrogen, let o = oxygen else { return }

            // Positions in the group's local space
            let hPos = h.position(relativeTo: group)
            let oPos = o.position(relativeTo: group)
            var delta = oPos - hPos
            let dist = length(delta)

            // Only attract when oxygen enters the "mantle" around hydrogen
            let mantleRadius: Float = 0.35 // meters
            if dist > 0.001, dist < mantleRadius {
                // Normalize and move hydrogen a small step toward oxygen
                delta /= dist
                let dt = Float(event.deltaTime)
                let strengthAtEdge: Float = 0.6  // m/s at zero distance factor
                let falloff = (1.0 - dist / mantleRadius) // stronger as it gets closer
                let step = delta * strengthAtEdge * falloff * dt
                h.position = hPos + step
            }
        }
    }
}

/// Minimal, production-clean setup:
/// - Loads two atoms ("hydrogen", "oxygen") from the RealityKitContent bundle
/// - Each atom is centered in a lightweight container
/// - Container is targetable, has a single collision shape (so hits land on the container)
/// - Uses GestureComponent (translation only) for direct, snappy dragging
/// - Group is world-anchored so transforms persist; no snap-back
struct InduceVolumeView: View {
    @State private var groupEntity: Entity?
    @State private var hydrogenEntity: Entity?
    @State private var oxygenEntity: Entity?
    @State private var controller = AtomSandboxController()

    var body: some View {
        RealityView { content in
            // Optional non-interactive backdrop (no collision generated)
            let backdrop = ModelEntity(
                mesh: .generatePlane(width: 2.0, depth: 1.4),
                materials: [SimpleMaterial(color: .init(white: 0.92, alpha: 1.0), isMetallic: false)]
            )
            backdrop.name = "Backdrop"
            backdrop.position = [0, -0.35, -0.35]
            backdrop.transform.rotation = simd_quatf(angle: -.pi / 2.8, axis: [1, 0, 0])
            content.add(backdrop)

            // Attach the per-frame attraction once, when all entities exist.
            if let group = groupEntity, let h = hydrogenEntity, let o = oxygenEntity {
                controller.ensureSubscription(content: content, group: group, hydrogen: h, oxygen: o)
            }
        } update: { content in
            if let entity = groupEntity, entity.parent == nil {
                content.add(entity)
            }
        }
        .task { await loadAndPrepareModels() }
    }

    // MARK: - Loading

    @MainActor
    private func loadAndPrepareModels() async {
        do {
            // Load by root names from rkassets
            let hydrogenRaw = try await Entity(named: "hydrogen", in: realityKitContentBundle)
            let oxygenRaw   = try await Entity(named: "oxygen",   in: realityKitContentBundle)

            // Center + make manipulable (one collision & input target on the container)
            let hydrogen = centeredManipulableContainer(for: hydrogenRaw, scale: 0.12)
            let oxygen   = centeredManipulableContainer(for: oxygenRaw,   scale: 0.12)
            hydrogen.name = "hydrogenContainer"
            oxygen.name   = "oxygenContainer"
            self.hydrogenEntity = hydrogen
            self.oxygenEntity   = oxygen

            // Position side-by-side under a world-anchored group
            let group = Entity()
            group.name = "AtomsGroup"

            let spacing: Float = 0.35
            hydrogen.position = [-spacing, 0, 0]
            oxygen.position   = [ spacing, 0, 0]

            group.addChild(hydrogen)
            group.addChild(oxygen)

            group.position = [0, 0, -0.18]
            group.components.set(AnchoringComponent(.world(transform: matrix_identity_float4x4)))

            groupEntity = group
        } catch {
            // Visible fallback if assets fail to load
            let fallback = ModelEntity(mesh: .generateBox(size: 0.1),
                                       materials: [SimpleMaterial(color: .red, isMetallic: false)])
            fallback.position = [0, 0, -0.25]

            let group = Entity()
            group.addChild(fallback)
            group.components.set(AnchoringComponent(.world(transform: matrix_identity_float4x4)))
            groupEntity = group
        }
    }

    // MARK: - Helpers

    /// Wraps a model in a container centered at origin, adds targetable collision on the container,
    /// and enables Apple's latest ManipulationComponent for natural dragging.
    private func centeredManipulableContainer(for model: Entity, scale: Float) -> Entity {
        let container = Entity()

        // 1) Center model in container & scale
        let originalBounds = model.visualBounds(relativeTo: nil)
        let center = originalBounds.center
        model.position = [-center.x, -center.y, -center.z]
        model.scale = .init(repeating: scale)
        container.addChild(model)

        // 2) Single collision shape on the container so hit-testing selects the container.
        //    Use the model's (now scaled) visual bounds to size a simple box collider.
        let scaledBounds = model.visualBounds(relativeTo: container)
        let extents = scaledBounds.extents
        let clampedExtents = simd.max(extents, SIMD3<Float>(repeating: 0.01)) // avoid degenerate shapes
        let shape = ShapeResource.generateBox(size: clampedExtents * 1.1)     // slightly generous
        container.components.set(CollisionComponent(shapes: [shape]))

        // 3) Input target so the system can direct manipulation to this container.
        var input = InputTargetComponent()
        input.allowedInputTypes = [.direct, .indirect]
        container.components.set(input)

        // 4) Modern manipulation: grab to move/rotate/scale. Keep on release.
        var gesture = GestureComponent()
        gesture.canTranslate = true
        gesture.canRotate = false
        gesture.canScale = false
        container.components.set(gesture)

        return container
    }
}

#Preview {
    InduceVolumeView()
}
