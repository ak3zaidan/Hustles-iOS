import SwiftUI
import Kingfisher

//#Preview {
//    Home()
//}

struct Home: View {
    @State private var posts: [Post] = samplePosts
    @State private var showDetailView: Bool = false
    @State private var detailViewAnimation: Bool = false
    @State private var selectedPicID: UUID?
    @State private var selectedPost: Post?
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 15) {
                ForEach(posts) { post in
                    CardView(post)
                }
            }
        }
        .overlay {
            if let selectedPost, showDetailView {
                DetailView(
                    showDetailView: $showDetailView,
                    detailViewAnimation: $detailViewAnimation,
                    post: selectedPost,
                    selectedPicID: $selectedPicID
                ) { id in
                    if let index = posts.firstIndex(where: { $0.id == selectedPost.id }) {
                        posts[index].scrollPosition = id
                    }
                }
                .transition(.offset(y: 5))
            }
        }
        .overlayPreferenceValue(OffsetKey2.self, { value in
            GeometryReader { proxy in
                if let selectedPicID, let source = value[selectedPicID.uuidString], let destination = value["DESTINATION\(selectedPicID.uuidString)"], let picItem = selectedImage(), showDetailView {
                    let sRect = proxy[source]
                    let dRect = proxy[destination]
                    
                    KFImage(URL(string: picItem.image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: detailViewAnimation ? dRect.width : sRect.width, height: detailViewAnimation ? dRect.height : sRect.height)
                        .clipShape(.rect(cornerRadius: detailViewAnimation ? 0 : 10))
                        .offset(x: detailViewAnimation ? dRect.minX : sRect.minX, y: detailViewAnimation ? dRect.minY : sRect.minY)
                        .allowsHitTesting(false)
                }
            }
        })
    }
    
    func selectedImage() -> PicItem? {
        if let pic = selectedPost?.pics.first(where: { $0.id == selectedPicID }) {
            return pic
        }
        return nil
    }

    @ViewBuilder
    func CardView(_ post: Post) -> some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {
                GeometryReader {
                    let size = $0.size
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(post.pics) { pic in
                                LazyHStack {
                                    KFImage(URL(string: pic.image))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxWidth: size.width)
                                        .clipShape(.rect(cornerRadius: 10))
                                }
                                .frame(maxWidth: size.width)
                                .frame(height: size.height)
                                .anchorPreference(key: OffsetKey2.self, value: .bounds, transform: { anchor in
                                    return [pic.id.uuidString: anchor]
                                })
                                .onTapGesture {
                                    selectedPost = post
                                    selectedPicID = pic.id
                                    showDetailView = true
                                }
                                .contentShape(.rect)
                                .opacity(selectedPicID == pic.id ? 0 : 1)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollPosition(id: .init(get: {
                        return post.scrollPosition
                    }, set: { _ in
                        
                    }))
                    .scrollIndicators(.hidden)
                    .scrollTargetBehavior(.viewAligned)
                    .scrollClipDisabled()
                }
                .frame(height: 200)
            }
            .safeAreaPadding(.leading, 45)
        }
    }
    
    @ViewBuilder
    func ImageButton(_ icon: String, onTap: @escaping () -> ()) -> some View {
        Button("", systemImage: icon, action: onTap)
            .font(.title3)
            .foregroundStyle(.primary)
    }
}

struct DetailView: View {
    @Binding var showDetailView: Bool
    @Binding var detailViewAnimation: Bool
    var post: Post
    @Binding var selectedPicID: UUID?
    var updateScrollPosition: (UUID?) -> ()
    @State private var detailScrollPosition: UUID?
    @State private var startTask1: DispatchWorkItem?
    @State private var startTask2: DispatchWorkItem?
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(post.pics) { pic in
                    KFImage(URL(string: pic.image))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .containerRelativeFrame(.horizontal)
                        .clipped()
                        .anchorPreference(key: OffsetKey2.self, value: .bounds, transform: { anchor in
                            return ["DESTINATION\(pic.id.uuidString)": anchor]
                        })
                        .opacity(selectedPicID == pic.id ? 0 : 1)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $detailScrollPosition)
        .background(.black)
        .opacity(detailViewAnimation ? 1 : 0)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .overlay(alignment: .topLeading) {
            Button("", systemImage: "xmark.circle.fill") {
                cancelTasks()
                
                updateScrollPosition(detailScrollPosition)
                selectedPicID = detailScrollPosition
                initiateTask(ref: &startTask1, task: .init(block: {
                    withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                        detailViewAnimation = false
                    }
                    initiateTask(ref: &startTask2, task: .init(block: {
                        showDetailView = false
                        selectedPicID = nil
                    }), duration: 0.3)
                    
                }), duration: 0.05)
            }
            .font(.title)
            .foregroundStyle(.white.opacity(0.8), .white.opacity(0.15))
            .padding()
        }
        .onAppear {
            guard detailScrollPosition == nil else { return }
            cancelTasks()
            detailScrollPosition = selectedPicID
            initiateTask(ref: &startTask1, task: .init(block: {
                withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                    detailViewAnimation = true
                }

                initiateTask(ref: &startTask2, task: .init(block: {
                    selectedPicID = nil
                }), duration: 0.3)
                
            }), duration: 0.05)
        }
    }
    
    func initiateTask(ref: inout DispatchWorkItem?, task: DispatchWorkItem, duration: CGFloat) {
        ref = task
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
    }

    func cancelTasks() {
        if let startTask1, let startTask2 {
            startTask1.cancel()
            startTask2.cancel()
            self.startTask1 = nil
            self.startTask2 = nil
        }
    }
}

struct OffsetKey2: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String : Anchor<CGRect>], nextValue: () -> [String : Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

struct PicItem: Identifiable {
    let id: UUID = .init()
    var image: String
}

struct Post: Identifiable {
    let id: UUID = .init()
    var username: String
    var content: String
    var pics: [PicItem]
    var scrollPosition: UUID?
}

var samplePosts: [Post] = [
    .init(username: "iJustine", content: "Nature Pics", pics: pics),
    .init(username: "Jenna", content: "Reversed Nature Pics", pics: pics1)
]

private var pics: [PicItem] = (1...5).compactMap { index -> PicItem? in
    return .init(image: "https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885_640.jpg")
}

private var pics1: [PicItem] = (1...5).reversed().compactMap { index -> PicItem? in
    return .init(image: "https://images.pexels.com/photos/674010/pexels-photo-674010.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500")
}
