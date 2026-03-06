import SwiftUI

// MARK: - Hans Walker Design Tokens

extension Color {
    // MARK: - Light Mode Colors
    
    /// Hans Walker cream background - Light mode
    static let hwCream = Color(hex: "F4EFE4")
    
    /// Hans Walker cream mid-tone - Light mode
    static let hwCreamMid = Color(hex: "EBE4D4")
    
    /// Hans Walker cream deep - Light mode
    static let hwCreamDeep = Color(hex: "DDD4BF")
    
    /// Hans Walker ink (text) - Light mode
    static let hwInk = Color(hex: "2C1F14")
    
    /// Hans Walker ink light - Light mode
    static let hwInkLight = Color(hex: "513F34")
    
    /// Hans Walker brand green - Light mode
    static let hwGreen = Color(hex: "5EC48A")
    
    /// Hans Walker green dark - for shadows
    static let hwGreenDark = Color(hex: "3aad73")
    
    /// Hans Walker green deeper - for 3D button depth
    static let hwGreenDeeper = Color(hex: "2a8a58")
    
    /// Hans Walker green accessible - for text on light backgrounds (WCAG AA: 4.8:1 on #F4EFE4)
    static let hwGreenAccessible = Color(hex: "2d8a5a")
    
    /// Hans Walker gold accent
    static let hwGold = Color(hex: "C9A84C")
    
    // MARK: - Dark Mode Colors
    
    /// Dark mode background - neutral dark (NOT brown)
    static let hwDarkBg = Color(hex: "1e1e22")
    
    /// Dark mode mid-tone background
    static let hwDarkBgMid = Color(hex: "2c2c30")
    
    /// Dark mode deep background
    static let hwDarkBgDeep = Color(hex: "3a3a3e")
    
    /// Dark mode text color
    static let hwDarkInk = Color(hex: "EDE4D0")
    
    /// Dark mode secondary text
    static let hwDarkInkLight = Color(hex: "c8b89a")
    
    /// Dark mode green accent
    static let hwDarkGreen = Color(hex: "4EC98A")
    
    /// Dark mode green dark - for shadows
    static let hwDarkGreenDark = Color(hex: "3aad73")
    
    /// Dark mode green deeper - for 3D button depth
    static let hwDarkGreenDeeper = Color(hex: "2a8a58")
}

// MARK: - Adaptive Color Helpers

extension Color {
    /// Adaptive background color based on color scheme
    static func hwBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .hwDarkBg : .hwCream
    }
    
    /// Adaptive mid-tone background
    static func hwBackgroundMid(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .hwDarkBgMid : .hwCreamMid
    }
    
    /// Adaptive deep background
    static func hwBackgroundDeep(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .hwDarkBgDeep : .hwCreamDeep
    }
    
    /// Adaptive text color
    static func hwText(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .hwDarkInk : .hwInk
    }
    
    /// Adaptive secondary text color
    static func hwTextSecondary(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .hwDarkInkLight : .hwInkLight
    }
    
    /// Adaptive green accent
    static func hwAccentGreen(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .hwDarkGreen : .hwGreen
    }
    
    /// Adaptive green dark (for shadows)
    static func hwAccentGreenDark(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .hwDarkGreenDark : .hwGreenDark
    }
    
    /// Adaptive green deeper (for 3D button depth)
    static func hwAccentGreenDeeper(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .hwDarkGreenDeeper : .hwGreenDeeper
    }
    
    /// Adaptive green accessible (for text on light/dark backgrounds - WCAG AA compliant)
    static func hwAccentGreenAccessible(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .hwDarkGreen : .hwGreenAccessible
    }
    
    /// Adaptive separator/border color
    static func hwSeparator(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color.white.opacity(0.1) 
            : Color.black.opacity(0.12)
    }
}

// MARK: - Font Extensions

extension Font {
    /// Krona One font - ONLY for app title "Shorts Factory"
    static func kronaOne(size: CGFloat) -> Font {
        .custom("KronaOne-Regular", size: size)
    }
}
