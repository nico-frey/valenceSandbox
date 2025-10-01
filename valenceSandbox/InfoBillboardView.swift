import SwiftUI

// MARK: - Model

struct AtomInfo: Identifiable, Equatable {
    let id = UUID()
    let name: String          // e.g. "Oxygen"
    let symbol: String        // e.g. "O"
    let subscriptText: String // e.g. "₆"  (use Unicode subscripts like "₁₂₃₄₅₆₇₈₉₀")
    let description: String   // short descriptive blurb
    let image: Image          // thumbnail or render of your atom
}

// MARK: - View

struct InfoBillboardView: View {
    let atom: AtomInfo

    private let buttonSize: CGFloat = 48
    private let hoverDelay: TimeInterval = 0.2
    @State private var isExpanded: Bool = false
    private let cornerRadius: CGFloat = 40

    var body: some View {
        // We render at full expanded size but reveal via a hover-driven clip mask (like your DetailView)
        ZStack(alignment: .topLeading) {
            // Collapsed icon (fades out on hover)
            Image(systemName: "info")
                .font(.system(size: 22, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .padding(13) // visually centers within 48×48
                .frame(width: buttonSize, height: buttonSize, alignment: .center)
                .hoverEffect { content, isActive, _ in
                    content.animation(.easeOut(duration: 0.4), body: { content in
                        content.opacity(isActive ? 0 : 1)
                    })
                }

            // Expanded content (fades in on hover with a slight delay)
            expandedContent
                .padding(24)
                .hoverEffect { content, isActive, _ in
                    content.animation(.smooth.delay(isActive ? hoverDelay : .zero), body: { content in
                        content.opacity(isActive ? 1 : 0)
                    })
                }
        }
        // Give the billboard its full expanded footprint; the hoverEffect below will clip it down to a 48×48 pill until hovered
        .frame(width: 516, height: 406, alignment: .topLeading)
        .glassBackgroundEffect()
        .hoverEffect { content, isActive, proxy in
            // Animate the container’s shape/size similarly to your working DetailView
            content.animation(isActive ? .smooth.delay(isActive ? hoverDelay : .zero) : .easeIn(duration: 0.35), body: { content in
                content
                    .clipShape(
                        .rect(cornerRadius: isActive ? cornerRadius : buttonSize/2)
                            .size(
                                width: isActive ? proxy.size.width : buttonSize,
                                height: isActive ? proxy.size.height : buttonSize,
                                anchor: .topLeading
                            )
                    )
                    .scaleEffect(isActive ? 1.02 : 1)
            })
        }
        .onHover { hovering in
            withAnimation(.smooth) { isExpanded = hovering }
        }
        .hoverEffectGroup()
    }

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header line: Name + Symbol with subscript
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(atom.name)
                    .font(.system(size: 32, weight: .semibold))
                    .fontDesign(.default)
                    .foregroundStyle(.primary)

                HStack(spacing: 2) {
                    Text(atom.symbol)
                        .font(.system(size: 32, weight: .semibold))
                        .fontDesign(.default)
                        .foregroundStyle(.secondary)
                    Text(atom.subscriptText)
                        .font(.system(size: 32, weight: .semibold))
                        .fontDesign(.default)
                        .foregroundStyle(.secondary)
                        .baselineOffset(10) // superscript look
                }

            }

            // Description
            Text(atom.description)
                .font(.system(size: 24, weight: .regular))
                .fontDesign(.default)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .minimumScaleFactor(0.9)

            // Image block
            ZStack {
                atom.image
                    .resizable()
                    .scaledToFit()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

// MARK: - Preview with example atom

struct InfoBillboardView_Previews: PreviewProvider {
    static var previews: some View {
        InfoBillboardView(
            atom: AtomInfo(
                name: "Oxygen",
                symbol: "O",
                subscriptText: "⁶", // Unicode superscript 6
                description: "Vital element, eight protons, supports respiration, fuels combustion, abundant in air.",
                image: Image("sampleAtom") // replace with your asset/render
            )
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
