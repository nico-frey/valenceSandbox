import SwiftUI
import RealityKit
import RealityKitContent

struct Atom: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let color: Color
}

struct Toolbar: View {
    private let atoms: [Atom] = [
        Atom(name: "Hydrogen",  symbol: "H",  color: .white),
        Atom(name: "Beryllium", symbol: "Be", color: .cyan),
        Atom(name: "Carbon",    symbol: "C",  color: .gray),
        Atom(name: "Nitrogen",  symbol: "N",  color: .blue),
        Atom(name: "Oxygen",    symbol: "O",  color: .red),
        Atom(name: "Fluorine",  symbol: "F",  color: .green)
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(atoms) { atom in
                AtomPill(atom: atom)
            }
        }
        .padding(4)              // space between red background and pills
        .background(.ultraThickMaterial)
        .clipShape(Capsule())
        .padding(4)              // space between blue and red
        .background(.regularMaterial)
        .clipShape(Capsule())
        .frame(height: 50)
        .glassBackgroundEffect()

    }
       
}

struct AtomPill: View {
    let atom: Atom
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(atom.color)
                .frame(width: 20, height: 20)

            Text(atom.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            Text(atom.symbol)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isHovering ? .regularMaterial : .regularMaterial)
        .clipShape(Capsule())
        .contentShape(Capsule())
        .onHover { hovering in
            // keep it snappy; tune if you like
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
        .hoverEffect(.highlight)
    }
}

#Preview {
    VStack {
        Spacer()
        Toolbar()
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
    }
}
