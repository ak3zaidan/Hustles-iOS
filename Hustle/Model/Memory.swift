import Firebase
import FirebaseFirestoreSwift
import AVFoundation

struct Memory: Identifiable, Decodable, Equatable, Hashable {
    @DocumentID var id: String?
    var image: String?
    var video: String?
    var lat: CGFloat?
    var long: CGFloat?
    var createdAt: Timestamp
}

struct MemoryMonths: Identifiable {
    var id = UUID().uuidString
    var date: String
    var allMemories: [animatableMemory]
}

struct MemoryHighLight: Identifiable {
    var id = UUID().uuidString
    var firstMemory: animatableMemory
    var allMemories: [animatableMemory]
    var highlightSentence: String
}

struct animatableMemory: Identifiable, Equatable {
    var id = UUID().uuidString
    var isImage: Bool
    var thumbnail: UIImage?
    var player: AVPlayer?
    var offset: CGSize = .zero
    var playVideo: Bool = false
    var memory: Memory
}

struct MemorySelectionReturn {
    var isImage: Bool
    var urlString: String
}
