import SwiftUI
import Kingfisher

struct PinnedChatView: View {
    @State private var seen: Bool = false
    @State private var active: Bool = false
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showMessage: Bool = false
    @State private var isPressingDown: Bool = false
    @State private var started: Bool = false
    @State var index: Int = 0
    @Binding var delete: Bool
    @Binding var chat: Chats
    @Binding var navigate: Bool
    @Binding var navChat: Chats?
    @Binding var updatePin: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 8){
                ZStack {
                    Circle()
                        .fill(Color.gray.gradient)
                        .frame(width: 90, height: 90)
                    if let name = chat.user.fullname.first ?? chat.user.username.first {
                        Text(String(name).uppercased()).font(.system(size: 30)).fontWeight(.medium)
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white).font(.title3)
                    }
                    if let image = chat.user.profileImageUrl {
                        KFImage(URL(string: image))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                            .contentShape(Circle())
                    }
                }
                .shadow(color: .gray, radius: colorScheme == .dark ? 4 : 3)
                .jiggle(isEnabled: delete)
                .overlay(alignment: .topLeading){
                    if delete {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                auth.currentUser?.pinnedChats?.removeAll(where: { $0 == chat.convo.id })
                            }
                            UserService().removeChatPin(id: chat.convo.id ?? "")
                        }, label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.gray)
                                .background(Color.white)
                                .clipShape(Circle())
                                .font(.title)
                        })
                    } else if active {
                        ZStack {
                            Circle().foregroundStyle(colorScheme == .dark ? .black : .white).frame(width: 20)
                            Circle().foregroundStyle(.green).frame(width: 18)
                        }.offset(x: 6, y: 6)
                    }
                }
                Text(chat.user.fullname)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .fontWeight(seen ? .bold : .regular)
                    .foregroundStyle(seen ? .blue : .gray)
                    .frame(maxWidth: 130)
            }
            
            if !delete && showMessage {
                if index == 2 || index == 5 || index == 8 || (chat.lastM?.text ?? "").count < 11 {
                    Text(chat.lastM?.text ?? "")
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .lineLimit(2)
                        .padding(4)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .frame(minWidth: 50)
                        .background {
                            ZStack(alignment: .top){
                                Triangle()
                                    .frame(width: 15, height: 12)
                                    .offset(y: -10)
                                RoundedRectangle(cornerRadius: 10)
                            }
                            .foregroundStyle(colorScheme == .dark ? .black : .white)
                        }
                        .shadow(color: .gray, radius: colorScheme == .dark ? 4 : 7)
                        .frame(maxWidth: widthOrHeight(width: true) * 0.4)
                        .offset(y: 18)
                        .transition(.scale.combined(with: .opacity).combined(with: .move(edge: .top)))
                } else if index == 1 || index == 4 || index == 9 {
                    Text(chat.lastM?.text ?? "")
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .lineLimit(2)
                        .padding(4)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .frame(minWidth: 50)
                        .background {
                            ZStack(alignment: .bottom){
                                Triangle()
                                    .frame(width: 15, height: 12)
                                    .offset(y: 10)
                                    .rotationEffect(.degrees(45))
                                    .offset(x: (chat.lastM?.text ?? "").count > 15 ? -20 : 0)
                                RoundedRectangle(cornerRadius: 10)
                            }
                            .foregroundStyle(colorScheme == .dark ? .black : .white)
                        }
                        .shadow(color: .gray, radius: colorScheme == .dark ? 4 : 7)
                        .frame(maxWidth: widthOrHeight(width: true) * 0.4)
                        .offset(y: -26)
                        .transition(.scale.combined(with: .opacity).combined(with: .move(edge: .bottom)))
                } else {
                    Text(chat.lastM?.text ?? "")
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .lineLimit(2)
                        .padding(4)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .frame(minWidth: 50)
                        .background {
                            ZStack(alignment: .bottom){
                                Triangle()
                                    .frame(width: 15, height: 12)
                                    .offset(y: 10)
                                    .rotationEffect(.degrees(-45))
                                    .offset(x: (chat.lastM?.text ?? "").count > 15 ? 20 : 0)
                                RoundedRectangle(cornerRadius: 10)
                            }
                            .foregroundStyle(colorScheme == .dark ? .black : .white)
                        }
                        .shadow(color: .gray, radius: colorScheme == .dark ? 4 : 7)
                        .frame(maxWidth: widthOrHeight(width: true) * 0.4)
                        .offset(y: -26)
                        .transition(.scale.combined(with: .opacity).combined(with: .move(edge: .bottom)))
                }
            }
        }
        .onChange(of: auth.currentUser?.pinnedChats, { _, _ in
            if let pos = auth.currentUser?.pinnedChats?.firstIndex(where: { $0 == chat.convo.id }) {
                self.index = pos + 1
            }
        })
        .onAppear(perform: {
            setUp()
        })
        .onChange(of: updatePin, { _, _ in
            setUp()
        })
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
                        navChat = chat
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
    func setUp() {
        if let pos = auth.currentUser?.pinnedChats?.firstIndex(where: { $0 == chat.convo.id }) {
            self.index = pos + 1
        }
        
        if let lastTime = chat.user.lastSeen {
            let dateString = lastTime.dateValue().formatted(.dateTime.month().day().year().hour().minute())
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "MMMM dd, yyyy 'at' h:mm a"
            if let date = dateFormatter.date(from:dateString){
                if Calendar.current.isDateInToday(date){
                    active = true
                } else {
                    active = false
                }
            } else {
                active = false
            }
        } else {
            active = false
        }
        
        let is_uid_one = (chat.convo.uid_one == auth.currentUser?.id ?? "")
        if let check1 = chat.lastM?.uid_one_did_recieve, let seen = chat.lastM?.seen_by_reciever {
            if (is_uid_one && check1) || (!is_uid_one && !check1) {
                if !seen {
                    self.seen = true
                    if let text = chat.lastM?.text, !text.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                            withAnimation(.easeIn(duration: 0.2)){
                                self.showMessage = true
                            }
                        }
                    } else {
                        withAnimation(.easeIn(duration: 0.2)){
                            self.showMessage = false
                        }
                    }
                } else {
                    self.seen = false
                }
            }
        }
    }
}

extension View {
    @ViewBuilder
    func jiggle(amount: Double = 4, isEnabled: Bool = true) -> some View {
        if isEnabled {
            modifier(JiggleViewModifier(amount: amount))
        } else {
            self
        }
    }
}

private struct JiggleViewModifier: ViewModifier {
    let amount: Double

    @State private var isJiggling = false

    func body(content: Content) -> some View {
        content
            .offset(x: isJiggling ? 3 : -3)
            .offset(y: isJiggling ? -3 : 3)
            .animation(
                .easeInOut(duration: randomize(interval: 0.07, withVariance: 0.025))
                .repeatForever(autoreverses: true),
                value: isJiggling
            )
            .animation (
                .easeInOut(duration: randomize(interval: 0.14, withVariance: 0.025))
                .repeatForever(autoreverses: true),
                value: isJiggling
            )
            .task {
                isJiggling.toggle()
            }
    }

    private func randomize(interval: TimeInterval, withVariance variance: Double) -> TimeInterval {
         interval + variance * (Double.random(in: 500...1_000) / 500)
    }
}

struct PinnedChatLoader: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack(spacing: 8){
            Circle()
                .fill(Color.gray.gradient)
                .frame(width: 90, height: 90)
                .shadow(color: .gray, radius: colorScheme == .dark ? 4 : 5)

            Text("Michael Don")
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.tail)
                .fontWeight(.regular)
                .foregroundStyle(.gray)
                .frame(maxWidth: 130)
                .blur(radius: 3.0)
        }
        .shimmering()
    }
}
