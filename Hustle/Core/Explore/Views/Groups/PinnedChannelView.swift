import SwiftUI
import Kingfisher

struct PinnedChannelView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressingDown: Bool = false
    @State private var started: Bool = false
    @Binding var delete: Bool
    let server: GroupX
    @Binding var navigate: Bool
    @Binding var navServer: GroupX?
    let remove: (String) -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 8){
                ZStack {
                    Circle()
                        .fill(Color.gray.gradient)
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: "person.3.fill").font(.title3).foregroundStyle(.white)
                    
                    KFImage(URL(string: server.imageUrl))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                        .contentShape(Circle())
                }
                .shadow(color: .gray, radius: 4)
                .jiggle(isEnabled: delete)
                .overlay(alignment: .topLeading){
                    if delete {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            remove(server.id)
                            UserService().removeChatPin(id: server.id)
                        }, label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.gray)
                                .background(Color.white)
                                .clipShape(Circle())
                                .font(.title)
                        })
                    }
                }
                Text(server.title)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .fontWeight(.regular)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: 130)
            }
        }
        .scaleEffect(isPressingDown ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: started)
        .transition(.scale.combined(with: .blurReplace))
        .onLongPressGesture(minimumDuration: .infinity) {
            
        } onPressingChanged: { starting in
            if starting {
                started = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05){
                    if started {
                        withAnimation {
                            isPressingDown = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25){
                            if isPressingDown {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                delete.toggle()
                                withAnimation {
                                    isPressingDown = false
                                }
                            }
                        }
                    } else if !delete {
                        navServer = server
                        navigate = true
                    }
                }
            } else {
                started = false
                if isPressingDown {
                    withAnimation {
                        self.isPressingDown = false
                    }
                }
            }
        }
    }
}
