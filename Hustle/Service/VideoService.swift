import Firebase
import Foundation

struct Max: Decodable {
    var max: Int
}

struct VideoService {
    let db = Firestore.firestore()
    
    func getBatch(category: String, randNum: Int, completion: @escaping(VideoBatch) -> Void) {
        let num = String(randNum)
        if !category.isEmpty && !num.isEmpty {
            db.collection("videos").document(category).collection("videos").document(num)
                .getDocument { snapshot, _ in
                    guard let snapshot = snapshot else { return }
                    guard let vid = try? snapshot.data(as: VideoBatch.self) else { return }
                    completion(vid)
                }
        }
    }
    func delete(id: String, category: String, docID: String){
        db.collection("videos").document(category).collection("videos").document(docID)
            .updateData(["videos": FieldValue.arrayRemove([id])]) { _ in }
    }
    func getMax(completion: @escaping(Int) -> Void) {
        db.collection("videos").document("max")
            .getDocument { snapshot, _ in
                guard let snapshot = snapshot else { return }
                guard let max = try? snapshot.data(as: Max.self) else { return }
                completion(max.max)
            }
        
    }
}
