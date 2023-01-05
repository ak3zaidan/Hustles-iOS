import CoreLocation
import Foundation
import SwiftUI
import PhotosUI

struct ImageAsset: Identifiable {
    var id: String = UUID().uuidString
    var asset: PHAsset
    var thumbnail: UIImage?
    var assetIndex: Int = -1
}

class UploadShopViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var caption: String = ""
    @Published var price: String = ""
    @Published var zipCode: String = ""
    @Published var tags: [String] = []
    @Published var didUploadShop = false
    @Published var uploadError: String = ""
    @Published var pickedImages: [UIImage] = []
    let service = ShopService()
    
    @Published var fetchedImages: [ImageAsset] = []
    @Published var selectedImages: [ImageAsset] = []
    @Published var pickedImagesIDS: [String] = []
    
    @Published var locationToAdd: String = ""
    
    init(){
        fetchImages()
    }
    
    func uploadShop(promoted: Int, profilePhoto: String?, username: String?, shopPointer: [String]?, userCounry: String?){
        if let country = userCounry, let username = username {
            let final_place = zipCode + " " + country
            CLGeocoder().geocodeAddressString(final_place) { (placemarks, error) in
                guard let placemarks = placemarks, let placemark = placemarks.first, error == nil else {
                    self.uploadError = "Could not find location"
                    return
                }
                let new_state = placemark.administrativeArea ?? ""

                guard let city = placemark.locality else {
                    self.uploadError = "Could not find location"
                    return
                }
                guard let country = placemark.country else {
                    self.uploadError = "Could not find location"
                    return
                }
                if let pointers = shopPointer {
                    if !pointers.contains(country + "," + new_state + "," + city) {
                        self.locationToAdd = country + "," + new_state + "," + city
                    }
                }
                self.service.uploadShop(title: self.title, caption: self.caption, price: self.price, tags: self.tags, images: self.pickedImages, promoted: promoted, city: city, state: new_state, country: country, username: username, profilePhoto: profilePhoto) { success in
                    if success {
                        self.didUploadShop = true
                    } else {
                        self.uploadError = "Could not Upload at this time"
                    }
                }
                if let pointers = shopPointer {
                    if !pointers.contains(country + "," + new_state + "," + city) {
                        self.service.addShopPointer(location: country + "," + new_state + "," + city)
                    }
                } else { self.service.addShopPointer(location: country + "," + new_state + "," + city) }
            }
        } else {
            self.uploadError = "Could not Upload at this time"
        }
    }
    
    func fetchImages(){
        let options = PHFetchOptions()
        options.includeHiddenAssets = false
        options.includeAssetSourceTypes = [.typeUserLibrary]
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        PHAsset.fetchAssets(with: .image, options: options).enumerateObjects { asset, _, _ in
            let imageAsset: ImageAsset = .init(asset: asset)
            self.fetchedImages.append(imageAsset)
        }
    }
    func updateImages() {
        let options = PHFetchOptions()
        options.includeHiddenAssets = false
        options.includeAssetSourceTypes = [.typeUserLibrary]

        let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
 
        options.predicate = NSPredicate(format: "creationDate > %@", oneHourAgo as CVarArg)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchedAssets = PHAsset.fetchAssets(with: .image, options: options)
        
        fetchedAssets.enumerateObjects { asset, _, _ in
            let imageAsset: ImageAsset = .init(asset: asset)
            if !self.fetchedImages.contains(where: { $0.asset == imageAsset.asset }) {
                self.fetchedImages.insert(imageAsset, at: 0)
            }
        }
    }
}
