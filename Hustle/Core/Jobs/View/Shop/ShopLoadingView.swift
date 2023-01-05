import SwiftUI

struct ShopLoadingView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(0..<12){ i in
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: widthOrHeight(width: true) * 0.475, height: widthOrHeight(width: true) * 0.475)
                        .foregroundColor(Color(UIColor.lightGray))
                        .shimmering()
                }
            }
        }.padding(.horizontal, 5).scrollIndicators(.hidden)
    }
}
