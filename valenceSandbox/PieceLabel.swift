//
//  PieceLabel.swift
//  valenceSandbox
//
//  Created by Nico Frey on 08.10.2025.
//

import SwiftUI

struct PieceLabel: View {
    let title: String
    let taxonomy: String
    let description: String
    
    var body: some View {
        VStack {
            Text(title)
            Text(taxonomy)
            Text(description)
        }
        .glassBackgroundEffect()
    }
}

#Preview {
    PieceLabel(title: "askdf", taxonomy: "asdf", description: "ADSFA")
}
