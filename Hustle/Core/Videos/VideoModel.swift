import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Video: Identifiable, Equatable {
    var id: String
    var category: String
    var videoID: String
    var liked: Bool
    var unliked: Bool
    var likesCount: Int = Int.random(in: 0...10000)
    var dislikesCount: Int = Int.random(in: 0...300)
}
struct VideoBatch: Identifiable, Equatable, Decodable {
    @DocumentID var id: String?
    var category: String?
    var videos: [String]
}

class VideoModel: ObservableObject {
    let service = VideoService()
    @Published var avoid = [String]()
    @Published var increase = [String]()
    var tags =  ["Math", "Science", "Business", "Ethics", "Interesting", "Tech", "Fitness"]
    @Published var VideosToShow = [Video]()
    @Published var batches = [VideoBatch]()
    @Published var fetched: [(String, [Int])] = []
    @Published var selected = ""
    @Published var maxFetchable = 0

    func getBatch(_ categoryName: String){
        if categoryName.isEmpty {
            var tempArr = tags.filter { tag in
                !avoid.contains(tag)
            }
            increase.forEach { tag in
                tempArr.append(tag)
                tempArr.append(tag)
                tempArr.append(tag)
                tempArr.append(tag)
            }
            if let element = tempArr.randomElement() {
                getBatch(element)
            } else {
                getBatch("Science")
            }
        } else {
            var max = 50
            if maxFetchable > 50 {
                max = maxFetchable
            } else if maxFetchable == 0 {
                getMax()
            }
            let randomPriorityThreshold = 0.6
            let randomValue = Double.random(in: 0..<1)
            if let index = fetched.firstIndex(where: { $0.0 == categoryName }){
                var final_number: Int
                if randomValue < randomPriorityThreshold {
                    final_number = generateRandomNumberInRange(from: 1, to: max, avoiding: fetched[index].1)
                } else {
                    let topHalfStart = Int(Double(max) * 0.5) + 1
                    final_number = generateRandomNumberInRange(from: topHalfStart, to: max, avoiding: fetched[index].1)
                }
                fetched[index].1.append(final_number)
                service.getBatch(category: categoryName, randNum: final_number) { videos in
                    var temp = videos
                    temp.category = categoryName
                    self.batches.append(temp)
                    let idArr = videos.videos.shuffled()
                    
                    var holderArr: [Video] = []
                    idArr.forEach { id in
                        let additive_id = id + String("\(UUID())".prefix(4))
                        let new = Video(id: "\(UUID())", category: categoryName, videoID: additive_id, liked: false, unliked: false)
                        holderArr.append(new)
                        if self.selected.isEmpty {
                            self.selected = additive_id
                        }
                    }
                    self.VideosToShow.append(contentsOf: holderArr)
                }
            } else {
                var final_number: Int
                if randomValue < randomPriorityThreshold {
                    final_number = Int.random(in: 1...max)
                } else {
                    let topHalfStart = Int(Double(max) * 0.5) + 1
                    final_number = Int.random(in: topHalfStart...max)
                }
                fetched.append((categoryName, [final_number]))
                service.getBatch(category: categoryName, randNum: final_number) { videos in
                    var temp = videos
                    temp.category = categoryName
                    self.batches.append(temp)
                    let idArr = videos.videos.shuffled()
                    
                    var holderArr: [Video] = []
                    idArr.forEach { id in
                        let additive_id = id + String("\(UUID())".prefix(4))
                        let new = Video(id: "\(UUID())", category: categoryName, videoID: additive_id, liked: false, unliked: false)
                        holderArr.append(new)
                        if self.selected.isEmpty {
                            self.selected = additive_id
                        }
                    }
                    self.VideosToShow.append(contentsOf: holderArr)
                }
            }
        }
    }
    func deleteVid(){
        let realID = String(selected.dropLast(4))
        if let element = batches.first(where: { $0.videos.contains(realID) }) {
            if let category = element.category, let docID = element.id {
                service.delete(id: realID, category: category, docID: docID)
            }
        }
    }
    func getMax(){
        if maxFetchable == 0 {
            service.getMax { num in
                self.maxFetchable = num
            }
        }
    }
    func generateRandomNumberInRange(from lowerBound: Int, to upperBound: Int, avoiding avoid: [Int]) -> Int {
        let validNumbers = Set(lowerBound...upperBound).subtracting(avoid)
        
        if validNumbers.isEmpty {
            if maxFetchable > 50 {
                return Int.random(in: 1...maxFetchable)
            } else {
                return Int.random(in: 1...50)
            }
        }

        let randomIndex = Int.random(in: 0..<validNumbers.count)
        let randomValidNumber = validNumbers[validNumbers.index(validNumbers.startIndex, offsetBy: randomIndex)]
        
        return randomValidNumber
    }
}
