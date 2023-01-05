import SwiftUI
import Combine
import UIKit

struct CreateGroupView: View, KeyboardReadable {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: GroupViewModel
    @EnvironmentObject var explore: ExploreViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @State var showImagePicker = false
    @State var showDidNotUpload: Bool = false
    @State var showDidUpload: Bool = false
    @State var uploaded: Bool = false
    @State var title = ""
    @State var titleError: String = ""
    @State var selectedImage: UIImage?
    @State var groupImage: Image?
    @State var rules: String = ""
    @State var ruleError: String = ""
    @State var publicStatus: Bool = true
    @State var desc: String = ""
    @State var descError: String = ""
    @State private var selection = 1
    @State private var showPrivSheet = false
    @State private var keyBoardVisible = false
    @State private var viewTop = false
    
    var body: some View {
        VStack(alignment: .center){
            ZStack{
                Color(.orange).opacity(0.7).ignoresSafeArea()
                HStack{
                    Text("Create a Channel").font(.title).bold().padding(.top)
                    Spacer()
                    Button {
                        if selection == 1 {
                            presentationMode.wrappedValue.dismiss()
                        } else if selection == 2 {
                            selection = 1
                        } else if selection == 3 {
                            selection = 2
                        } else if selection == 4 {
                            selection = 3
                        }
                    } label: {
                        HStack(spacing: 2){
                            Image(systemName: "chevron.backward")
                                .scaleEffect(1.3)
                                .frame(width: 15, height: 15)
                            Text("back")
                        }
                    }.offset(y: 8)
                }.padding(.horizontal, 15)
            }.frame(height: 80)
            
            if selection == 1 {
                VStack {
                    VStack(spacing: 8){
                        Text("Pick a Group Name").font(.title).bold()
                        Text("*can be changed later*").font(.callout).foregroundColor(.gray)
                    }.padding(.top, widthOrHeight(width: true) * 0.2)
                    VStack {
                        TextField("Group Name...", text: $title)
                            .padding(.leading)
                            .onChange(of: title) { _ in
                                titleError = inputChecker().myInputChecker(withString: title, withLowerSize: 1, withUpperSize: 12, needsLower: true)
                            }
                            .frame(width: 230, height: 40)
                            .overlay {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(.gray, lineWidth: 2)
                            }
                    }.padding(.top)
                    Text(titleError).font(.caption).foregroundColor(.red)
                    Spacer()
                    Button {
                        if (titleError == "" && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            showPrivSheet.toggle()
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15).frame(height: 40)
                                .foregroundColor((titleError == "" && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .orange : .gray)).opacity(0.7)
                            Text("Next").bold().font(.title2).foregroundColor(.white)
                        }.padding(.horizontal, 20)
                    }.padding(.bottom, keyBoardVisible ? 10 : 70)
                }
            } else if selection == 2 {
                VStack {
                    ScrollView {
                        VStack(spacing: 8){
                            Text("Add in some details to describe your Group").font(.title).bold().multilineTextAlignment(.center)
                            Text("*can be changed later*").font(.callout).foregroundColor(.gray)
                        }.padding(.top, widthOrHeight(width: true) * 0.12).padding(.horizontal).ignoresSafeArea()
                        ZStack(alignment: .leading){
                            if desc.isEmpty {
                                Text("description...")
                                    .opacity(0.5).offset(x: 15)
                                    .foregroundColor(.gray).font(.system(size: 17))
                            }
                            TextField("", text: $desc, axis: .vertical)
                                .tint(.blue)
                                .lineLimit(6)
                                .padding(.leading)
                                .padding(.trailing, 4)
                                .frame(minHeight: 40)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(.gray, lineWidth: 2)
                                }
                        }
                        .padding(.horizontal, 40).padding(.top)
                        .onChange(of: desc, perform: { new in
                            descError = inputChecker().myInputChecker(withString: desc, withLowerSize: 0, withUpperSize: 500, needsLower: true)
                        })
                        Text(descError).foregroundColor(.red).font(.caption)
                    }
                    .scrollIndicators(.hidden)
                    .gesture (
                        DragGesture()
                            .onChanged { _ in
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                    )
                    Spacer()
                    Button {
                        if (descError == "" && !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                            selection = 3
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15).frame(height: 40)
                                .foregroundColor((descError == "" && !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? .orange : .gray).opacity(0.7)
                            Text("Next").bold().font(.title2).foregroundColor(.white)
                        }.padding(.horizontal, 20)
                    }.padding(.bottom, keyBoardVisible ? 10 : 70)
                }
            } else if selection == 3 {
                VStack {
                    ScrollView {
                        VStack(spacing: 8){
                            Text("Add in some Group Rules").font(.title).bold().multilineTextAlignment(.center)
                            Text("*Optional, can be changed later*").font(.callout).foregroundColor(.gray)
                        }.padding(.top, widthOrHeight(width: true) * 0.12).padding(.horizontal).ignoresSafeArea()
                        ZStack(alignment: .leading){
                            if rules.isEmpty {
                                Text("Rules...")
                                    .opacity(0.5).offset(x: 15)
                                    .foregroundColor(.gray).font(.system(size: 17))
                            }
                            TextField("", text: $rules, axis: .vertical)
                                .tint(.blue)
                                .lineLimit(6)
                                .padding(.leading)
                                .padding(.trailing, 4)
                                .frame(minHeight: 40)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(.gray, lineWidth: 2)
                                }
                        }
                        .padding(.horizontal, 40).padding(.top)
                        .onChange(of: rules, perform: { new in
                            ruleError = inputChecker().myInputChecker(withString: rules, withLowerSize: 0, withUpperSize: 500, needsLower: false)
                        })
                        Text(ruleError).foregroundColor(.red).font(.caption)
                    }
                    .scrollIndicators(.hidden)
                    .gesture (
                        DragGesture()
                            .onChanged { _ in
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                    )
                    Spacer()
                    Button {
                        if ruleError == "" {
                            selection = 4
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15).frame(height: 40)
                                .foregroundColor(ruleError == "" ? .orange : .gray).opacity(0.7)
                            Text("Next").bold().font(.title2).foregroundColor(.white)
                        }.padding(.horizontal, 20)
                    }.padding(.bottom, keyBoardVisible ? 10 : 70)
                }
            } else if selection == 4 {
                VStack {
                    VStack(spacing: 8){
                        Text("Add a Group photo").font(.title).bold().multilineTextAlignment(.center)
                        Text("*can be changed later*").font(.callout).foregroundColor(.gray)
                    }.padding(.top, widthOrHeight(width: true) * 0.2).padding(.horizontal)
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(.gray)
                            .frame(width: 100, height: 70)
                            .opacity(0.4)
                        Button {
                            showImagePicker.toggle()
                        } label: {
                            if let jobImage = groupImage {
                                jobImage.resizable().modifier(GroupImageModifier())
                            } else {
                                ZStack(alignment: .center){
                                    Image(systemName: "circle.fill").resizable().foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : .black)
                                    Image(systemName: "questionmark")
                                        .resizable()
                                        .foregroundColor(.white)
                                        .frame(width: 15, height: 20)
                                }.modifier(GroupImageModifier())
                            }
                        }
                    }.padding(.top, 60).scaleEffect(1.3)
                    Spacer()
                    if !showDidNotUpload && !showDidUpload {
                        if !uploaded {
                            Button {
                                if let image = selectedImage {
                                    if titleError == "" && descError == "" && ruleError == "" && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        uploaded = true
                                        viewModel.createGroup(title: title, image: image, rules: rules, publicStatus: publicStatus, desc: desc)
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15).frame(height: 40)
                                        .foregroundColor((titleError == "" && descError == "" && ruleError == "" && selectedImage != nil && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? .orange : .gray).opacity(0.7)
                                    Text("Upload").bold().font(.title2).foregroundColor(.white)
                                }.padding(.horizontal, 20)
                            }.padding(.bottom, keyBoardVisible ? 10 : 70)
                        } else {
                            Loader(flip: true).id("\(UUID())").padding(.bottom, keyBoardVisible ? 10 : 70)
                        }
                    }
                }
            }
        }
        .onAppear { viewTop = true }
        .onDisappear { viewTop = false }
        .onChange(of: popRoot.tap) { _ in
            if popRoot.tap == 3 && popRoot.Explore_or_Video && viewTop {
                popRoot.tap = 0
                if selection == 1 {
                    presentationMode.wrappedValue.dismiss()
                } else if selection == 2 {
                    selection = 1
                } else if selection == 3 {
                    selection = 2
                } else if selection == 4 {
                    selection = 3
                }
            }
        }
        .dynamicTypeSize(.large)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showImagePicker, onDismiss: loadImage){
            ImagePicker(selectedImage: $selectedImage)
                .tint(colorScheme == .dark ? .white : .black)
        }
        .onReceive(keyboardPublisher) { newIsKeyboardVisible in
            keyBoardVisible = newIsKeyboardVisible
        }
        .onChange(of: viewModel.didUploadGroup, perform: { success in
            if success {
                showDidUpload = true
                uploaded = false
                Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
                    showDidUpload = false
                    presentationMode.wrappedValue.dismiss()
                    title = ""
                    titleError = ""
                    selectedImage = nil
                    groupImage = nil
                    rules = ""
                    ruleError = ""
                    publicStatus = true
                    desc = ""
                    descError = ""
                    viewModel.didUploadGroup = false
                }
                if !viewModel.groupId.isEmpty {
                    explore.getUserGroupCover(userGroupId: [viewModel.groupId])
                    if authViewModel.currentUser?.groupIdentifier == nil {
                        authViewModel.currentUser?.groupIdentifier = [viewModel.groupId]
                    } else {
                        authViewModel.currentUser?.groupIdentifier?.append(viewModel.groupId)
                    }
                    viewModel.groupId = ""
                }
            }
        })
        .onChange(of: viewModel.uploadFaliure, perform: { _ in
            if !viewModel.uploadFaliure.isEmpty {
                uploaded = false
                viewModel.uploadFaliure = ""
                showDidNotUpload = true
                if !viewModel.groupId.isEmpty {
                    explore.getUserGroupCover(userGroupId: [viewModel.groupId])
                    if authViewModel.currentUser?.groupIdentifier == nil {
                        authViewModel.currentUser?.groupIdentifier = [viewModel.groupId]
                    } else {
                        authViewModel.currentUser?.groupIdentifier?.append(viewModel.groupId)
                    }
                    viewModel.groupId = ""
                }
                Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
                    showDidNotUpload = false
                    presentationMode.wrappedValue.dismiss()
                }
            }
        })
        .sheet(isPresented: $showDidNotUpload) {
            VStack{
                LottieView(loopMode: .loop, name: "failure").scaleEffect(0.4).frame(width: 85, height: 85).padding(.top)
                Text("Process incomplete, please try again later").font(.subheadline).padding(.top)
                Spacer()
            }
            .presentationDetents([.fraction(0.2)])
        }
        .sheet(isPresented: $showDidUpload) {
            VStack{
                LottieView(loopMode: .loop, name: "success").scaleEffect(0.9).frame(width: 85, height: 85).padding(.top)
                Text("Success, your group will be active in a few moments").font(.subheadline)
                Spacer()
            }
            .presentationDetents([.fraction(0.2)])
            .onDisappear {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .sheet(isPresented: $showPrivSheet) {
            if #available(iOS 16.4, *){
                sheetView().presentationDetents([.height(250)]).presentationCornerRadius(60)
            } else {
                sheetView().presentationDetents([.height(250)])
            }
        }
    }
    func loadImage() {
        guard let selectedImage = selectedImage else {return}
        groupImage = Image(uiImage: selectedImage)
    }
    func sheetView() -> some View {
        VStack {
            HStack {
                Text("Is this Group Public?").font(.title2).bold()
                Spacer(minLength: 90)
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    publicStatus = true
                    showPrivSheet = false
                    selection = 2
                } label: {
                    Text("Yes").font(.system(size: 22)).foregroundColor(.blue)
                }
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    publicStatus = false
                    showPrivSheet = false
                    selection = 2
                } label: {
                    Text("No").font(.system(size: 22)).foregroundColor(.red)
                }
            }.padding(.horizontal, 35)
        }
    }
}
