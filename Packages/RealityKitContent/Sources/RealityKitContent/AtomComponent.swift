import RealityKit

// Ensure you register this component in your app’s delegate using:
// AtomComponent.registerComponent()
public struct AtomComponent: Component, Codable {
    // This is an example of adding a variable to the component.
    public var type: AtomType = .oxygen

    public init() {
    }
}

public enum AtomType: String, Codable {
    case oxygen
    case hydrogen
    case beryllium
    case carbon
    case nitrogen
    
    public var title: String {
        switch self {
        case .oxygen:
            return "Oxygen"
        case .hydrogen:
            return "Hydrogen"
        case .beryllium:
            return "Beryllium"
        case .carbon:
            return "Carbon"
        case .nitrogen:
            return "Nitrogen"
        }
    }
    
    public var description: String {
        switch self {
        case .oxygen:
            return "Oxygen"
        case .hydrogen:
            return "Hydrogen"
        case .beryllium:
            return "Beryllium"
        case .carbon:
            return "Carbon"
        case .nitrogen:
            return "Nitrogen"
        }
    }

    public var taxonomy: String {
        switch self {
        case .oxygen:
            return "Oxygen"
        case .hydrogen:
            return "Hydrogen"
        case .beryllium:
            return "Beryllium"
        case .carbon:
            return "Carbon"
        case .nitrogen:
            return "Nitrogen"
        }
    }

}
