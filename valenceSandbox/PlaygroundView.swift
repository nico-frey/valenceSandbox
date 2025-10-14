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
    @State private var spawnSub: EventSubscription?     // duplication-on-drag

    // Names of the "toolbar" atoms that should always duplicate on drag.
    // Include both spellings for safety since the RC scene currently uses "flourine".
    private let paletteNames: Set<String> = ["hydrogen", "oxygen", "carbon", "nitrogen", "fluorine", "flourine", "beryllium"]

    // Helper to recursively remove InputTargetComponent from all descendants
    private func removeInputTargetsRecursively(from entity: Entity) {
        for child in entity.children {
            child.components.remove(InputTargetComponent.self)
            if !child.children.isEmpty {
                removeInputTargetsRecursively(from: child)
            }
        }
    }

    // Walk up parents to see if an entity is inside a prefab with this root name.
    private func isDescendant(_ entity: Entity, ofNamed target: String) -> Bool {
        var current: Entity? = entity
        while let e = current {
            if e.name == target { return true }
            current = e.parent
        }
        return false
    }

    // Find the nearest ancestor (including self) that is an atom root (has AtomComponent).
    private func atomRoot(for entity: Entity) -> Entity? {
        var current: Entity? = entity
        while let e = current {
            if e.components[AtomComponent.self] != nil { return e }
            current = e.parent
        }
        return nil
    }

    fileprivate func handleSuccess(_ event: CollisionEvents.Began, compoundName: String, in playgroundEntity: Entity) {
        firstCollision = nil
        firstValidCompound = try? Entity.load(named: compoundName, in: realityKitContentBundle)
        
        if let firstValidCompound {
            // Name the spawned root so collision logic can recognize stages (e.g., "compound_ho", "molecule_h2o").
            firstValidCompound.name = compoundName
            
            // Ensure we drag the whole compound (root), not a nested child.
            if firstValidCompound.components[InputTargetComponent.self] == nil {
                firstValidCompound.components.set(InputTargetComponent())
            }
            if firstValidCompound.components[CollisionComponent.self] == nil {
                firstValidCompound.generateCollisionShapes(recursive: true)
            }
            removeInputTargetsRecursively(from: firstValidCompound)

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
                    uiAnchor.components.set(viewAttachmentComponent)
                }
                
                oxygenEntity = playgroundEntity.findEntity(named: "oxygen")

                // Make atoms draggable (toolbar and spawned ones)
                for child in playgroundEntity.children {
                    if let atomComponent = child.components[AtomComponent.self] {
                        print(atomComponent.type.title)
                        var manipulationComponent = ManipulationComponent()
                        manipulationComponent.releaseBehavior = .stay
                        child.components.set(manipulationComponent)
                    }
                }

                // Duplication-on-drag — only for toolbar atoms, visible, no collision spam
                spawnSub = content.subscribe(to: ManipulationEvents.WillBegin.self) { event in
                    // Only act if this drag began on a toolbar atom (or any of its children)
                    guard let root = atomRoot(for: event.entity),
                          paletteNames.contains(root.name),
                          event.entity.components[AtomComponent.self]?.placed == false, // do not duplicate an already placed entity anymore
                          let replacement = try? Entity.load(named: root.name, in: realityKitContentBundle) else {
                        return
                    }
                    replacement.name = root.name

                    replacement.components.set(InputTargetComponent())
                    if let collisionComponent = event.entity.components[CollisionComponent.self] {
                        replacement.components.set(collisionComponent)
                    }
                    replacement.components.set(event.entity.components[AtomComponent.self] ?? AtomComponent())
                    
                    var manipulationComponent = ManipulationComponent()
                    manipulationComponent.releaseBehavior = .stay
                    replacement.components.set(manipulationComponent)


                    replacement.transform = root.transform
                    root.parent?.addChild(replacement)

                    // After copying the original atom component to the duplicated entity,
                    //mark the initially manipulated atom component's entity as placed to prevent it from duplicating
                    event.entity.components[AtomComponent.self]?.placed = true

                    // Note: the user keeps dragging the original (which just left the toolbar),
                    // and the replacement stays as the next “palette” copy.
                }
                
                // Collisions → compounds/molecules
                firstCollision = content.subscribe(to: CollisionEvents.Began.self, { event in
                    print("1 ", event.entityA.name, event.entityB.name)
                    if isResolving { return }
                                        
                    // Pull out atom types if present (compounds won't have AtomComponent).
                    let aType = event.entityA.components[AtomComponent.self]?.type
                    let bType = event.entityB.components[AtomComponent.self]?.type
                    
                    // HO compound (or any of its children) + H atom → H2O molecule
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
