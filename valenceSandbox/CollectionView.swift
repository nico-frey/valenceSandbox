import SwiftUI

struct Molecule: Identifiable {
    let id = UUID()
    let name: String
    let formula: String
    let image: Image
    let isUnlocked: Bool
}

struct CollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var molecules: [Molecule]

    // Always show exactly 8 (4×2)
    private var displayed: [Molecule] {
        let missing = max(0, 8 - molecules.count)
        let filler = (0..<missing).map { _ in
            Molecule(name: "???", formula: "???", image: Image(systemName: "circle.fill"), isUnlocked: false)
        }
        return Array(molecules.prefix(8)) + filler
    }

    var body: some View {
        let windowShape = RoundedRectangle(cornerRadius: 24, style: .continuous)

        ZStack {
            windowShape
                .fill(.ultraThinMaterial)
                .overlay(windowShape.stroke(.white.opacity(0.12), lineWidth: 0.5))

            // CONTENT: centered, padded, no spacers biasing layout
            VStack(spacing: 24) {
                // 1) Header
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Collection")
                            .font(.system(size: 48, weight: .semibold))
                        Text("\(displayed.filter { $0.isUnlocked }.count) / 8")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 48, height: 48)
                            .glassBackgroundEffect()
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                }

                // 2) Grid (4 columns × 2 rows)
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4),
                    spacing: 16
                ) {
                    ForEach(displayed) { mol in
                        MoleculeCard(molecule: mol)
                    }
                }
            }
            .padding(24) // equal padding like a CSS container
        }
        .frame(width: 1200, height: 1000) // tweak as you like
        .glassBackgroundEffect(in: windowShape)
    }
}

struct MoleculeCard: View {
    let molecule: Molecule
    @State private var hovering = false

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        VStack(spacing: 12) {
            ZStack {
                if molecule.isUnlocked {
                    molecule.image.resizable().scaledToFit().frame(height: 180)
                } else {
                    molecule.image.resizable().scaledToFit().frame(height: 180).opacity(0.08)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                        .opacity(0.6)
                }
            }
            VStack(spacing: 4) {
                Text(molecule.name)
                    .font(.system(size: 22, weight: .semibold))
                    .opacity(molecule.isUnlocked ? 1 : 0.5)
                Text(molecule.formula)
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                    .opacity(molecule.isUnlocked ? 1 : 0.3)
            }
        }
        .padding(20)
        .frame(height: 280)
        .frame(maxWidth: .infinity)
        .background(cardShape.fill(.regularMaterial))
        .overlay(cardShape.stroke(hovering && molecule.isUnlocked ? .white.opacity(0.35) : .white.opacity(0.12), lineWidth: 1))
        .onHover { isOn in
            withAnimation(.easeInOut(duration: 0.15)) {
                hovering = isOn && molecule.isUnlocked
            }
        }
        .hoverEffect(molecule.isUnlocked ? .highlight : .automatic)
    }
}
