import SwiftUI

struct SavedView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: ProfileViewModel
    @EnvironmentObject var auth: AuthViewModel
    @State var currentAudio: String = ""
    @State var tempSet: Bool = false
    @Namespace private var animation
    @Namespace private var newsAnimation
    
    var body: some View {
        VStack {
            HStack(spacing: 8){
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                    Text("Saved Posts").bold()
                }.font(.title)
                Spacer()
            }.padding(.leading)
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.allSaved) { tweet in
                        TweetRowView(tweet: tweet, edit: false, canShow: true, canSeeComments: true, map: false, currentAudio: $currentAudio, isExpanded: $tempSet, animationT: animation, seenAllStories: false, isMain: false, showSheet: $tempSet, newsAnimation: newsAnimation)
                        
                        if tweet != viewModel.allSaved.last {
                            Divider().overlay(.gray).padding(.bottom, 6)
                        }
                    }
                    Color.clear.frame(height: 100)
                }
            }
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let saved = auth.currentUser?.savedPosts, !saved.isEmpty && viewModel.allSaved.isEmpty {
                viewModel.getAllSaved(all: saved)
            }
        }
    }
}
