import SwiftUI

struct UnknownView: View {
    @EnvironmentObject var viewModel: ExploreViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @State var backShow = false
    
    @Binding var show: Bool
    @Binding var caption: String
    @Binding var tag: String
    let username: String
    let newsName: String?
    
    var body: some View {
        ZStack {
            Color.gray.opacity(backShow ? 0.4 : 0.001)
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill (
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white, Color.black]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                ZStack(alignment: .top){
                    HStack {
                        Spacer()
                        Image("unknown").resizable().aspectRatio(contentMode: .fit).opacity(0.8).offset(x: 20)
                            .frame(height: 280)
                    }
                    HStack {
                        Text("Anonymous?").gradientForeground(colors: [.black, .white]).font(.title).bold()
                        Spacer()
                    }.padding(.leading).offset(y: 100)
                    VStack(spacing: 3){
                        Spacer()
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            viewModel.sendNewsRep(caption: caption, user: ""){ success in
                                if success && !tag.isEmpty {
                                    popRoot.alertImage = "tag.fill"
                                    popRoot.alertReason = "Tagged user notified"
                                    withAnimation {
                                        popRoot.showAlert = true
                                    }
                                    viewModel.tagUserNews(myUsername: username, otherUsername: tag, message: caption, newsName: newsName)
                                }
                                tag = ""
                                caption = ""
                            }
                            withAnimation(.easeInOut(duration: 0.1)){ backShow = false }
                            withAnimation(.easeOut){
                                show = false
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15).fill(.ultraThinMaterial).frame(height: 40)
                                Text("Dont Include Username").foregroundColor(.white)
                                    .font(.system(size: 15)).bold()
                            }
                        }
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            viewModel.sendNewsRep(caption: caption, user: username){ success in
                                if success && !tag.isEmpty {
                                    popRoot.alertImage = "tag.fill"
                                    popRoot.alertReason = "Tagged user notified"
                                    withAnimation {
                                        popRoot.showAlert = true
                                    }
                                    viewModel.tagUserNews(myUsername: username, otherUsername: tag, message: caption, newsName: newsName)
                                }
                                caption = ""
                                tag = ""
                            }
                            withAnimation(.easeInOut(duration: 0.1)){ backShow = false }
                            withAnimation(.easeOut){
                                show = false
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15).fill(.ultraThinMaterial).frame(height: 40)
                                Text("Include Username").foregroundColor(.white)
                                    .font(.system(size: 15)).bold()
                            }
                        }
                    }.padding(.horizontal).padding(.bottom, 10)
                }
            }.frame(width: 270, height: 350)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4)){ backShow = true }
        }
    }
}

extension View {
    public func gradientForeground(colors: [Color]) -> some View {
        self.overlay(
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing)
        )
        .mask(self)
    }
}
