import SwiftUI

struct PlaceholderScreenView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Text(title)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color(red: 106 / 255, green: 114 / 255, blue: 130 / 255))
            Spacer()
        }
        .padding(.bottom, 120)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}
