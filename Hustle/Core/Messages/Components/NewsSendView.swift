import SwiftUI
import Kingfisher

struct NewsSendView: View {
    @EnvironmentObject var viewModel: ExploreViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @Namespace private var newsAnimation
    @State private var showForward = false
    @State var sendLink: String = ""
    @State var noFound: Bool = false
   
    let fullURL: String
    let leading: Bool
    @State var currentNews: News?
    let isGroup: Bool
    
    var body: some View {
        HStack(spacing: 10){
            if let news = currentNews {
                if leading && !isGroup {
                    optionButtons()
                }
                NavigationLink {
                    TopNewsView(animation: newsAnimation, newsMid: news.id ?? "NANID", animate: false, news: news)
                } label: {
                    NewsRowView(news: news, isRow: false)
                }
                .overlay(alignment: .leading){
                    if isGroup {
                        optionButtons().offset(x: -40)
                    }
                }
                if !leading && !isGroup {
                    optionButtons()
                }
            } else if noFound {
                VStack(spacing: 8){
                    HStack {
                        Text("News unavailable").font(.headline)
                        Spacer()
                    }
                    Text("This content may have expired. Check your connection to ensure content can be loaded.").font(.caption)
                }
                .frame(width: widthOrHeight(width: true) * 0.55)
                .padding(8)
                .background(.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onTapGesture {
                    popRoot.alertReason = "News not found"
                    popRoot.alertImage = "exclamationmark.magnifyingglass"
                    withAnimation {
                        popRoot.showAlert = true
                    }
                }
            } else {
                LoadingNews().shimmering()
            }
        }
        .onAppear(perform: {
            if currentNews == nil {
                let title = extractNewsVariable(from: fullURL)
                if let title = title {
                    if let first = viewModel.news.first(where: { $0.id == title }) {
                        currentNews = first
                    } else {
                        viewModel.getSingleNews(id: title) { op_news in
                            if let op_news {
                                self.currentNews = op_news
                            } else {
                                noFound = true
                            }
                        }
                    }
                } else {
                    noFound = true
                }
            }
        })
        .sheet(isPresented: $showForward, content: {
            SendProfileView(sendLink: $sendLink)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
        })
    }
    func optionButtons() -> some View {
        VStack(spacing: 10){
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if let id = currentNews?.id {
                    sendLink = "https://hustle.page/news/\(id)/"
                    showForward = true
                }
            }, label: {
                Image(systemName: "paperplane")
                    .frame(width: 18, height: 18)
                    .font(.headline)
                    .padding(8)
                    .background(.gray.opacity(0.2))
                    .clipShape(Circle())
            })
            Button(action: {
                popRoot.alertReason = "News link copied"
                popRoot.alertImage = "link"
                withAnimation {
                    popRoot.showAlert = true
                }
                if let id = currentNews?.id {
                    UIPasteboard.general.string = "https://hustle.page/news/\(id)/"
                }
            }, label: {
                Image(systemName: "link")
                    .frame(width: 18, height: 18)
                    .font(.headline)
                    .padding(8).foregroundStyle(.blue)
                    .background(.gray.opacity(0.2))
                    .clipShape(Circle())
            })
        }
    }
}

func extractNewsVariable(from urlString: String) -> String? {
    let components = urlString.components(separatedBy: "/")

    if let index = components.firstIndex(of: "news"), index + 1 < components.count {
        return components[index + 1]
    }
    
    return nil
}
