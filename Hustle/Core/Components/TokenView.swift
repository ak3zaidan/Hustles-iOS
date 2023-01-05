import SwiftUI

struct TokenView: View {
    let showText: Bool
    @Binding var showToken: Bool
    @State var show = false
    @State var size = 0.01
    @State var offset = 0.01
    @State var rotationAngle: Angle = .degrees(0.1)
    @State var reason = ""
    let image: String
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.9)
            VStack(spacing: 0){
                Spacer()
                if showText{
                    if show {
                        Text("New Token Unlocked!").font(.system(size: 20)).bold()
                    }
                }
                Text("_\(reason)_").font(.subheadline).padding(.vertical, 7)
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .rotation3DEffect(rotationAngle, axis: (x: 0, y: 1, z: 0))
                Ellipse()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: size / 1.8, height: size / 5.75)
                Spacer()
            }.offset(y: offset)
        }
        .onTapGesture {
            withAnimation(.linear(duration: 0.3)){
                offset = 900
            }
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                showToken = false
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { size = 175 }
            Timer.scheduledTimer(withTimeInterval: 0.42, repeats: false) { _ in
                withAnimation(.easeInOut){ show = true }
            }
            Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                withAnimation(.linear(duration: 0.01)) { rotationAngle += .degrees(1.75) }
            }
            if image == "g_owner" { reason = "Achieved king rank" }
            else if image == "write" { reason = "Hustler Member" }
            else if image == "tentips" { reason = "Uploaded 10 verified tips" }
            else if image == "tenhustles" { reason = "Uploaded 10 verified hustles" }
            else if image == "fivejobs" { reason = "Completed 5 jobs" }
            else if image == "heart" { reason = "Recieved 1000 likes on a post" }
        }
    }
}
