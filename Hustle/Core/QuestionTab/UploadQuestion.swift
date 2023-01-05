import SwiftUI
import Kingfisher
import UIKit

class QuestionCategories: ObservableObject {
    var tags: [String] =  ["Business", "Manufacturing", "Marketing" , "CC", "Trademark", "Patent" ,"College", "Real Estate", "Investing", "Ecommerce", "Finance", "Amazon", "Career", "LLC/S-CORP", "Stocks", "Crypto", "Product Dev", "Legal", "technical", "Sales", "Taxes", "professional", "Other"]
}

enum QuestionOption: Int, CaseIterable {
    case TEXT
    case IMAGE
    
    var title: String {
        switch self {
            case .TEXT: return "Text Question"
            case .IMAGE: return "Photo Question"
        }
    }
}

struct UploadQuestion: View {
    @State private var selectedFilter: QuestionOption = .TEXT
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var viewModel: QuestionModel
    @Environment(\.colorScheme) var colorScheme
    @State private var goodTitle: String = ""
    @State private var goodDesc: String = ""
    @State private var showAddTags = false
    @Namespace private var animation
    @State var title: String = ""
    @State var caption: String = ""
    @State var tags: [String] = []
    @State private var tooManyInOneHour = ""
    @State private var uploaded = false
    @State private var promotedELO: Int = 0
    
    @State private var selectedImageOne: UIImage?
    @State private var questionImageOne: Image?
    @State private var selectedImageTwo: UIImage?
    @State private var questionImageTwo: Image?
    @State var showImagePicker = false
    @State var showFixSheet = false
    @State var showAI = false
    
    var body: some View {
        ZStack {
            VStack {
                HStack(){
                    Text("Ask a Question").bold().font(.title).padding(.leading).padding(.top, 25)
                    Spacer()
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        presentationMode.wrappedValue.dismiss()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text("Cancel")
                            .bold()
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(.blue).opacity(0.7)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .scaleEffect(0.9)
                    }.padding(.trailing).padding(.top, 25)
                }.frame(height: 55)
                ZStack{
                    if colorScheme == .dark {
                        LinearGradient(
                            gradient: Gradient(colors: [.black, .green.opacity(0.5), .black]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                    } else {
                        LinearGradient(
                            gradient: Gradient(colors: [.white, .green.opacity(0.5), .white]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                    }
                    VStack {
                        promoteFilter
                        if selectedFilter == .TEXT {
                            ScrollView {
                                VStack {
                                    ZStack(alignment: .center){
                                        RoundedRectangle(cornerRadius: 25).foregroundColor(.white)
                                        RoundedRectangle(cornerRadius: 25).foregroundColor(.black).opacity(colorScheme == .dark ? 0.2 : 0.4)
                                        VStack(spacing: 0){
                                            HStack{
                                                Text("Title").font(.system(size: 22)).foregroundColor(colorScheme == .dark ? .black : .white).bold()
                                                Text(goodTitle).font(.caption).foregroundColor(.red).bold()
                                                Spacer()
                                            }.padding()
                                            CustomVideoField(place: "Add a title", text: $title)
                                                .padding(.bottom)
                                                .onChange(of: title) { _, _ in
                                                    goodTitle = inputChecker().myInputChecker(withString: title, withLowerSize: 10, withUpperSize: 110, needsLower: true)
                                                    if title.isEmpty {
                                                        goodTitle = ""
                                                    }
                                                }
                                            Spacer()
                                        }.padding(5)
                                    }
                                    .frame(width: widthOrHeight(width: true) * 0.95, height: 130)
                                    .padding(.top)
                                    ZStack(alignment: .center){
                                        RoundedRectangle(cornerRadius: 25).foregroundColor(.white)
                                        RoundedRectangle(cornerRadius: 25).foregroundColor(.black).opacity(colorScheme == .dark ? 0.2 : 0.4)
                                        VStack(spacing: 0){
                                            HStack{
                                                Text("Description").font(.system(size: 22)).foregroundColor(colorScheme == .dark ? .black : .white).bold()
                                                Text(goodDesc).font(.caption).foregroundColor(.red).bold()
                                                Spacer()
                                                if showAI {
                                                    Button(action: {
                                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                        showFixSheet = true
                                                    }, label: {
                                                        ZStack {
                                                            Capsule().frame(width: 45, height: 26).foregroundColor(Color.gray).opacity(0.3)
                                                            LottieView(loopMode: .loop, name: "finite")
                                                                .scaleEffect(0.05)
                                                                .frame(width: 25, height: 14)
                                                        }
                                                    }).transition(.scale.combined(with: .opacity))
                                                }
                                            }.padding()
                                            CustomVideoField(place: "Add a description", text: $caption)
                                                .padding(.bottom)
                                                .onChange(of: caption, { _, new in
                                                    goodDesc = inputChecker().myInputChecker(withString: caption, withLowerSize: 30, withUpperSize: 500, needsLower: true)
                                                    if caption.isEmpty {
                                                        goodDesc = ""
                                                    }
                                                    
                                                    if caption.count > 30 && !showAI {
                                                        withAnimation(.easeInOut(duration: 0.15)){
                                                            showAI = true
                                                        }
                                                    } else if caption.count <= 30 && showAI {
                                                        withAnimation(.easeInOut(duration: 0.15)){
                                                            showAI = false
                                                        }
                                                    }
                                                })
                                            Spacer()
                                        }.padding(5)
                                    }
                                    .frame(width: widthOrHeight(width: true) * 0.95, height: 175)
                                    .padding(.top)
                                    ZStack(alignment: .center){
                                        RoundedRectangle(cornerRadius: 25).foregroundColor(.white)
                                        RoundedRectangle(cornerRadius: 25).foregroundColor(.black).opacity(colorScheme == .dark ? 0.2 : 0.4)
                                        VStack(spacing: 0){
                                            HStack{
                                                HStack(spacing: 5){
                                                    Text("Tags:").font(.system(size: 22)).foregroundColor(colorScheme == .dark ? .black : .white).bold()
                                                }
                                                Spacer()
                                                ForEach(tags, id: \.self) { text in
                                                    TagView(text, .blue, "")
                                                }
                                                Spacer()
                                                Button {
                                                    showAddTags.toggle()
                                                } label: {
                                                    Image(systemName: "plus").font(.system(size: 20)).foregroundColor(.blue).padding(6).background(.white).cornerRadius(20)
                                                }
                                            }.padding()
                                        }.padding(5)
                                    }
                                    .frame(width: widthOrHeight(width: true) * 0.95, height: 85)
                                    .padding(.top)
                                    promotionView()
                                }
                            }
                            .scrollIndicators(.hidden)
                            .gesture(
                                DragGesture()
                                    .onChanged { _ in
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    }
                                
                            )
                        } else {
                            ScrollView {
                                VStack {
                                    ZStack(alignment: .center){
                                        RoundedRectangle(cornerRadius: 25).foregroundColor(.white)
                                        RoundedRectangle(cornerRadius: 25).foregroundColor(.black).opacity(colorScheme == .dark ? 0.2 : 0.4)
                                        VStack(spacing: 0){
                                            HStack{
                                                Text("Description").font(.system(size: 22)).foregroundColor(colorScheme == .dark ? .black : .white).bold()
                                                Text(goodDesc).font(.caption).foregroundColor(.red).bold()
                                                Spacer()
                                            }.padding()
                                            CustomVideoField(place: "Add a description", text: $caption)
                                                .padding(.bottom)
                                                .onChange(of: caption, { _, new in
                                                    goodDesc = inputChecker().myInputChecker(withString: caption, withLowerSize: 30, withUpperSize: 200, needsLower: true)
                                                    if caption.isEmpty {
                                                        goodDesc = ""
                                                    }
                                                })
                                            Spacer()
                                        }.padding(5)
                                    }.frame(width: widthOrHeight(width: true) * 0.95, height: 150).padding(.top)
                                    VStack(spacing: 20){
                                        if selectedImageOne == nil {
                                            Button {
                                                showImagePicker.toggle()
                                            } label: {
                                                Image(systemName: "plus").font(.system(size: 25)).foregroundColor(.blue).padding(10).background(.white).cornerRadius(20)
                                            }
                                        } else if let image = questionImageOne {
                                            Button {
                                                if let p1 = questionImageTwo, let p2 = selectedImageTwo {
                                                    questionImageOne = p1
                                                    selectedImageOne = p2
                                                    questionImageTwo = nil
                                                    selectedImageTwo = nil
                                                } else {
                                                    questionImageOne = nil
                                                    selectedImageOne = nil
                                                }
                                            } label: {
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 170, height: 170)
                                                    .cornerRadius(10)
                                                    .clipped()
                                            }
                                        }
                                        if selectedImageTwo == nil {
                                            Button {
                                                showImagePicker.toggle()
                                            } label: {
                                                Image(systemName: "plus").font(.system(size: 25)).foregroundColor(.blue).padding(10).background(.white).cornerRadius(20)
                                            }
                                        } else if let image = questionImageTwo {
                                            Button {
                                                questionImageTwo = nil
                                                selectedImageTwo = nil
                                            } label: {
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 170, height: 170)
                                                    .cornerRadius(10)
                                                    .clipped()
                                            }
                                        }
                                    }.padding(.vertical)
                                    promotionView()
                                }
                            }
                            .scrollIndicators(.hidden)
                            .gesture(
                                DragGesture()
                                    .onChanged { _ in
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    }
                                
                            )
                        }
                    }.padding(.top, 15)
                }
                Spacer()
                if !viewModel.uploadError.isEmpty {
                    Text(viewModel.uploadError).font(.subheadline).foregroundColor(.red)
                }
                if tooManyInOneHour.isEmpty {
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        if let user = auth.currentUser, !uploaded {
                            if selectedFilter == .TEXT && goodDesc.isEmpty && goodTitle.isEmpty && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !tags.isEmpty {
                                var go = 0
                                let user2 = profile.users.first(where: { $0.user.username == user.username })
                                if let posts = user2?.questions?.prefix(7) {
                                    let arr = Array(posts)
                                    arr.forEach { element in
                                        if calculateCosineSimilarity(caption, element.caption) > 0.6 {
                                            viewModel.uploadError = "This question matches another, please make it unique."
                                            go = 1
                                        }
                                    }
                                }
                                if go == 0 {
                                    uploaded = true
                                    viewModel.uploadQuestion(title: title, caption: caption, tags: tags, promoted: promotedELO, username: auth.currentUser?.username ?? "", profilePhoto: auth.currentUser?.profileImageUrl)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                }
                            } else if selectedFilter == .IMAGE && goodDesc.isEmpty && !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImageOne != nil {
                                uploaded = true
                                viewModel.uploadQuestionImage(caption: caption, promoted: promotedELO, username: auth.currentUser?.username ?? "", profilePhoto: auth.currentUser?.profileImageUrl, image1: selectedImageOne, image2: selectedImageTwo)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        }
                    } label: {
                        if uploaded {
                            Loader(flip: true).id("\(UUID())")
                        } else {
                            ZStack(alignment: .center){
                                RoundedRectangle(cornerRadius: 25).foregroundColor(.white)
                                if selectedFilter == .TEXT && goodDesc.isEmpty && goodTitle.isEmpty && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !tags.isEmpty {
                                    RoundedRectangle(cornerRadius: 25).foregroundColor(.orange).opacity(0.7)
                                } else if selectedFilter == .IMAGE && goodDesc.isEmpty && !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImageOne != nil {
                                    RoundedRectangle(cornerRadius: 25).foregroundColor(.orange).opacity(0.7)
                                } else {
                                    RoundedRectangle(cornerRadius: 25).foregroundColor(.black).opacity(colorScheme == .dark ? 0.2 : 0.4)
                                }
                                VStack(spacing: 0){
                                    HStack{
                                        Text("Post").font(.system(size: 22)).foregroundColor(colorScheme == .dark ? .black : .white).bold()
                                    }.padding()
                                }.padding(5)
                            }.frame(width: widthOrHeight(width: true) * 0.95, height: 70)
                        }
                    }.padding(.bottom, 5)
                } else {
                    Text(tooManyInOneHour).font(.subheadline).foregroundColor(.red).padding(.vertical, 6)
                }
            }
            .onReceive(viewModel.$didUploadShop) { success in
                if success {
                    if promotedELO > 0 && auth.currentUser?.elo ?? 3000 < 2900 {
                        UserService().editElo(withUid: nil, withAmount: (promotedELO * -50)) {}
                    }
                    caption = ""
                    title = ""
                    tags = []
                    viewModel.didUploadShop = false
                    withAnimation(.easeIn(duration: 0.2)){
                        uploaded = false
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .onChange(of: viewModel.uploadError) { _, _ in
                if viewModel.uploadError == "Could not Upload at this time" {
                    uploaded = false
                }
            }
            .onAppear {
                viewModel.uploadError = ""
                tooManyInOneHour = ""
                if let user = auth.currentUser {
                    if user.elo >= 2900 { promotedELO = 4 }
                    if user.elo >= 850 { return }
                    else {
                        let hustles = profile.users.first(where: { $0.user.username == user.username })
                        if let posts = hustles?.questions {
                            var x = 0
                            let currentDate = Date()
                            posts.forEach { item in
                                let date = item.timestamp.dateValue()
                                let calendar = Calendar.current
                                if calendar.isDate(date, equalTo: currentDate, toGranularity: .hour) {
                                    x += 1
                                }
                            }
                            if (x == 1 && user.elo < 600) || (x == 3 && user.elo < 850) {
                                tooManyInOneHour = "max uploads for this hour"
                            }
                        } else { return }
                    }
                }
            }
        }
        .sheet(isPresented: $showFixSheet, content: {
            RecommendTextView(oldText: $caption)
        })
        .sheet(isPresented: $showImagePicker, onDismiss: loadImage){
            ImagePicker(selectedImage: selectedImageOne == nil ? $selectedImageOne : $selectedImageTwo)
                .tint(colorScheme == .dark ? .white : .black)
        }
        .sheet(isPresented: $showAddTags) {
            VStack {
                VStack(spacing: 0) {
                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(tags, id: \.self) { tag in
                                TagView(tag, .orange, "checkmark")
                                    .matchedGeometryEffect(id: tag, in: animation)
                                    .onTapGesture {
                                        withAnimation {
                                            tags.removeAll(where: { $0 == tag })
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 15)
                        .frame(height: 35)
                        .padding(.vertical, 15)
                    }.scrollIndicators(.hidden).zIndex(1)
                    
                    ScrollView(.vertical) {
                        TagLayout(alignment: .center, spacing: 8) {
                            ForEach(QuestionCategories().tags.filter { !tags.contains($0) }, id: \.self) { tag in
                                TagView(tag, .blue, "plus")
                                    .matchedGeometryEffect(id: tag, in: animation)
                                    .onTapGesture {
                                        withAnimation {
                                            if tags.count < 2 {
                                                tags.insert(tag, at: 0)
                                            } else {
                                                tags.removeLast()
                                                tags.insert(tag, at: 0)
                                            }
                                        }
                                    }
                                
                            }
                        }.padding(.vertical, 15).padding(.horizontal, 5)
                    }
                    .scrollIndicators(.hidden)
                    .zIndex(0)
                }
                Spacer()
                Text("Add up to 2 tags").bold().padding(.vertical)
                Button {
                    showAddTags.toggle()
                } label: {
                    ZStack{
                        RoundedRectangle(cornerRadius: 10).fill(.blue.gradient)
                            .frame(height: 44)
                        Text("Done").font(.system(size: 20)).bold()
                    }.padding(.horizontal)
                }.padding(.bottom, 15).disabled(tags.count == 0)
            }
            .edgesIgnoringSafeArea(.horizontal)
            .presentationDetents([.fraction(0.75)])
        }
    }
    func promotionView() -> some View {
        VStack {
            VStack(spacing: 15){
                if let user = auth.currentUser {
                    if user.elo < 2900 {
                        PromoteELO(days: $promotedELO, userElo: auth.currentUser?.elo ?? 0)
                    } else {
                        ZStack{
                            RoundedRectangle(cornerRadius: 10).frame(width: 120, height: 45).foregroundColor(Color(UIColor.lightGray))
                            Text("Auto Promoted").font(.system(size: 15)).foregroundColor(.black).bold()
                        }.shimmering().padding(.top)
                    }
                } else {
                    PromoteELO(days: $promotedELO, userElo: auth.currentUser?.elo ?? 0)
                }
            }
            Text("*Promoted items appear at the top").font(.subheadline).padding(.vertical, 8)
        }
    }
    func loadImage() {
        if questionImageOne == nil {
            guard let selectedImage = selectedImageOne else { return }
            questionImageOne = Image(uiImage: selectedImage)
        } else {
            guard let selectedImage = selectedImageTwo else { return }
            questionImageTwo = Image(uiImage: selectedImage)
        }
    }
    @ViewBuilder
    func TagView(_ tag: String, _ color: Color, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Text(tag)
                .font(.callout)
                .fontWeight(.semibold)
            if !icon.isEmpty {
                Image(systemName: icon)
            }
        }
        .minimumScaleFactor(0.6)
        .frame(height: 35)
        .foregroundStyle(.white)
        .padding(.horizontal, 15)
        .background {
            Capsule()
                .fill(color.gradient)
        }
    }
}

extension UploadQuestion {
    var promoteFilter: some View {
        HStack{
            ForEach(QuestionOption.allCases, id: \.rawValue){ item in
                VStack {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(selectedFilter == item ? .semibold: .regular)
                        .foregroundColor(selectedFilter == item ? colorScheme == .dark ? .white : .black : .gray)
                    
                    if selectedFilter == item {
                        Capsule()
                            .foregroundColor(Color(.systemBlue))
                            .frame(height: 3)
                            .matchedGeometryEffect(id: "filter", in: animation)
                    } else {
                        Capsule()
                            .foregroundColor(Color(.clear))
                            .frame(height: 3)
                    }
                }
                .onTapGesture {
                    withAnimation(.easeInOut){
                        self.selectedFilter = item
                    }
                }
            }
        }.overlay(Divider().offset(x:0, y:16))
    }
}
