import SwiftUI
import Kingfisher

struct AdTestRow: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    let plus: Bool
    let caption: String
    let image: Image?
    let video: String?
    let link: String?
    let appName: String?

    var body: some View {
        VStack(alignment: .leading){
            HStack(alignment: .top, spacing: 12){
                ZStack(alignment: .bottomTrailing) {
                    if let image = auth.currentUser?.profileImageUrl {
                        KFImage(URL(string: image))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width:56, height: 56)
                            .clipShape(Circle())
                    } else {
                        ZStack(alignment: .center){
                            Image(systemName: "circle.fill")
                                .resizable()
                                .foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : .black)
                                .frame(width: 56, height: 56)
                            Image(systemName: "questionmark")
                                .resizable()
                                .foregroundColor(.white)
                                .frame(width: 17, height: 22)
                        }
                    }
                    Image("veriBlue")
                        .resizable()
                        .frame(width: 30, height: 25).offset(x: 3, y: 5)
                }
                VStack(alignment: .leading){
                    HStack(spacing: 0){
                        Text("@\(auth.currentUser?.username ?? "*Username*")")
                            .lineLimit(1).minimumScaleFactor(0.6)
                            .font(.title3).bold()
                        Spacer()
                        RoundedRectangle(cornerRadius: 5)
                            .frame(width: 70, height: 20)
                            .foregroundColor(.orange).opacity(0.7)
                            .overlay(
                                HStack{
                                    Text(plus ? "Boost+" : "Boost")
                                        .font(.caption)
                                        .foregroundColor(.white).bold()
                                    Image(systemName: "arrow.up")
                                        .resizable()
                                        .frame(width: 10, height: 10)
                                        .foregroundColor(.white)
                                }
                            )
                        Text("✅")
                    }
                    LinkedText(caption, tip: true, isMess: nil)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.leading)
                    if let pic = image {
                        HStack{
                            Spacer()
                            pic
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 250)
                                .cornerRadius(5)
                            Spacer()
                        }.padding(.trailing, 13).padding(.vertical, 5)
                    }
                }
            }
            if let link = video {
                HStack {
                    Spacer()
                    if !link.contains(".") && !link.contains("https://") && !link.contains("com") && link.contains("shorts"){
                        YouTubeView(link: link, short: true)
                            .frame(width: 370, height: 370)
                    } else if !link.contains(".") && !link.contains("https://") && !link.contains("com"){
                        YouTubeView(link: link, short: false).frame(width: widthOrHeight(width: true) * 0.8, height: widthOrHeight(width: false) * 0.25)
                    } else {
                        WebVideoView(link: link)
                            .padding(.vertical, 8)
                            .offset(x: 5)
                            .frame(width: widthOrHeight(width: true) * 0.88, height: widthOrHeight(width: false) * 0.23)
                    }
                    Spacer()
                }
            }
            if let name = appName {
                HStack {
                    Spacer()
                    ZStack(alignment: .top){
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(colorScheme == .dark ? .white : .black, lineWidth: 1)
                        VStack{
                            HStack{
                                VStack(spacing: 3){
                                    HStack{
                                        Text("\(name) - Genra...").font(.subheadline).bold()
                                        Spacer()
                                    }
                                    HStack(spacing: 0.5){
                                        ForEach(1...5, id: \.self) { index in
                                            Image(systemName: "star.fill")
                                                .resizable()
                                                .frame(width: 10, height: 10)
                                                .foregroundColor(.gray)
                                        }
                                        Text("Rated 5.0 of 5")
                                            .foregroundColor(.gray).font(.caption).padding(.leading)
                                        Spacer()
                                    }
                                }
                                Spacer()
                            }
                            HStack{
                                Spacer()
                                Button {
                                    if let url = URL(string: "itms-apps://apps.apple.com/app/id") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    ZStack(alignment: .center){
                                        RoundedRectangle(cornerRadius: 10)
                                            .frame(width: 180)
                                            .foregroundColor(.blue)
                                        Text("Download")
                                            .foregroundColor(.white)
                                            .font(.subheadline)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .padding(.leading, 6)
                        .padding(.vertical, 3)
                    }
                    .padding(.top, 3)
                    .frame(width: 250, height: 50)
                    Spacer()
                }
                .padding(.leading, image != nil ? 54 : 15)
                .padding(.top, image != nil ? 2 : 0)
            }
            HStack(alignment: .center, spacing: 35){
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    HStack(spacing: 2){
                        Text("\(225)")
                        Image(systemName: "bubble.left").font(.subheadline)
                    }
                }
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    ZStack {
                        Color.clear.frame(width: 25, height: 15)
                        HStack(spacing: 2){
                            Text("\(2054)")
                            Image(systemName: "heart.fill")
                                .font(.subheadline).foregroundColor(.red)
                        }.padding(5)
                    }
                }
                if let loc = link {
                    HStack{
                        Spacer()
                        Link(destination: URL(string: loc)!) {
                            ZStack(alignment: .center){
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 100, height: 25)
                                    .foregroundColor(.gray)
                                Text("Visit Site")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 4)
            Divider().overlay(colorScheme == .dark ? Color(red: 220/255, green: 220/255, blue: 220/255) : .gray)
                .frame(height: 2)
        }
    }
}
