import SwiftUI

struct SideMenuOptionRowView: View {
    let viewModel: SideMenuViewModel
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        HStack(spacing: 16){
            Image(systemName: viewModel.imageName).font(.headline).foregroundColor(.gray)
            Text(viewModel.description)
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            Spacer()
        }
        .frame(height: 40)
        .padding(.horizontal)
    }
}
