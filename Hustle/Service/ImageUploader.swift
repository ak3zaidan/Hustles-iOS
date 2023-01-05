import Firebase
import UIKit
import FirebaseStorage

struct ImageUploader {
    static func uploadFile(data: Data, location: String, fileExtension: String, completion: @escaping (String) -> Void) {
        let ref = Storage.storage().reference(withPath: "/\(location)/\(NSUUID().uuidString).\(fileExtension)")
        ref.putData(data, metadata: nil) { metadata, error in
            if let err = error {
                print(err)
            }
            ref.downloadURL { (url, error) in
                guard let downloadURL = url?.absoluteString else {
                    completion("")
                    return
                }
                completion(downloadURL)
            }
        }
    }
    static func uploadImage(image: UIImage, location: String, compression: Double, completion: @escaping(String, Bool) -> Void){
        guard let imageData = image.jpegData(compressionQuality: compression) else { return }
        
        let filename = NSUUID().uuidString
        let ref = Storage.storage().reference(withPath: "/\(location)/\(filename)")
    
        ref.putData(imageData, metadata: nil) { _, error in
            if error != nil {
                completion("", false)
                return
            }
            ref.downloadURL { imageUrl, _ in
                guard let imageUrl = imageUrl?.absoluteString else {
                    completion("", false)
                    return
                }
                completion(imageUrl, true)
            }
        }
    }
    static func uploadMultipleImages(images: [UIImage], location: String, compression: Double, completion: @escaping([String]) -> Void){
        var urlArr: [String] = []
        
        images.forEach { image in
            guard let imageData = image.jpegData(compressionQuality: compression) else { return }
            
            let filename = NSUUID().uuidString
            let ref = Storage.storage().reference(withPath: "/\(location)/\(filename)")
        
            ref.putData(imageData, metadata: nil) { _, _ in
                ref.downloadURL { imageUrl, _ in
                    if let imageUrl = imageUrl?.absoluteString {
                        urlArr.append(imageUrl)
                        if urlArr.count == images.count {
                            urlArr.removeAll(where: { $0.isEmpty })
                            completion(urlArr)
                        }
                    } else {
                        urlArr.append("")
                        if urlArr.count == images.count {
                            urlArr.removeAll(where: { $0.isEmpty })
                            completion(urlArr)
                        }
                    }
                }
            }
        }
    }
    static func uploadMultipleVideos(videos: [URL], location: String, compression: Double, completion: @escaping([String]) -> Void){
        var urlArr: [String] = []

        videos.forEach { vid in
            uploadVideoToFirebaseStorage(localVideoURL: vid) { new in
                if let url = new, !url.isEmpty {
                    urlArr.append(url)
                    if urlArr.count == videos.count {
                        urlArr.removeAll(where: { $0.isEmpty })
                        completion(urlArr)
                    }
                } else {
                    urlArr.append("")
                    if urlArr.count == videos.count {
                        urlArr.removeAll(where: { $0.isEmpty })
                        completion(urlArr)
                    }
                }
            }
        }
    }
    static func uploadVideoToFirebaseStorage(localVideoURL: URL, completion: @escaping (String?) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()

        let videoRef = storageRef.child("stories/\(UUID().uuidString).mp4")

        videoRef.putFile(from: localVideoURL, metadata: nil) { metadata, error in
            if metadata == nil {
                completion(nil)
                return
            }
            videoRef.downloadURL { url, error in
                if let downloadURL = url {
                    completion(downloadURL.absoluteString)
                } else {
                    completion(nil)
                }
            }
        }
    }
    static func uploadVideoToFB(localVideoURL: URL, completion: @escaping (String?) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()

        let videoRef = storageRef.child("hustlesVideos/\(UUID().uuidString).mp4")

        videoRef.putFile(from: localVideoURL, metadata: nil) { metadata, error in
            if metadata == nil {
                completion(nil)
                return
            }
            videoRef.downloadURL { url, error in
                if let downloadURL = url {
                    completion(downloadURL.absoluteString)
                } else {
                    completion(nil)
                }
            }
        }
    }
    static func uploadAudioToFirebaseStorage(localURL: URL, completion: @escaping (String?) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()

        let videoRef = storageRef.child("audio/\(UUID().uuidString)")//.m4a

        videoRef.putFile(from: localURL, metadata: nil) { metadata, error in
            if metadata == nil {
                completion(nil)
                return
            }
            videoRef.downloadURL { url, error in
                if let downloadURL = url {
                    completion(downloadURL.absoluteString)
                } else {
                    completion(nil)
                }
            }
        }
    }
    static func deleteImage(fileLocation: String, completion: @escaping (Error?) -> Void) {
        let storageRef = Storage.storage().reference(forURL: fileLocation)
        
        storageRef.delete { error in
            completion(error)
        }
    }
}
