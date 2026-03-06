import SwiftUI

struct HansWalkerButton: View {
    let title: String
    let icon: AnyView?
    let action: () -> Void
    let disabled: Bool
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    @State private var isHovered = false
    
    init<Icon: View>(
        _ title: String,
        disabled: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder icon: () -> Icon
    ) {
        self.title = title
        self.icon = AnyView(icon())
        self.disabled = disabled
        self.action = action
    }
    
    init(
        _ title: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = nil
        self.disabled = disabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if !disabled {
                action()
            }
        }) {
            HStack(spacing: 8) {
                icon
                
                Text(title)
                    .font(.kronaOne(size: 13))
                    .tracking(2.6)
                    .textCase(.uppercase)
            }
            .foregroundColor(
                disabled 
                    ? Color.hwTextSecondary(colorScheme).opacity(0.5) 
                    : Color.hwInk
            )
            .padding(.horizontal, 36)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                ZStack {
                    if !disabled {
                        // 3D depth layer (bottom shadow)
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.hwAccentGreenDeeper(colorScheme))
                            .offset(y: isPressed ? 2 : (isHovered ? 9 : 8))
                        
                        // Main button layer
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                isPressed 
                                    ? Color(hex: "4db87a")  // Active: dark green
                                    : (isHovered 
                                        ? Color(hex: "6ed49a")  // Hover: light green
                                        : Color.hwAccentGreen(colorScheme))  // Normal: #5EC48A
                            )
                            .shadow(
                                color: Color.hwAccentGreen(colorScheme).opacity(
                                    isPressed ? 0.2 : (isHovered ? 0.45 : 0.42)
                                ),
                                radius: isPressed ? 8 : (isHovered ? 32 : 28),
                                y: isPressed ? 2 : (isHovered ? 15 : 12)
                            )
                    } else {
                        // Disabled state
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.hwBackgroundDeep(colorScheme))
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(Color.hwSeparator(colorScheme), lineWidth: 1)
                            )
                    }
                }
            )
            // Text se pohybuje společně s celým tlačítkem
            .offset(y: isPressed ? 5 : (isHovered ? -3 : 0))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(disabled)
        .onHover { hovering in
            if !disabled {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !disabled && !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    if !disabled {
                        isPressed = false
                    }
                }
        )
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .animation(.easeInOut(duration: 0.1), value: isHovered)
    }
}

// MARK: - Secondary Button Style (Ghost button - like "Buy me a coffee" on web)

struct SecondaryHansWalkerButton: View {
    let title: String
    let icon: AnyView?
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false
    
    init<Icon: View>(
        _ title: String,
        action: @escaping () -> Void,
        @ViewBuilder icon: () -> Icon
    ) {
        self.title = title
        self.action = action
        self.icon = AnyView(icon())
    }
    
    init(
        _ title: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.icon = nil
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                icon
                
                Text(title)
                    .font(.kronaOne(size: 11))
                    .tracking(2.2)
                    .textCase(.uppercase)
            }
            .foregroundColor(
                isHovered 
                    ? Color.hwAccentGreenAccessible(colorScheme)
                    : Color.hwTextSecondary(colorScheme)
            )
            .padding(.horizontal, 36)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 56)  // Stejná výška jako primary button
            .background(Color.clear)
            .cornerRadius(100)
            .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .stroke(
                        isHovered 
                            ? Color.hwAccentGreenAccessible(colorScheme)
                            : Color.hwSeparator(colorScheme),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: isHovered 
                    ? Color.hwAccentGreenAccessible(colorScheme).opacity(0.15)
                    : Color.clear,
                radius: 16,
                y: 4
            )
            // Text se pohybuje společně s celým tlačítkem
            .offset(y: isHovered ? -2 : 0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}

#Preview("Default State") {
    VStack(spacing: 20) {
        HansWalkerButton("Start Batch", action: {
            print("Clicked")
        })
        
        HansWalkerButton("Start Batch", disabled: true) {
            print("Clicked")
        }
        
        SecondaryHansWalkerButton("Open Folder", action: {
            print("Clicked")
        }) {
            Image(systemName: "folder")
                .font(.system(size: 13))
        }
    }
    .padding(40)
    .frame(width: 540)
    .background(Color.hwCream)
}

#Preview("Dark Mode") {
    VStack(spacing: 20) {
        HansWalkerButton("Start Batch", action: {
            print("Clicked")
        })
        
        HansWalkerButton("Start Batch", disabled: true) {
            print("Clicked")
        }
        
        SecondaryHansWalkerButton("Open Folder", action: {
            print("Clicked")
        }) {
            Image(systemName: "folder")
                .font(.system(size: 13))
        }
    }
    .padding(40)
    .frame(width: 540)
    .background(Color.hwDarkBg)
    .preferredColorScheme(.dark)
}
