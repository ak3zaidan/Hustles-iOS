import Foundation
import SwiftUI
import Firebase

class UploadAdViewModel: ObservableObject{
    @Published var myAds = [Tweet]()
    @Published var didUploadAd = false
    @Published var uploadError = ""
    var deletedAds: [String] = []
    let service = AdService()
    let userService = UserService()
    
    func uploadAd(caption: String, start: Date, end: Date, webLink: String?, appName: String?, image: UIImage?, plus: Bool, photo: String, username: String, video: String){
        let link = inputChecker().getLink(videoLink: video)
        self.service.uploadAd(caption: caption, start: start, end: end, webLink: webLink, appName: appName, image: image, plus: plus, photo: photo, username: username, videoURL: link) { success in
            if success {
                self.didUploadAd = true
            } else {
                self.uploadError = "error"
            }
        }
    }
    func getAds(){
        service.getAds { ads in
            self.myAds = ads
        }
    }
    func editAdBody(body: String, adId: String){
        if !deletedAds.contains(adId) {
            let data = ["caption": body]
            Firestore.firestore().collection("ads").document(adId).updateData(data) { _ in }
        }
    }
    func editAdImage(image: UIImage, adId: String, oldImage: String?){
        if !deletedAds.contains(adId) {
            ImageUploader.uploadImage(image: image, location: "ads", compression: 0.5) { newImageUrl, _ in
                let data = ["image": newImageUrl]
                Firestore.firestore().collection("ads").document(adId).updateData(data) { _ in }
            }
            if let old = oldImage {
                ImageUploader.deleteImage(fileLocation: old) { _ in }
            }
        }
    }
    func editAdLink(link: String, adId: String){
        if !deletedAds.contains(adId) {
            if !link.isEmpty && !link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let data = ["web": link]
                Firestore.firestore().collection("ads").document(adId).updateData(data) { _ in }
            }
        }
    }
    func deleteAds(adId: String, adImage: String?){
        deletedAds.append(adId)
        Firestore.firestore().collection("ads").document(adId)
            .delete()
        if let old = adImage {
            ImageUploader.deleteImage(fileLocation: old) { _ in }
        }
    }
}
