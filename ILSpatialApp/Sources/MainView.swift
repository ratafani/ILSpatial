import SwiftUI
import RealityKit
import ILSFoundation

struct MainView: View {
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    @State private var isImmersiveSpaceOpen = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("ILSpatial Engine")
                .font(TypographyTokens.header)
                .foregroundColor(ColorTokens.primaryText)
            
            Text("Your universal spatial foundation.")
                .font(TypographyTokens.subheader)
                .foregroundColor(ColorTokens.secondaryText)
            
            Toggle("Immersive Mode", isOn: $isImmersiveSpaceOpen)
                .toggleStyle(.button)
                .padding()
        }
        .padding(40)
        .glassBackgroundEffect()
        .onChange(of: isImmersiveSpaceOpen) { _, newValue in
            Task {
                if newValue {
                    await openImmersiveSpace(id: "ImmersiveSpace")
                } else {
                    await dismissImmersiveSpace()
                }
            }
        }
    }
}
