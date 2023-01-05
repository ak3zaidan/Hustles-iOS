import SwiftUI
import Kingfisher

struct ViewGroupBubble: View {
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var groupViewModel: ExploreViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showTime = false
    @State private var showGroup = false
    @State private var showLoad = false
    @State var message: Message
    @State var recieved: Bool
    @State private var is_uid_one: Bool
    
    init(message: Message, is_uid_one: Bool){
        _message = State(initialValue: message)
        _is_uid_one = State(initialValue: is_uid_one)
        if is_uid_one && message.uid_one_did_recieve || !is_uid_one && !message.uid_one_did_recieve {
            _recieved = State(initialValue: true)
        } else {
            _recieved = State(initialValue: false)
        }
    }

    var body: some View {
        HStack {
            if !recieved {
                Spacer()
            }
            if recieved {
                if showTime {
                    Text("\(message.timestamp.dateValue().formatted(.dateTime.hour().minute()))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 5)
                }
            }
            VStack(alignment: recieved ? .trailing : .leading, spacing: 1){
                HStack{
                    if !recieved {
                        Spacer()
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.orange).gradient.opacity(colorScheme == .dark ? 0.3 : 0.7))
                        HStack {
                            if let text = message.text {
                                Text("View: \(text.components(separatedBy: "pub!@#$%^&*()").last ?? "")")
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .font(.system(size: 15))
                                Spacer()
                                Button {
                                    groupViewModel.fetchGroupForMessages(id: message.text?.components(separatedBy: "pub!@#$%^&*()").first ?? "")
                                    showLoad = true
                                } label: {
                                    if showLoad {
                                        ProgressView().padding(.trailing, 10)
                                    } else {
                                        ZStack(alignment: .center){
                                            Capsule()
                                                .frame(width: 45, height: 25)
                                                .foregroundColor(.blue)
                                            Text("Go")
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .font(.system(size: 15).bold())
                                        }
                                    }
                                }
                                .fullScreenCover(isPresented: $showGroup) {
                                    if let first = groupViewModel.groupFromMessage.first {
                                        NavigationStack {
                                            GroupView(group: first, imageName: "", title: "", remTab: false, showSearch: false)
                                        }
                                    }
                                }
                                .onChange(of: groupViewModel.groupFromMessageSet) { _, _ in
                                    showLoad = false
                                    if groupViewModel.groupFromMessage.first != nil {
                                        showGroup = true
                                        popRoot.displayingGroup = true
                                    } else {
                                        showGroup = false
                                    }
                                }
                                .onChange(of: showGroup) { _, _ in
                                    if !showGroup { popRoot.displayingGroup = false }
                                }
                            }
                        }.padding(.horizontal)
                    }
                    .frame(width: 250, height: 50)
                    if recieved {
                        Spacer()
                    }
                }
            }
            .onTapGesture {
                showTime.toggle()
            }
            if !recieved {
                if showTime {
                    Text("\(message.timestamp.dateValue().formatted(.dateTime.hour().minute()))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 5)
                }
            }
            if recieved{
                Spacer()
            }
        }.padding(.horizontal)
    }
}
