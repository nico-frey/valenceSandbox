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

    fileprivate func handleSuccess(_ event: CollisionEvents.Began, in playgroundEntity: Entity) {
        firstCollision = nil
        firstValidCompound = try? Entity.load(named: "compound_ho", in: realityKitContentBundle)
        
        if let firstValidCompound, let oxygenEntity {
            playgroundEntity.addChild(firstValidCompound)
            firstValidCompound.setPosition(oxygenEntity.position, relativeTo: nil)
            
            var manipulationComponent = ManipulationComponent()
            manipulationComponent.releaseBehavior = .stay
            firstValidCompound.components.set(manipulationComponent)
        }
        
        Entity.animate(.smooth) {
            event.entityA.transform.scale = .zero
            event.entityA.components[OpacityComponent.self]?.opacity = 0
            event.entityB.transform.scale = .zero
            event.entityB.components[OpacityComponent.self]?.opacity = 0
        } completion: {
            event.entityA.removeFromParent()
            event.entityB.removeFromParent()
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
                
                oxygenEntity = playgroundEntity.findEntity(named: "hydrogen")

                for child in playgroundEntity.children {
                    if let atomComponent = child.components[AtomComponent.self] {

                        print(atomComponent.type.title)
                        var manipulationComponent = ManipulationComponent()
                        manipulationComponent.releaseBehavior = .stay
                        child.components.set(manipulationComponent)
                        
//                        let gestureComponent = GestureComponent(TapGesture().onEnded({ event in
//                            print("Tapped")
//                        }))
//                        child.components.set(gestureComponent)
                        
                        
//                        let entity = Entity()
//                        let attachment = ViewAttachmentComponent(rootView: PieceLabel(title: atomComponent.type.title, taxonomy: atomComponent.type.taxonomy, description: atomComponent.type.description))
//                        
//                        print(atomComponent.type)
//                        child.components.set(attachment)
//                        
//                        entity.transform = child.transform
//                        entity.transform.translation.y += 0.5
//
//                        child.addChild(entity)
                        
//                        _ = content.subscribe(to: ManipulationEvents.WillBegin.self, on: child, { event in
//                            playgroundEntity.addChild(event.entity.clone(recursive: true))
//                        })
                        

                    }
                }
                
//                playgroundEntity.addChild(firstValidCompound)

                firstCollision = content.subscribe(to: CollisionEvents.Began.self, { event in
                    print("1 ", event.entityA.name, event.entityB.name)
                                        
                    if let atomComponentA = event.entityA.components[AtomComponent.self],
                        let atomComponentB = event.entityB.components[AtomComponent.self] {
                        
                        if atomComponentA.type == .oxygen && atomComponentB.type == .hydrogen {
                            handleSuccess(event, in: playgroundEntity)
                        } else if atomComponentA.type == .beryllium && atomComponentB.type == .carbon {
                            print("make final molecule from compound and atom")
                        } else {
                            print("incompatible, shake or move entity a away")
                            
                            // TODO: Handle more combination cases
                        }
                    }
                    
                })

//                _ = content.subscribe(to: CollisionEvents.Began.self, on: firstValidCompound, { event in
//                    print(firstValidCompound?.name)
//                    print("2 ", event.entityA.name, event.entityB.name)
//                })
                
                content.add(playgroundEntity)
            }
        }
    }
}

#Preview(immersionStyle: .mixed) {
    PlaygroundView()
}
