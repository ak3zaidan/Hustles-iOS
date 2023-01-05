import SwiftUI
import Kingfisher

struct NewsContextView: View {
    
    var body: some View {
        VStack(spacing: 10){
            Text("No one is Live yet.")
                .font(.title3).fontWeight(.semibold)
                .padding(.top, widthOrHeight(width: false) * 0.3)
            Text("Lives will appear here")
                .font(.subheadline).fontWeight(.light)
                .padding(.bottom, 20)
            LottieView(loopMode: .loop, name: "liveLoader")
                .scaleEffect(0.9)
                .frame(width: 85, height: 85)
            Spacer()
        }
    }
}

//#Preview {
//    NewsContextView()
//}
