import SwiftUI
import Kingfisher
import Firebase

struct NewsRowView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var dateFinal: String = ""
    @State var showForward = false
    @State var sendString: String = ""
    @State var uploadVisibility: String = ""
    @State var visImage: String = ""
    @State var initialContent: uploadContent? = nil
    @State var showNewTweetView: Bool = false
    @State var place: myLoc? = nil
    
    var news: News
    let isRow: Bool

    var body: some View {
        HStack(alignment: .top){
            VStack(alignment: .leading, spacing: 8){
                HStack(spacing: 6){
                    Text(news.source).bold().foregroundStyle(colorScheme == .dark ? .white : .black)
                    Text(dateFinal)
                        .foregroundColor(.gray)
                        .font(.caption)
                        .onAppear {
                            self.dateFinal = getMessageTime(date: news.timestamp.dateValue())
                        }
                }
                HStack(spacing: 4){
                    if news.breaking != nil {
                        Text("Breaking").fontWeight(.heavy)
                            .font(.subheadline).foregroundColor(.red)
                    }
                    if news.breaking != nil && news.usersPick != nil {
                        Text("-")
                    }
                    if news.usersPick != nil {
                        Text("Users Pick")
                            .bold().font(.subheadline).foregroundColor(.blue)
                    }
                }
                if isRow {
                    Text(news.title)
                        .multilineTextAlignment(.leading).bold().padding(.bottom, 5)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .minimumScaleFactor(0.85)
                        .truncationMode(.tail)
                        .frame(minHeight: 70)
                } else {
                    Text(news.title)
                        .multilineTextAlignment(.leading).bold().padding(.bottom, 5)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .minimumScaleFactor(0.85)
                        .truncationMode(.tail)
                }
            }
            .padding(.top, 5)
            .padding(.leading, 8)
            
            Spacer()
            
            KFImage(URL(string: news.imageUrl))
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .contentShape(RoundedRectangle(cornerRadius: 5))
                .padding(.vertical, 20)
                .padding(.trailing, 8)
        }
        .background {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.gray)
                .opacity(colorScheme == .dark ? 0.35 : 0.2)
        }
        .contextMenu {
            Button {
                sendString = "https://hustle.page/news/\(news.id ?? "")/"
                showForward = true
            } label: {
                Label("Share", systemImage: "paperplane")
            }
            Button {
                showNewTweetView = true
            } label: {
                Label("Post", systemImage: "plus")
            }
            Button {
                if let url = URL(string: news.link) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } label: {
                Label("Open Link", systemImage: "link")
            }
        }
        .fullScreenCover(isPresented: $showNewTweetView, content: {
            NewTweetView(place: $place, visibility: $uploadVisibility, visibilityImage: $visImage, initialContent: $initialContent, newsID: news.id)
        })
        .sheet(isPresented: $showForward, content: {
            SendProfileView(sendLink: $sendString)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
        })
    }
}
