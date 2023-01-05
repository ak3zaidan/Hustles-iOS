import CoreLocation
import Foundation
import SwiftUI

class UploadJobViewModel: ObservableObject{
    @Published var caption: String = ""
    @Published var zipCode: String = ""
    @Published var title: String = ""
    @Published var link: String = ""
    @Published var selected: Bool = false
    @Published var didUploadJob = false
    @Published var uploadError: String = ""
    let service = JobService()
    @Published var locationToAdd: String = ""
    
    func uploadJobImage(withImage image: UIImage?, withPro promoted: Int, photo: String, username: String, jobPointer: [String], userCounry: String){
        if selected == true {
            self.locationToAdd = "remote"
            self.service.uploadJobImage(caption: caption, title: title, city: "", state: "", remote: selected, image: image, promoted: promoted, link: link, photo: photo, username: username, country: "") { success in
                if success {
                    self.didUploadJob = true
                } else {
                    self.uploadError = "Could not Upload at this time"
                }
            }
            if !jobPointer.contains("remote") {
                self.service.addJobPointer(location: "remote")
            }
        } else {
            let final_place = zipCode + " " + userCounry
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
                if !jobPointer.contains(country + "," + new_state + "," + city) {
                    self.locationToAdd = country + "," + new_state + "," + city
                }
                self.service.uploadJobImage(caption: self.caption, title: self.title, city: city, state: new_state, remote: self.selected, image: image, promoted: promoted, link: self.link, photo: photo, username: username, country: country) { success in
                    if success {
                        self.didUploadJob = true
                    } else {
                        self.uploadError = "Could not Upload at this time"
                    }
                }
                if !jobPointer.contains(country + "," + new_state + "," + city) {
                    self.service.addJobPointer(location: country + "," + new_state + "," + city)
                }
            }
        }
    }
    func isValidZipCode(_ zipCode: String) -> Bool {
        let trimmedZipCode = zipCode.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedZipCode.isEmpty
    }
}
