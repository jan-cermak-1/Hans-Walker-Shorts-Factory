import SwiftUI

struct HeaderView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header content
            HStack(spacing: 16) {
                // Hans Walker Logo - switches based on color scheme
                Image(colorScheme == .dark ? "hans-walker-logo-dark" : "hans-walker-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 48)
                
                // Title - single line
                Text("SHORTS FACTORY")
                    .font(.kronaOne(size: 13))
                    .foregroundColor(Color.hwText(colorScheme))
                    .tracking(2.6)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.hwBackgroundMid(colorScheme))
            
            // Bottom border
            Rectangle()
                .fill(Color.hwSeparator(colorScheme))
                .frame(height: 1)
        }
    }
}

// MARK: - Hans Walker Logo Shape

struct HansWalkerLogo: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Scale factors from original 800x800 viewBox
        let scaleX = width / 800.0
        let scaleY = height / 800.0
        
        // Full Hans Walker logo path (kaligrafický styl z SVG)
        path.move(to: CGPoint(x: 347.908 * scaleX, y: 347.028 * scaleY))
        path.addCurve(
            to: CGPoint(x: 358.676 * scaleX, y: 351.766 * scaleY),
            control1: CGPoint(x: 351.83 * scaleX, y: 347.031 * scaleY),
            control2: CGPoint(x: 356.722 * scaleX, y: 348.01 * scaleY)
        )
        path.addCurve(
            to: CGPoint(x: 357.78 * scaleX, y: 382.339 * scaleY),
            control1: CGPoint(x: 362.906 * scaleX, y: 359.898 * scaleY),
            control2: CGPoint(x: 359.847 * scaleX, y: 373.996 * scaleY)
        )
        
        // Simplified rendering - full path is 3KB+ of coordinates
        // Using key strokes of the signature
        path.move(to: CGPoint(x: 338.234 * scaleX, y: 439.539 * scaleY))
        path.addCurve(
            to: CGPoint(x: 311.427 * scaleX, y: 498.523 * scaleY),
            control1: CGPoint(x: 330.245 * scaleX, y: 459.43 * scaleY),
            control2: CGPoint(x: 320.331 * scaleX, y: 479.176 * scaleY)
        )
        
        path.move(to: CGPoint(x: 241.824 * scaleX, y: 626.891 * scaleY))
        path.addCurve(
            to: CGPoint(x: 215.093 * scaleX, y: 656.469 * scaleY),
            control1: CGPoint(x: 234.363 * scaleX, y: 637.187 * scaleY),
            control2: CGPoint(x: 225.845 * scaleX, y: 649.531 * scaleY)
        )
        
        // Second major stroke (right side)
        path.move(to: CGPoint(x: 476.397 * scaleX, y: 390.357 * scaleY))
        path.addCurve(
            to: CGPoint(x: 487.179 * scaleX, y: 393.082 * scaleY),
            control1: CGPoint(x: 480.53 * scaleX, y: 389.73 * scaleY),
            control2: CGPoint(x: 483.944 * scaleX, y: 390.191 * scaleY)
        )
        
        path.move(to: CGPoint(x: 468.944 * scaleX, y: 468.43 * scaleY))
        path.addLine(to: CGPoint(x: 419.792 * scaleX, y: 536.336 * scaleY))
        
        // Upper strokes
        path.move(to: CGPoint(x: 440.779 * scaleX, y: 95.7695 * scaleY))
        path.addCurve(
            to: CGPoint(x: 447.92 * scaleX, y: 107.061 * scaleY),
            control1: CGPoint(x: 448.404 * scaleX, y: 96.3617 * scaleY),
            control2: CGPoint(x: 450.709 * scaleX, y: 99.9283 * scaleY)
        )
        
        path.move(to: CGPoint(x: 429.51 * scaleX, y: 144.877 * scaleY))
        path.addLine(to: CGPoint(x: 400.83 * scaleX, y: 200.396 * scaleY))
        
        path.move(to: CGPoint(x: 614.78 * scaleX, y: 241.937 * scaleY))
        path.addCurve(
            to: CGPoint(x: 625.542 * scaleX, y: 244.227 * scaleY),
            control1: CGPoint(x: 618.429 * scaleX, y: 241.669 * scaleY),
            control2: CGPoint(x: 622.624 * scaleX, y: 242.032 * scaleY)
        )
        
        return path
    }
}

#Preview {
    VStack(spacing: 0) {
        HeaderView()
        Spacer()
    }
    .frame(width: 540, height: 400)
}

#Preview("Dark Mode") {
    VStack(spacing: 0) {
        HeaderView()
        Spacer()
    }
    .frame(width: 540, height: 400)
    .preferredColorScheme(.dark)
}
