import RealityKit

// Ensure you register this component in your app’s delegate using:
// AtomComponent.registerComponent()
public struct AtomComponent: Component, Codable {
    // This is an example of adding a variable to the component.
    public var type: AtomType = .oxygen
    public var placed: Bool = false

    public init() {
    }
}

public enum AtomType: String, Codable {
    case hydrogen
    case beryllium
    case carbon
    case nitrogen
    case oxygen
    case flourine
    
    public var title: String {
        switch self {
        case .hydrogen:
            return "Hydrogen"
        case .beryllium:
            return "Beryllium"
        case .carbon:
            return "Carbon"
        case .nitrogen:
            return "Nitrogen"
        case .oxygen:
            return "Oxygen"
        case .flourine:
            return "Flourine"
        }
    }
    
    public var description: String {
        switch self {
        case .hydrogen:
            return "Hydrogen is the lightest and most abundant element in the universe."
        case .beryllium:
            return "Beryllium is a lightweight, strong alkaline earth metal."
        case .carbon:
            return "Carbon is a versatile nonmetal essential to all known life."
        case .nitrogen:
            return "Nitrogen makes up about 78% of Earth's atmosphere."
        case .oxygen:
            return "Oxygen is essential for respiration in most living organisms."
        case .flourine:
            return "Flourine is a highly reactive halogen and the most electronegative element."
        }
    }

    public var symbol: String {
        switch self {
        case .hydrogen:
            return "H"
        case .beryllium:
            return "Be"
        case .carbon:
            return "C"
        case .nitrogen:
            return "N"
        case .oxygen:
            return "O"
        case .flourine:
            return "F"
        }
    }

}
