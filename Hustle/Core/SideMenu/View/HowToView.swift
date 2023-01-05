import SwiftUI

struct HowToView: View {
    @EnvironmentObject var popRoot: PopToRoot
    @Environment(\.presentationMode) var presentationMode
    @State private var viewIsTop = false
    var body: some View {
        VStack(alignment: .leading){
            ZStack(alignment: .leading){
                Color(.orange).ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20){
                    HStack{
                        Text("How To").font(.title)
                        Spacer()
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            HStack(spacing: 2){
                                Image(systemName: "chevron.backward")
                                    .scaleEffect(1.5)
                                    .frame(width: 15, height: 15)
                                Text("back").font(.subheadline)
                            }
                        }
                    }.padding(.horizontal, 25).padding(.top)
                }
            }.frame(height: 80)
            
            ScrollView {
                VStack(alignment: .leading){
                    HStack {
                        Text("Universal").font(.title3).bold().padding(.top, 15)
                        Spacer()
                    }.padding(.top, 15)
                    VStack(alignment: .leading){
                        Text("-Click the page title of the first 3 tabs to switch pages and see something different!")
                            .font(.headline).foregroundColor(.gray).bold()
                        Text("-Click the tab button to scroll up or navigate back.")
                            .font(.headline).foregroundColor(.gray)
                    }.padding(.leading, 25).padding(.top, 10)
                }
                VStack(alignment: .leading){
                    HStack {
                        Text("Tab 1 (Hustles)").font(.title3).bold().padding(.top, 15)
                        Spacer()
                    }.padding(.top, 15)
                    VStack(alignment: .leading, spacing: 8){
                        Text("-Click 'Hustles' to view more content.")
                            .font(.headline).foregroundColor(.gray).bold()
                        Text("-In the Verified page, swipe right on the text to go next and left to go back.")
                            .font(.headline).foregroundColor(.gray)
                    }.padding(.leading, 25).padding(.top, 10)
                }
                 
                VStack(alignment: .leading){
                    HStack {
                        Text("Tab 2 (Jobs/MarketPlace)").font(.title3).bold()
                        Spacer()
                    }.padding(.top, 15)
                    VStack(alignment: .leading, spacing: 8){
                        Text("-Click 'Jobs' to view the MarketPlace.")
                            .font(.headline).foregroundColor(.gray).bold()
                        Text("-View the approximate location of a post by clicking on the blue globe.")
                            .font(.headline).foregroundColor(.gray)
                        Text("-Filter 4Sale results by picking a tag or searching for a tag.")
                            .font(.headline).foregroundColor(.gray)
                        Text("-Edit the price of an item 4Sale by clicking on the three dots below the images.")
                            .font(.headline).foregroundColor(.gray)
                    }.padding(.leading, 25).padding(.top, 10)
                }
                
                VStack(alignment: .leading){
                    HStack {
                        Text("Tab 3 (Discover)").font(.title3).bold()
                        Spacer()
                    }.padding(.top, 15)
                    VStack(alignment: .leading, spacing: 8){
                        Text("-Click 'Discover' to view Videos, go back by clicking 'Swipes'.")
                            .font(.headline).foregroundColor(.gray).bold()
                        Text("-Watching a Swipes Video? Hold down until you see the time bar, then drag left or right to the desired video duration.").font(.headline).foregroundColor(.gray)
                        Text("-Click a news article to see Opinions, or click it again at the top to open the link in Google.").font(.headline).foregroundColor(.gray)
                        Text("-Post an Opinion by clicking 'send' on the keyboard, or post an Opinion Reply by clicking on the message icon first for the specified Opinion.")
                            .font(.headline).foregroundColor(.gray)
                        Text("-Change the search type by clicking 'users' to the right of the search box.")
                            .font(.headline).foregroundColor(.gray)
                    }.padding(.leading, 25).padding(.top, 10)
                }
                
                HStack {
                    Text("Tab 4 (Ask)").font(.title3).bold()
                    Spacer()
                }.padding(.top, 15)
                VStack(alignment: .leading, spacing: 8){
                    Text("-Post a photo question by selecting 'photo question' at the top.")
                        .font(.headline).foregroundColor(.gray)
                    Text("-Toggle the image shown in a question by swiping left or right when the image is zoomed out.").font(.headline).foregroundColor(.gray)
                    Text("-Double click the image in a photo question to zoom out.")
                        .font(.headline).foregroundColor(.gray)
                }.padding(.leading, 25).padding(.top, 10)
                
                VStack(alignment: .leading){
                    HStack {
                        Text("Tab 5 (Message)").font(.title3).bold()
                        Spacer()
                    }.padding(.top, 15)
                    VStack(alignment: .leading, spacing: 8){
                        Text("-Click the bell to view notifications.")
                            .font(.headline).foregroundColor(.gray)
                        Text("-Double click, swipe on the left edge, or click the tab button to leave a chat.").font(.headline).foregroundColor(.gray)
                        Text("-Click on 'end-to-encrypted' to view details.")
                            .font(.headline).foregroundColor(.gray)
                        Text("-Delete or copy a message by holding down on it.")
                            .font(.headline).foregroundColor(.gray)
                        Text("-Send group/invite links in chats.")
                            .font(.headline).foregroundColor(.gray)
                    }.padding(.leading, 25).padding(.top, 10)
                }
                Color.clear.frame(height: 30)
            }.padding(.horizontal).scrollIndicators(.hidden)
        }
        .navigationBarBackButtonHidden(true)
        .padding(.bottom, 45)
        .onChange(of: popRoot.tap, perform: { _ in
            if popRoot.tap == 6 && viewIsTop {
                presentationMode.wrappedValue.dismiss()
                popRoot.tap = 0
            }
        })
        .onAppear { viewIsTop = true }
        .onDisappear { viewIsTop = false }
    }
}
