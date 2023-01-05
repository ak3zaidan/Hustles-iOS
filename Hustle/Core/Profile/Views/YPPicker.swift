import YPImagePicker
import SwiftUI

struct ImagePickerViewMessage: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var selectedVideoURL: URL?
    @Binding var isImagePickerPresented: Bool

    func makeUIViewController(context: Context) -> YPImagePicker {
        var config = YPImagePickerConfiguration()
        config.screens = [.library]
        config.library.mediaType = .photoAndVideo
        config.video.recordingTimeLimit = 120.0
        config.albumName = "Hustles"
        config.shouldSaveNewPicturesToAlbum = false
        
        let picker = YPImagePicker(configuration: config)

        picker.didFinishPicking { items, cancelled in
            if !cancelled {
                if let photo = items.singlePhoto {
                    self.selectedImage = photo.image
                } else if let video = items.singleVideo {
                    self.selectedVideoURL = video.url
                }
            }
            self.isImagePickerPresented = false
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: YPImagePicker, context: Context) { }
}

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var selectedVideoURL: URL?
    @Binding var isImagePickerPresented: Bool
    @Binding var showPreviewSec: Bool

    func makeUIViewController(context: Context) -> YPImagePicker {
        var config = YPImagePickerConfiguration()
        config.screens = [.library]
        config.library.mediaType = .photoAndVideo
        config.video.recordingTimeLimit = 60.0
        config.albumName = "Hustles"
        config.shouldSaveNewPicturesToAlbum = false
        
        let picker = YPImagePicker(configuration: config)

        picker.didFinishPicking { items, cancelled in
            if !cancelled {
                if let photo = items.singlePhoto {
                    self.selectedImage = photo.image
                } else if let video = items.singleVideo {
                    self.selectedVideoURL = video.url
                    self.showPreviewSec = true
                }
            }
            self.isImagePickerPresented = false
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: YPImagePicker, context: Context) { }
}

struct ImagePickerViewSec: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isImagePickerPresented: Bool

    func makeUIViewController(context: Context) -> YPImagePicker {
        var config = YPImagePickerConfiguration()
        config.screens = [.library]
        config.library.mediaType = .photo
        config.video.recordingTimeLimit = 60.0
        config.albumName = "Hustles"
        config.shouldSaveNewPicturesToAlbum = false
        
        let picker = YPImagePicker(configuration: config)

        picker.didFinishPicking { items, cancelled in
            if !cancelled {
                if let photo = items.singlePhoto {
                    self.selectedImage = photo.image
                }
            }
            self.isImagePickerPresented = false
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: YPImagePicker, context: Context) { }
}

struct HustlePickerViewNew: UIViewControllerRepresentable {
    @Binding var add_content: [uploadContent]
    @Binding var isImagePickerPresented: Bool

    func makeUIViewController(context: Context) -> YPImagePicker {
        var config = YPImagePickerConfiguration()
        config.screens = [.library]
        config.library.mediaType = .photoAndVideo
        config.library.maxNumberOfItems = 10 - add_content.count
        config.video.recordingTimeLimit = 100.0
        config.albumName = "Hustles"
        config.shouldSaveNewPicturesToAlbum = false
        
        let picker = YPImagePicker(configuration: config)

        picker.didFinishPicking { items, cancelled in
            if !cancelled {
                items.forEach { single in
                    switch single {
                    case.photo(p: let photo):
                        if add_content.count < 10 {
                            let sel = photo.image
                            let new_image = Image(uiImage: photo.image)
                            add_content.append(uploadContent(isImage: true, selectedImage: sel, hustleImage: new_image))
                        }
                    case.video(v: let video):
                        if add_content.count < 10 {
                            add_content.append(uploadContent(isImage: false, videoURL: video.url))
                        }
                    }
                }
            }
            self.isImagePickerPresented = false
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: YPImagePicker, context: Context) { }
}

struct HustlePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var hustleImage: Image?
    @Binding var selectedVideoURL: URL?
    @Binding var isImagePickerPresented: Bool
    let canAddVid: Bool

    func makeUIViewController(context: Context) -> YPImagePicker {
        var config = YPImagePickerConfiguration()
        config.screens = [.library]
        if canAddVid {
            config.library.mediaType = .photoAndVideo
        } else {
            config.library.mediaType = .photo
        }
        config.video.recordingTimeLimit = 100.0
        config.albumName = "Hustles"
        config.shouldSaveNewPicturesToAlbum = false
        
        let picker = YPImagePicker(configuration: config)

        picker.didFinishPicking { items, cancelled in
            if !cancelled {
                if let photo = items.singlePhoto {
                    self.selectedImage = photo.image
                    hustleImage = Image(uiImage: photo.image)
                } else if let video = items.singleVideo {
                    self.selectedVideoURL = video.url
                }
            }
            self.isImagePickerPresented = false
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: YPImagePicker, context: Context) { }
}
