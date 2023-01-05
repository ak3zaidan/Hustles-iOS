import SwiftUI
import Kingfisher
import Firebase

struct ShopRowView: View {
    let shopItem: Shop
    let isSheet: Bool
    var body: some View {
        if let url = shopItem.photos.first {
            ZStack(alignment: .bottomTrailing){
                KFImage(URL(string: url))
                    .resizable()
                    .scaledToFill()
                    .frame(width: isSheet ? widthOrHeight(width: true) * 0.42 : widthOrHeight(width: true) * 0.48, height: isSheet ? widthOrHeight(width: true) * 0.42 : widthOrHeight(width: true) * 0.48, alignment: .center)
                    .clipped()
                    .cornerRadius(8)
                if let promoted = shopItem.promoted?.dateValue(), Timestamp().dateValue() <= promoted {
                    VStack {
                        Text("Promoted")
                            .font(.system(size: 13)).fontWeight(.semibold)
                            .frame(height: 20)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .background { Capsule().fill(.orange.gradient) }
                    }.padding(7)
                }
            }.frame(width: isSheet ? widthOrHeight(width: true) * 0.42 : widthOrHeight(width: true) * 0.48, height: isSheet ? widthOrHeight(width: true) * 0.42 : widthOrHeight(width: true) * 0.48)
        } else {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: isSheet ? widthOrHeight(width: true) * 0.42 : widthOrHeight(width: true) * 0.475, height: isSheet ? widthOrHeight(width: true) * 0.42 : widthOrHeight(width: true) * 0.475)
                .foregroundColor(Color(UIColor.lightGray))
        }
    }
}
