import SwiftUI
import Kingfisher

struct DiscoverRowView: View {
    @State var imageName: String
    @State var title: String
    @State var scale: Double
    @State var titleArray: [String] = ["Sneakers", "Real Estate", "Crypto", "Investing", "DropShip", "eCommerce", "Stocks", "Amazon", "Services", "Tech"]
    @State private var opacity = 0.2
    @State var letters: [String] = Array(repeating: "?", count: 7)
    
    init(title: String, imageName: String, scale: Double){
        self.imageName = imageName
        self.title = title
        self.scale = scale
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 2){
            if title == "" {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(.gray).opacity(opacity)
                        .frame(width: 100,height: 70)
                    LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
                        .frame(width: 100,height: 70)
                        .cornerRadius(10)
                }
                Text(letters.joined(separator: ""))
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .blur(radius: 1)
                    .onAppear {
                        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                           letters = letters.map { _ in randomLetter() }
                        }
                    }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(.gray)
                        .frame(width: 100,height: 70)
                        .opacity(0.4)
                    if imageName == "lock" || imageName == "lock.open"{
                        Image(systemName: imageName)
                            .frame(width: 60, height: 60)
                            .scaleEffect(scale)
                            .offset(y: -15)
                    } else {
                        if titleArray.contains(self.title) {
                            Image(imageName)
                                .frame(width: 60, height: 60)
                                .scaleEffect(scale)
                                .offset(y: -15)
                        } else {
                            KFImage(URL(string: imageName))
                                .resizable()
                                .modifier(GroupImageModifier())
                        }
                    }
                }
                Text(title).font(.subheadline)
            }
        }
    }
}

func randomLetter() -> String {
    let letters = "abcdefghijklmnopqurstuvwxyv"
    let randomLetter = letters.randomElement()
    return String(randomLetter ?? "?")
}
