import SwiftUI
import Kingfisher
import Firebase
import AudioToolbox

struct WaveButtonChat: View {
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var auth: AuthViewModel
    @State var scale = 0.5
    @State var scale2 = 1.0
    @State var offset1 = 0.0
    @State var offset2 = 0.0
    @State var status = false
    @State var sent = false
    
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 20){
                LottieView(loopMode: .loop, name: "waveHello")
                    .scaleEffect(scale)
                    .frame(width: 110, height: 130)
                    .offset(y: offset1)
                    .zIndex(5.0)
                Text("Wave").font(.headline).fontWeight(.heavy)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 15).padding(.vertical, 7)
                    .background {
                        LinearGradient(colors: [.blue, .purple], startPoint: .bottomLeading, endPoint: .topTrailing)
                    }
                    .clipShape(Capsule())
                    .zIndex(1.0)
                    .offset(y: offset2)
                    .scaleEffect(scale2)
                    .particleEffect360(systemImage: "hand.wave.fill", font: .subheadline, status: status, activeTint: Color.purple, inActiveTint: Color.gray, direction: true)
            }
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                withAnimation(.easeInOut(duration: 0.1)){
                    scale = 0.2
                    scale2 = 0.9
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.3)){
                        scale = 0.5
                        scale2 = 1.0
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeInOut(duration: 0.2)){
                        offset1 = 300.0
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    withAnimation(.easeInOut(duration: 0.2)){
                        offset2 = 300.0
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                    withAnimation(.easeInOut(duration: 0.2)){
                        scale2 = 0.6
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) {
                    withAnimation(.easeInOut(duration: 0.2)){
                        scale2 = 1.3
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                    status.toggle()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    sendContent()
                }
            }
        }.padding(.trailing, 45)
    }
    func sendContent() {
        if !sent {
            sent = true
            if let index = viewModel.currentChat {
                let uid = Auth.auth().currentUser?.uid ?? ""
                let uid_prefix = String(uid.prefix(5))
                
                let id = uid_prefix + String("\(UUID())".prefix(15))
                
                let new = Message(id: id, uid_one_did_recieve: (viewModel.chats[index].convo.uid_one == auth.currentUser?.id ?? "") ? false : true, seen_by_reciever: false, text: "Hello!", timestamp: Timestamp(), sentAImage: nil, replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, replyAudio: nil, replyVideo: nil)
                
                AudioServicesPlaySystemSound(1004)
                viewModel.chats[index].lastM = new
                
                viewModel.sendMessagesMain(myMessArr: auth.currentUser?.myMessages ?? [], otherUserUid: viewModel.chats[index].user.id ?? "", text: "Hello!", elo: nil, image: nil, messageID: id, fileData: nil, replyID: nil, selfReply: nil, myUsername: auth.currentUser?.username ?? "You Replied", videoURL: nil, audioURL: nil)
                
                withAnimation(.bouncy(duration: 0.3)){
                    if viewModel.chats[index].messages != nil {
                        viewModel.chats[index].messages?.insert(new, at: 0)
                    } else {
                        viewModel.chats[index].messages = [new]
                    }
                }
                viewModel.setDate()
            }
        }
    }
}
