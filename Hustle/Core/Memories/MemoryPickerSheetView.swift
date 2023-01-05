import SwiftUI
import Firebase
import AVFoundation
import Kingfisher

struct MemoryPickerSheetView: View {
    @EnvironmentObject var viewModel: PopToRoot
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State var maxReached: Bool = false
    @State var selected: [animatableMemory] = []
    @State var limitQuery: Bool = false
    @State var scrollViewSize: CGSize = .zero
    @State var wholeSize: CGSize = .zero
    let photoOnly: Bool
    let maxSelect: Int
    let done: ([MemorySelectionReturn]) -> Void
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .bottom){
                    ChildSizeReader(size: $wholeSize) {
                        ScrollView {
                            if viewModel.allMemories.isEmpty {
                                Color.clear.frame(height: 40)
                                if viewModel.noMoreMemories {
                                    VStack {
                                        Image("memory")
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                        Text("Your memories will appear here!")
                                            .font(.headline)
                                    }
                                } else {
                                    VStack {
                                        LottieView(loopMode: .loop, name: "placeLoader")
                                            .frame(width: 85, height: 85)
                                            .scaleEffect(0.7)
                                        Text("Fetching Memories..")
                                            .font(.headline)
                                    }
                                }
                            }
                            ChildSizeReader(size: $scrollViewSize) {
                                LazyVGrid(columns: Array(repeating: GridItem(spacing: 19), count: 3), spacing: 3) {
                                    ForEach(viewModel.allMemories) { element in
                                        ForEach(element.allMemories) { single in
                                            if (photoOnly && single.isImage) || !photoOnly {
                                                CardViewSelectMemory(videoFile: single)
                                                    .frame(width: (geo.size.width / 3.0) + 3, height: 190)
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        withAnimation(.easeInOut(duration: 0.1)){
                                                            if let idx = selected.firstIndex(where: { $0.id == single.id }) {
                                                                selected.remove(at: idx)
                                                            } else {
                                                                if selected.count < maxSelect {
                                                                    selected.append(single)
                                                                } else {
                                                                    maxReached = true
                                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4){
                                                                        withAnimation(.easeInOut(duration: 0.1)){
                                                                            maxReached = false
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    .overlay(alignment: .bottomTrailing){
                                                        if let idx = selected.firstIndex(where: { $0.id == single.id }) {
                                                            Circle()
                                                                .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                                                                .frame(width: 24, height: 24)
                                                                .padding(12)
                                                                .overlay {
                                                                    Text("\(idx + 1)")
                                                                        .foregroundStyle(.white).bold()
                                                                        .font(.subheadline)
                                                                }
                                                        } else {
                                                            Circle()
                                                                .stroke(.white, lineWidth: 1.0)
                                                                .frame(width: 24, height: 24)
                                                                .padding(12)
                                                        }
                                                    }
                                            }
                                        }
                                    }
                                }
                                .onPreferenceChange(ViewOffsetKey.self) { value in
                                    if value > (scrollViewSize.height - wholeSize.height) - 350 && limitQuery && !viewModel.noMoreMemories {
                                        limitQuery = false
                                        fetchData()
                                    }
                                }
                            }
                            if !viewModel.allMemories.isEmpty && !viewModel.noMoreMemories {
                                LottieView(loopMode: .loop, name: "placeLoader")
                                    .frame(width: 85, height: 85)
                                    .scaleEffect(0.5)
                                    .padding(.top, 15)
                            }
                            Color.clear.frame(height: 30)
                        }
                    }
                    if !self.selected.isEmpty {
                        Button(action: {
                            var finalSend = [MemorySelectionReturn]()
                            selected.forEach { element in
                                finalSend.append(MemorySelectionReturn(isImage: element.isImage, urlString: (element.isImage ? element.memory.image : element.memory.video) ?? ""))
                            }
                            done(finalSend)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            dismiss()
                        }, label: {
                            HStack(spacing: 8){
                                Text("Attach").font(.headline)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 30).padding(.vertical, 10)
                            .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                            .clipShape(Capsule())
                            .shadow(color: .gray, radius: 4)
                        })
                        .transition(.move(edge: .bottom))
                        .animation(.easeInOut(duration: 0.3), value: selected)
                        .padding(.bottom, 70)
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationBarBackButtonHidden(true)
            .navigationTitle("Select Memories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(selected.count)/\(maxSelect)")
                        .scaleEffect(maxReached ? 1.3 : 1.0)
                        .foregroundStyle(maxReached ? .red : (colorScheme == .dark ? .white : .black))
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel").foregroundStyle(.blue)
                    }
                }
            })
        }
        .presentationDetents([.medium, .fraction(0.999)])
        .presentationDragIndicator(.hidden)
        .onAppear {
            if viewModel.allMemories.isEmpty || (viewModel.allMemories.count == 1 && (viewModel.allMemories.first?.date ?? "") == "Recents"){
                fetchData()
            } else {
                limitQuery = true
            }
        }
    }
    func fetchData(){
        var last: Timestamp? = nil
        if let check = viewModel.allMemories.last {
            last = check.allMemories.last?.memory.createdAt
        }
        
        UserService().getMemories(after: last) { memories in
            if memories.count < 28 {
                viewModel.noMoreMemories = true
            }
            limitQuery = true
            if memories.isEmpty {
                return
            }
            var tupiles: [(String, Memory)] = []
            memories.forEach { element in
                tupiles.append((formatFirebaseTimestampToMonthYear(element.createdAt), element))
            }
            tupiles.forEach { element in
                var new = animatableMemory(isImage: element.1.image != nil, memory: element.1)
                if let video = element.1.video, let url = URL(string: video) {
                    new.player = AVPlayer(url: url)
                }
                
                if let idxAdd = viewModel.allMemories.firstIndex(where: { $0.date == element.0 }) {
                    viewModel.allMemories[idxAdd].allMemories.append(new)
                } else {
                    let newMonth = MemoryMonths(date: element.0, allMemories: [new])
                    viewModel.allMemories.append(newMonth)
                }
            }
        }
    }
}

struct CardViewSelectMemory: View {
    private let screenSize = UIScreen.main.bounds
    @State var videoFile: animatableMemory
    
    var body: some View {
        GeometryReader {
            let size = $0.size

            if let imageURL = videoFile.memory.image {
                KFImage(URL(string: imageURL))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(Rectangle())
                    .overlay {
                        Rectangle().stroke(.gray, lineWidth: 1.0)
                    }
                    .background(content: {
                        Rectangle()
                            .foregroundColor(.gray).opacity(0.2)
                            .overlay(content: {
                                ProgressView().scaleEffect(1.2)
                            })
                    })
                    .clipShape(Rectangle())
            } else if let thumbnail = videoFile.thumbnail, let player = videoFile.player {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .opacity(videoFile.playVideo ? 0 : 1)
                    .frame(width: size.width, height: size.height)
                    .overlay {
                        VStack(alignment: .leading){
                            Spacer()
                            HStack {
                                Text(formatDuration(player.currentItem?.duration))
                                    .foregroundStyle(.white)
                                    .font(.subheadline).fontWeight(.medium)
                                Spacer()
                            }
                        }.padding(10)
                    }
                    .clipShape(Rectangle())
            } else {
                Rectangle()
                    .foregroundColor(.gray).opacity(0.2)
                    .overlay(content: {
                        ProgressView().scaleEffect(1.2)
                    })
                    .onAppear {
                        if let f_url = videoFile.memory.video, let url = URL(string: f_url) {
                            extractImageAt(f_url: url, time: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)) { thumbnail in
                                videoFile.thumbnail = thumbnail
                            }
                        }
                    }
            }
        }
    }
}

func formatFirebaseTimestampToMonthYear(_ timestamp: Timestamp) -> String {
    let date = timestamp.dateValue()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMMM yyyy"
    let formattedDate = dateFormatter.string(from: date)
    return formattedDate
}

func reformatDateString(_ dateString: String) -> String {
    let inputFormatter = DateFormatter()
    inputFormatter.dateFormat = "MMMM yyyy"
    guard let date = inputFormatter.date(from: dateString) else {
        return dateString
    }
    let outputFormatter = DateFormatter()
    outputFormatter.dateFormat = "MMM yyyy"
    let formattedDate = outputFormatter.string(from: date)
    return formattedDate
}
