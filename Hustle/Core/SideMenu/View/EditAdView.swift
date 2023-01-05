import SwiftUI
import Firebase
import Kingfisher
import Lottie

struct EditAdView: View {
    var tweet: Tweet
    @State var newText: String = ""
    @State var newTextError: String = ""
    @State var newLink: String = ""
    @State var newLinkError: String = ""
    @State var newImage: String = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var adImage: Image?
    @StateObject var viewModel = UploadAdViewModel()
    @State private var difference = false
    @State private var success = false
    @State private var showDelete = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack{
            ZStack(alignment: .bottom){
                Color(.orange)
                HStack{
                    Text("Edit Ad")
                        .font(.title2).bold()
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        HStack(spacing: 2){
                            Image(systemName: "chevron.backward")
                                .scaleEffect(1.5)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .frame(width: 15, height: 15)
                            Text("back").font(.subheadline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                    }
                }
                .padding(.horizontal, 25)
                .padding(.bottom, 8)
            }.frame(height: 110)
            ScrollView(){
                HStack(alignment: .bottom){
                    Text("Ad Description")
                        .font(.system(size: 20)).bold()
                        .padding(.top)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Text(newTextError)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.leading, 5)
                        .padding(.bottom, 3)
                    Spacer()
                    Button {
                        newText = tweet.caption
                    } label: {
                        Image(systemName: "repeat")
                            .resizable()
                            .foregroundColor(.blue)
                            .frame(width: 20, height: 20)
                    }
                }.padding(.horizontal, 30)
                TextArea("Enter new desc.", text: $newText)
                    .padding(.leading, 5)
                    .frame(width: 270, height: 100)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(colorScheme == .dark ? .white : .black, lineWidth: 1)
                    }
                    .onChange(of: newText) { _ in
                        newTextError = inputChecker().myInputChecker(withString: newText, withLowerSize: 0, withUpperSize: 300, needsLower: false)
                    }
                HStack(alignment: .bottom){
                    Text("Ad Link")
                        .font(.system(size: 20)).bold()
                        .padding(.top)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Text(newLinkError)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.leading, 5)
                        .padding(.bottom, 3)
                    Spacer()
                    Button {
                        newLink = tweet.web ?? ""
                    } label: {
                        Image(systemName: "repeat")
                            .resizable()
                            .foregroundColor(.blue)
                            .frame(width: 20, height: 20)
                    }
                }.padding(.horizontal, 30)
                TextField("Enter a new link", text: $newLink)
                    .tint(.blue)
                    .padding(.leading, 8)
                    .frame(width: 270, height: 45)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(colorScheme == .dark ? .white : .black, lineWidth: 1)
                    }
                    .onChange(of: newLink) { _ in
                        newLinkError = inputChecker().myInputChecker(withString: newLink, withLowerSize: 1, withUpperSize: 100, needsLower: false)
                        if let url = URL(string: newLink), UIApplication.shared.canOpenURL(url) {
                            
                        } else {
                            newLinkError = "invalid link"
                        }
                        if newLink.isEmpty{
                            newLinkError = ""
                        }
                    }
                HStack(alignment: .bottom){
                    Text("Ad Image")
                        .font(.system(size: 20)).bold()
                        .padding(.top)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    if newImage == "" && adImage == nil {
                        Button {
                            showImagePicker.toggle()
                        } label: {
                            HStack(spacing: 3){
                                Text("Add photo")
                                    .font(.caption).bold()
                                    .foregroundColor(.blue)
                                Image(systemName: "plus")
                                    .resizable()
                                    .foregroundColor(.blue)
                                    .frame(width: 13, height: 13)
                            }
                        }
                        .padding(.bottom, 3)
                        .padding(.leading)
                    }
                    Spacer()
                }.padding(.leading, 30)
                if newImage != "" && adImage == nil {
                    HStack(spacing: 20){
                        Button {
                            showImagePicker.toggle()
                        } label: {
                            KFImage(URL(string: newImage))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 125, height: 125)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .padding(.top, 5)
                        .padding(.leading, 10)
                        HStack{
                            Image(systemName: "pencil").foregroundColor(colorScheme == .dark ? .white : .black)
                            Text("Tap pic to replace")
                                .font(.subheadline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Spacer()
                        }
                        Spacer()
                    }.padding(.leading, 20)
                }
                if let adImage = adImage {
                    HStack(spacing: 20){
                        Button {
                            showImagePicker.toggle()
                        } label: {
                            adImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 125, height: 125)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .gesture(DragGesture(minimumDistance: 20, coordinateSpace: .global)
                                    .onEnded { value in
                                        selectedImage = nil
                                        self.adImage = nil
                                    })
                        }
                        .padding(.top, 5)
                        .padding(.leading, 10)
                        VStack(spacing: 10){
                            HStack{
                                Image(systemName: "pencil")
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                Text("Tap pic to replace")
                                    .font(.subheadline)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                Spacer()
                            }
                            HStack{
                                Image(systemName: "pencil")
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                Text("swipe to delete")
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .font(.subheadline)
                                Spacer()
                            }
                        }
                        Spacer()
                    }.padding(.leading, 20)
                }
                if success {
                    Text("Allow 5 minuites for update")
                        .font(.subheadline).bold()
                        .padding(.top, 50)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { _ in
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                        let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                            keyWindow.endEditing(true)
                        }
                    }
            )
            ZStack(alignment: .center){
                Button {
                    showDelete.toggle()
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                    let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                        keyWindow.endEditing(true)
                    }
                } label: {
                    Text("Delete")
                        .bold()
                        .padding(.horizontal, 30)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray))
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .clipShape(Capsule())
                        .shadow(color: .gray.opacity(0.6), radius: 10, x: 0, y: 0)
                }.offset(x: -80)
                Button {
                    if difference && newLinkError.isEmpty && newTextError.isEmpty {
                        if newText != tweet.caption {
                            viewModel.editAdBody(body: newText, adId: tweet.id ?? "")
                            success = true
                            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                success = false
                            }
                        }
                        if newLink != tweet.web {
                            viewModel.editAdLink(link: newLink, adId: tweet.id ?? "")
                            success = true
                            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                success = false
                            }
                        }
                        if let image = selectedImage {
                            viewModel.editAdImage(image: image, adId: tweet.id ?? "", oldImage: tweet.image)
                            selectedImage = nil
                            adImage = nil
                            success = true
                            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                success = false
                            }
                        }
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                        let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                            keyWindow.endEditing(true)
                        }
                    }
                } label: {
                    if !success{
                        Text("Update")
                            .bold()
                            .padding(.horizontal, 30)
                            .padding(.vertical, 8)
                            .background(Color( (difference && newLinkError.isEmpty && newTextError.isEmpty) ? .systemBlue : .systemGray))
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .clipShape(Capsule())
                            .shadow(color: .gray.opacity(0.6), radius: 10, x: 0, y: 0)
                    } else {
                        LottieView(loopMode: .playOnce, name: "image_success")
                            .frame(width: 60, height: 60)
                            .padding(.leading)
                    }
                }.offset(x: 80)
            }.padding(.bottom, 50)
        }
        .padding(.bottom, 40)
        .alert("Are you sure you want to delete this ad? You will NOT be granted a refund.", isPresented: $showDelete) {
            Button("Confirm", role: .destructive) {
                viewModel.deleteAds(adId: tweet.id ?? "", adImage: tweet.image)
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .onAppear{
            newText = tweet.caption
            newLink = tweet.web ?? ""
            newImage = tweet.image ?? ""
            newTextError = ""
            newLinkError = ""
        }
        .sheet(isPresented: $showImagePicker, onDismiss: loadImage){
            ImagePicker(selectedImage: $selectedImage)
                .tint(.black)
        }
        .onChange(of: newText) { _ in
            if newText != tweet.caption {
                difference = true
            } else if newLink == tweet.web && adImage == nil {
                difference = false
            }
        }
        .onChange(of: newLink) { _ in
            if newLink != (tweet.web ?? "") {
                difference = true
            } else if newText == tweet.caption && adImage == nil {
                difference = false
            }
        }
        .onChange(of: adImage) { _ in
            if adImage != nil {
                difference = true
            } else if newText == tweet.caption && newLink == (tweet.web ?? "") {
                difference = false
            }
        }
        .onChange(of: success) { _ in
            if !success{
                newTextError = ""
                newLinkError = ""
            }
        }
    }
    func loadImage() {
        guard let selectedImage = selectedImage else {return}
        adImage = Image(uiImage: selectedImage)
    }
}
