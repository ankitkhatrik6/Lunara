import SwiftUI

// MARK: - Corner Radii (matching Android)

public struct LunaraCornerRadius {
    public static let small: CGFloat = 4
    public static let medium: CGFloat = 8
    public static let large: CGFloat = 16
    public static let pill: CGFloat = 24
}

// MARK: - Card Style Modifier

public struct LunaraCardStyle: ViewModifier {
    public var padding: CGFloat = 12
    public var cornerRadius: CGFloat = LunaraCornerRadius.medium
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.spotifyCardSurface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

public extension View {
    func lunaraCard(padding: CGFloat = 12, cornerRadius: CGFloat = LunaraCornerRadius.medium) -> some View {
        self.modifier(LunaraCardStyle(padding: padding, cornerRadius: cornerRadius))
    }
}
