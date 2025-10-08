//
//  valenceSandboxApp.swift
//  valenceSandbox
//
//  Created by Nico Frey on 01.10.2025.
//

import SwiftUI
import RealityKit
import RealityKitContent

@main
struct valenceSandboxApp: App {
    
    init() {
        AtomComponent.registerComponent()
    }
    
    var body: some SwiftUI.Scene {
        ImmersiveSpace {
            PlaygroundView()
        }
    }
}
