import SwiftUI
import RealityKit

// MARK: - Atom Data Model
struct Atom: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let color: Color
}

// MARK: - Draggable Atom Entity
struct DraggableAtom: Identifiable {
    let id = UUID()
    let atom: Atom
    var position: SIMD3<Float>
    var opacity: Float
}

// MARK: - Main Toolbar View
struct Toolbar: View {
    // Available atoms in the toolbar
    private let atoms: [Atom] = [
        Atom(name: "Hydrogen", symbol: "H", color: .white),
        Atom(name: "Beryllium", symbol: "Li", color: .cyan),
        Atom(name: "Carbon", symbol: "C", color: .gray),
        Atom(name: "Nitrogen", symbol: "Ca", color: .blue),
        Atom(name: "Oxygen", symbol: "O", color: .red),
        Atom(name: "Fluorine", symbol: "Fl", color: .green)
    ]
    
    @State private var draggedAtoms: [DraggableAtom] = []
    @State private var currentDragAtom: Atom?
    @State private var dragLocation: CGPoint = .zero
    @State private var isDragging: Bool = false
    @State private var atomEntities: [Entity] = []
    
    var body: some View {
        ZStack {
            RealityView { content in
                // Initial setup for RealityKit content
            } update: { content in
                updateDraggedAtoms(in: content)
            }
            .allowsHitTesting(false)
            
            // The main toolbar UI (stays in place)
            toolbarUI
        }
    }
    
    // MARK: - Toolbar UI
    private var toolbarUI: some View {
        HStack(spacing: 4) {
            ForEach(atoms) { atom in
                AtomButton(atom: atom, onDragStart: { atom, location in
                    startDragging(atom: atom, at: location)
                }, onDragChange: { location in
                    updateDrag(at: location)
                }, onDragEnd: {
                    endDragging()
                })
            }
        }
        .padding(4)
        .background {
            // Apple VisionOS toolbar background
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.regularMaterial)
        }
        .overlay {
            // Apple's subtle border
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
        }
    }
    
    // MARK: - Drag Handling
    private func startDragging(atom: Atom, at location: CGPoint) {
        guard !isDragging else { return }
        currentDragAtom = atom
        dragLocation = location
        isDragging = true
        
        // Create a new draggable atom instance at starting position
        let newAtom = DraggableAtom(
            atom: atom,
            position: SIMD3<Float>(0, 0, 0),
            opacity: 0.0
        )
        draggedAtoms.append(newAtom)
    }
    
    private func updateDrag(at location: CGPoint) {
        guard currentDragAtom != nil,
              var lastAtom = draggedAtoms.last else { return }
        
        dragLocation = location
        
        // Fade in the 3D model as user drags
        lastAtom.opacity = min(1.0, lastAtom.opacity + 0.1)
        
        // Update position based on drag (convert 2D to 3D space)
        // This is a simplified conversion - adjust based on your coordinate system
        lastAtom.position = SIMD3<Float>(
            Float(location.x) / 500.0,
            Float(location.y) / 500.0,
            -0.5
        )
        
        draggedAtoms[draggedAtoms.count - 1] = lastAtom
    }
    
    private func endDragging() {
        currentDragAtom = nil
        isDragging = false
        
        // Finalize the dragged atom
        if var lastAtom = draggedAtoms.last {
            lastAtom.opacity = 1.0
            draggedAtoms[draggedAtoms.count - 1] = lastAtom
        }
    }
    
    // MARK: - RealityKit Update
    private func updateDraggedAtoms(in content: RealityViewContent) {
        // Remove previously spawned entities from the content
        for entity in atomEntities {
            content.remove(entity)
        }
        atomEntities.removeAll()

        // Add entities for current dragged atoms
        for draggedAtom in draggedAtoms {
            let entity = createAtomEntity(for: draggedAtom)
            content.add(entity)
            atomEntities.append(entity)
        }
    }
    
    private func createAtomEntity(for draggedAtom: DraggableAtom) -> ModelEntity {
        // Create a simple sphere mesh for now
        let sphere = MeshResource.generateSphere(radius: 0.05)
        
        // Create material with atom's color
        // The opacity is controlled entirely through the alpha channel of the color
        var material = UnlitMaterial()
        material.color = .init(
            tint: UIColor(draggedAtom.atom.color).withAlphaComponent(CGFloat(draggedAtom.opacity))
        )
        // Enable transparent blending so the alpha channel is respected
        material.blending = .transparent(opacity: 1.0)
        
        let entity = ModelEntity(mesh: sphere, materials: [material])
        entity.position = draggedAtom.position
        
        return entity
    }
}

// MARK: - Atom Button Component
struct AtomButton: View {
    let atom: Atom
    let onDragStart: (Atom, CGPoint) -> Void
    let onDragChange: (CGPoint) -> Void
    let onDragEnd: () -> Void
    
    @State private var currentDragStart: CGPoint? = nil
    @State private var isHovering: Bool = false
    
    var body: some View {
        let pillShape = RoundedRectangle(cornerRadius: 999, style: .continuous)

        HStack(spacing: 8) {
            // Atom icon/image (24x24)
            Circle()
                .fill(atom.color.opacity(0.3))
                .frame(width: 24, height: 24)
                .overlay {
                    Circle()
                        .strokeBorder(atom.color.opacity(0.6), lineWidth: 1)
                }
            
            // Atom name
            Text(atom.name)
                .font(.system(size: 16))
                .foregroundStyle(.primary)
            
            // Atom symbol (shorthand)
            Text(atom.symbol)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 10)
        .padding(.trailing, 14)
        .padding(.vertical, 6)
        .frame(height: 40)
        .background {
            // Apple's hover state - clean material background
            if isHovering {
                pillShape
                    .fill(.regularMaterial)
            }
        }
        .overlay {
            // Apple's hover border - simple and clean
            if isHovering {
                pillShape
                    .strokeBorder(.white.opacity(0.3), lineWidth: 1)
            }
        }
        .contentShape(pillShape)
        .hoverEffect(.highlight)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if currentDragStart == nil {
                        onDragStart(atom, value.location)
                        currentDragStart = value.startLocation
                    }
                    onDragChange(value.location)
                }
                .onEnded { _ in
                    currentDragStart = nil
                    onDragEnd()
                }
        )
    }
}

// MARK: - Preview for Testing
#Preview(windowStyle: .volumetric) {
    ZStack {
        Color.clear
        VStack {
            Spacer()
            Toolbar()
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
    }
}
