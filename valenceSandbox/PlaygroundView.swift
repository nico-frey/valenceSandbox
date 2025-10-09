//
//  PlaygroundView.swift
//  valenceSandbox
//
//  Created by Nico Frey on 08.10.2025.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct PlaygroundView: View {
    @State private var firstCollision: EventSubscription?
    @State private var firstValidCompound: Entity?
    @State private var oxygenEntity: Entity?
    @State private var isResolving: Bool = false

    // Helper to recursively remove InputTargetComponent from all descendants
    private func removeInputTargetsRecursively(from entity: Entity) {
        for child in entity.children {
            child.components.remove(InputTargetComponent.self)
            if !child.children.isEmpty {
                removeInputTargetsRecursively(from: child)
            }
        }
    }

    // NEW: Walk up parents to see if an entity is inside a prefab with this root name.
    private func isDescendant(_ entity: Entity, ofNamed target: String) -> Bool {
        var current: Entity? = entity
        while let e = current {
            if e.name == target { return true }
            current = e.parent
        }
        return false
    }

    fileprivate func handleSuccess(_ event: CollisionEvents.Began, compoundName: String, in playgroundEntity: Entity) {
        // Load the requested compound prefab and place it between the two colliding atoms.
        firstCollision = nil
        firstValidCompound = try? Entity.load(named: compoundName, in: realityKitContentBundle)
        
        if let firstValidCompound {
            // Name the spawned root so collision logic can recognize stages (e.g., "compound_ho", "molecule_h2o").
            firstValidCompound.name = compoundName
            
            // Ensure we drag the whole compound (root), not a nested child.
            if firstValidCompound.components[InputTargetComponent.self] == nil {
                firstValidCompound.components.set(InputTargetComponent())
            }
            // Make sure it can be hit-tested for gestures.
            if firstValidCompound.components[CollisionComponent.self] == nil {
                firstValidCompound.generateCollisionShapes(recursive: true)
            }
            // Remove InputTarget from all descendants to avoid dragging a subpart.
            removeInputTargetsRecursively(from: firstValidCompound)
            // Install manipulation on the root so the whole thing moves.
            var manipulationComponent = ManipulationComponent()
            manipulationComponent.releaseBehavior = .stay
            firstValidCompound.components.set(manipulationComponent)
            
            // Place at the midpoint of the two colliders and add to scene.
            let posA = event.entityA.position(relativeTo: nil)
            let posB = event.entityB.position(relativeTo: nil)
            let mid  = (posA + posB) * 0.5
            firstValidCompound.setPosition(mid, relativeTo: nil)
            playgroundEntity.addChild(firstValidCompound)
        }
        
        Entity.animate(.smooth) {
            event.entityA.transform.scale = .zero
            event.entityA.components[OpacityComponent.self]?.opacity = 0
            event.entityB.transform.scale = .zero
            event.entityB.components[OpacityComponent.self]?.opacity = 0
        } completion: {
            event.entityA.removeFromParent()
            event.entityB.removeFromParent()
            self.isResolving = false
        }
    }
    
    var body: some View {
        RealityView { content in
            if let playgroundEntity = try? await Entity(named: "Playground", in: realityKitContentBundle) {
                let viewAttachmentComponent = ViewAttachmentComponent(rootView: ToolbarView())
                if let uiAnchor = playgroundEntity.findEntity(named: "ui_anchor") {
                    print(uiAnchor)
                    uiAnchor.components.set(viewAttachmentComponent)
                }
                
                oxygenEntity = playgroundEntity.findEntity(named: "oxygen")

                for child in playgroundEntity.children {
                    if let atomComponent = child.components[AtomComponent.self] {
                        print(atomComponent.type.title)
                        var manipulationComponent = ManipulationComponent()
                        manipulationComponent.releaseBehavior = .stay
                        child.components.set(manipulationComponent)
                    }
                }
                
                firstCollision = content.subscribe(to: CollisionEvents.Began.self, { event in
                    print("1 ", event.entityA.name, event.entityB.name)
                    if isResolving { return }
                                        
                    // Pull out atom types if present (compounds won't have AtomComponent).
                    let aType = event.entityA.components[AtomComponent.self]?.type
                    let bType = event.entityB.components[AtomComponent.self]?.type
                    
                    // ✅ HO compound (or any of its children) + H atom → H2O molecule
                    if (isDescendant(event.entityA, ofNamed: "compound_ho") && bType == .hydrogen) ||
                       (isDescendant(event.entityB, ofNamed: "compound_ho") && aType == .hydrogen) {
                        isResolving = true
                        handleSuccess(event, compoundName: "molecule_h2o", in: playgroundEntity)
                        
                    // Atom–atom rules (both must be atoms)
                    } else if let a = aType, let b = bType {
                        // O + H → HO (order-insensitive)
                        if (a == .oxygen && b == .hydrogen) || (a == .hydrogen && b == .oxygen) {
                            isResolving = true
                            handleSuccess(event, compoundName: "compound_ho", in: playgroundEntity)
                            
                        // C + O → CO (order-insensitive)
                        } else if (a == .carbon && b == .oxygen) || (a == .oxygen && b == .carbon) {
                            isResolving = true
                            handleSuccess(event, compoundName: "compound_co", in: playgroundEntity)
                            
                        } else if a == .beryllium && b == .carbon {
                            print("make final molecule from compound and atom")
                        } else {
                            print("incompatible, shake or move entity a away")
                            // TODO: Handle more combination cases
                        }
                    }
                })
                
                content.add(playgroundEntity)
            }
        }
    }
}

#Preview(immersionStyle: .mixed) {
    PlaygroundView()
}
