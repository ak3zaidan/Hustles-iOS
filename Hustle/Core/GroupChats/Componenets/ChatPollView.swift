import SwiftUI
import Firebase

struct ChatPollView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @State var question: String = ""
    @State var text1: String = ""
    @State var text2: String = ""
    @State var text3: String = ""
    @State var text4: String = ""
    @FocusState var focusedFieldQ: FocusedField?
    @State var amountShow: Int = 2
    @EnvironmentObject var channel: GroupViewModel
    @EnvironmentObject var groupChat: GroupChatViewModel
    @EnvironmentObject var auth: AuthViewModel
    let isDevGroup: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10){
                    HStack {
                        Text("Question").font(.system(size: 18)).bold()
                        Spacer()
                    }
                    TextField("Ask a question", text: $question, axis: .vertical)
                        .tint(.green)
                        .lineLimit(3)
                        .focused($focusedFieldQ, equals: .one)
                        .padding(.horizontal).padding(.vertical, 10)
                        .background(.ultraThickMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            if focusedFieldQ == .one {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.green, lineWidth: 1.0)
                            }
                        }
                    
                    HStack {
                        Text("Options").font(.system(size: 18)).bold()
                        Spacer()
                    }.padding(.top, 20)
                    
                    VStack(spacing: 5){
                        TextField("Add", text: $text1)
                            .tint(.green).lineLimit(1)
                            .padding(.horizontal).padding(.vertical, 10)
                            .padding(.trailing, 15)
                            .overlay {
                                HStack {
                                    Spacer()
                                    Text("\(25 - text1.count)")
                                        .foregroundStyle(.gray)
                                }.padding(.trailing, 10)
                            }
                        Divider().padding(.leading, 15)
                        TextField("Add", text: $text2)
                            .tint(.green).lineLimit(1)
                            .padding(.horizontal).padding(.vertical, 10)
                            .padding(.trailing, 15)
                            .overlay {
                                HStack {
                                    Spacer()
                                    Text("\(25 - text2.count)")
                                        .foregroundStyle(.gray)
                                }.padding(.trailing, 10)
                            }
                        Divider().padding(.leading, 15)
                        TextField("Add (Optional)", text: $text3)
                            .tint(.green).lineLimit(1)
                            .padding(.horizontal).padding(.vertical, 10)
                            .padding(.trailing, 15)
                            .overlay {
                                HStack {
                                    Spacer()
                                    Text("\(25 - text3.count)")
                                        .foregroundStyle(.gray)
                                }.padding(.trailing, 10)
                            }
                        Divider().padding(.leading, 15)
                        TextField("Add (Optional)", text: $text4)
                            .tint(.green).lineLimit(1)
                            .padding(.horizontal).padding(.vertical, 10)
                            .padding(.trailing, 15)
                            .overlay {
                                HStack {
                                    Spacer()
                                    Text("\(25 - text4.count)")
                                        .foregroundStyle(.gray)
                                }.padding(.trailing, 10)
                            }
                    }
                    .background(.ultraThickMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding().padding(.top, 20)
            }
            .scrollIndicators(.hidden)
            .presentationDragIndicator(.hidden)
            .navigationTitle("Create Poll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Cancel").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline)
                    })
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !text1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !text2.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            sendCont()
                        }, label: {
                            Text("Send").foregroundStyle(.blue).font(.headline)
                        })
                    } else {
                        Text("Send").foregroundStyle(.gray).font(.headline)
                    }
                }
            })
        }
        .presentationDetents([.large])
        .onChange(of: text1){ _, new in
            if text1.count > 25 {
                text1.removeLast()
            }
        }
        .onChange(of: text2){ _, new in
            if text2.count > 25 {
                text2.removeLast()
            }
        }
        .onChange(of: text3){ _, new in
            if text3.count > 25 {
                text3.removeLast()
            }
        }
        .onChange(of: text4){ _, new in
            if text4.count > 25 {
                text4.removeLast()
            }
        }
    }
    func sendCont() {
        if channel.currentGroup != nil {
            sendChannel()
        } else if groupChat.currentChat != nil {
            sendGC()
        }
        presentationMode.wrappedValue.dismiss()
    }
    func sendGC() {
        if let index = groupChat.currentChat, let docID = groupChat.chats[index].id {
            let id = String((auth.currentUser?.id ?? "").prefix(6)) + String("\(UUID())".prefix(10))
            let t3: String? = text3.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : text3
            let t4: String? = text4.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : text4
            
            let new = GroupMessage(id: id, seen: nil, text: question, imageUrl: nil, audioURL: nil, videoURL: nil, file: nil, replyFrom: nil, replyText: nil, replyImage: nil, replyFile: nil, replyAudio: nil, replyVideo: nil, countSmile: nil, countCry: nil, countThumb: nil, countBless: nil, countHeart: nil, countQuestion: nil, timestamp: Timestamp(), lat: nil, long: nil, name: nil, choice1: text1, choice2: text2, choice3: t3, choice4: t4)
            
            GroupChatService().sendMessage(docID: docID, text: question, imageUrl: nil, messageID: id, replyFrom: nil, replyText: nil, replyImage: nil, replyVideo: nil, replyAudio: nil, replyFile: nil, videoURL: nil, audioURL: nil, fileURL: nil, exception: false, lat: nil, long: nil, name: nil, choice1: text1, choice2: text2, choice3: t3, choice4: t4, pinmap: nil)
            
            groupChat.chats[index].lastM = new
            
            if groupChat.chats[index].messages != nil {
                groupChat.chats[index].messages?.insert(new, at: 0)
                groupChat.setDate()
            } else {
                groupChat.chats[index].messages = [new]
                groupChat.setDate()
            }
        }
    }
    func sendChannel() {
        if let index = channel.currentGroup, let user = auth.currentUser, let uid = user.id {
            let tempId = "\(UUID())"
            let t3: String? = text3.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : text3
            let t4: String? = text4.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : text4

            let newTweet = Tweet(id: tempId, caption: question, timestamp: Timestamp(), uid: uid, username: user.username, profilephoto: user.profileImageUrl ?? "", video: nil, verified: nil, veriUser: nil, image: nil, replyFrom: nil, replyText: nil, replyImage: nil, choice1: text1, choice2: text2, choice3: t3, choice4: t4)
            
            if isDevGroup {
                if index < channel.groupsDev.count {
                    if channel.groupsDev[index].messages != nil {
                        channel.groupsDev[index].messages?.insert(newTweet, at: 0)
                    } else {
                        channel.groupsDev[index].messages = [newTweet]
                    }
                    ExploreService().uploadPoll(question: question, text1: text1, text2: text2, text3: t3, text4: t4, groupId: channel.groups[index].1.id, username: auth.currentUser?.username ?? "", profileP: auth.currentUser?.profileImageUrl, square: "", devGroup: true, newTextID: tempId)
                }
            } else {
                if index < channel.groups.count {
                    if channel.groups[index].0 == "Rules" || channel.groups[index].0 == "Info/Description" {
                        if let indexSec = channel.groups[index].1.messages?.firstIndex(where: { $0.id == "Main" }) {
                            channel.groups[index].1.messages?[indexSec].messages.insert(newTweet, at: 0)
                        }
                    } else {
                        if let indexSec = channel.groups[index].1.messages?.firstIndex(where: { $0.id == channel.groups[index].0 }) {
                            channel.groups[index].1.messages?[indexSec].messages.insert(newTweet, at: 0)
                        }
                    }
                    
                    var square = "Main"
                    if channel.groups[index].0 != "Rules" && channel.groups[index].0 != "Info/Description" {
                        square = channel.groups[index].0
                    }
                    ExploreService().uploadPoll(question: question, text1: text1, text2: text2, text3: t3, text4: t4, groupId: channel.groups[index].1.id, username: user.username, profileP: user.profileImageUrl ?? "", square: square, devGroup: false, newTextID: tempId)
                }
            }
        }
    }
}
