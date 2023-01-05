import SwiftUI
import UIKit
import Foundation
import Kingfisher

enum EditGroupOptions: Int, CaseIterable{
    case title
    case priv
    case desc
    case rule
    case image
    
    var title: String {
        switch self {
            case .title: return "Title"
            case .priv: return "Public"
            case .desc: return "Desc."
            case .rule: return "Rules"
            case .image: return "Photo"
        }
    }
}

struct EditGroupView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: GroupViewModel
    var userId: String
    @Environment(\.presentationMode) var presentationMode
    @State var selectedImage: UIImage?
    @State var groupImage: Image?
    @State var addImage: Bool = false
    @State var publicStatus = false
    @State var desc: String = ""
    @State var descErr: String = ""
    @State var rules: String = ""
    @State var ruleErr: String = ""
    @State var titleNew: String = ""
    @State var titleErr: String = ""
    @State private var selectedFilter: EditGroupOptions = .title
    @Namespace private var animation
    
    var body: some View {
        VStack {
            ZStack{
                Color(.orange).opacity(0.7).ignoresSafeArea()
                HStack{
                    Text("Modify Channel").font(.title2).bold()
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        HStack(spacing: 2){
                            Image(systemName: "chevron.backward")
                                .scaleEffect(1.5)
                                .frame(width: 15, height: 15)
                            Text("back").font(.subheadline)
                        }
                    }
                }.padding(.horizontal, 12)
            }.frame(height: 80).ignoresSafeArea(.keyboard)
            
            promoteFilter.padding(.vertical)
            
            VStack {
                if selectedFilter == .title {
                    VStack {
                        VStack{
                            Text("Edit Group Name").font(.title).bold()
                        }.padding(.top, widthOrHeight(width: true) * 0.2)
                        VStack {
                            TextField("Group Name...", text: $titleNew)
                                .padding(.leading)
                                .onChange(of: titleNew) { _ in
                                    titleErr = inputChecker().myInputChecker(withString: titleNew, withLowerSize: 1, withUpperSize: 12, needsLower: true)
                                }
                                .frame(width: 230, height: 40)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(.gray, lineWidth: 2)
                                }
                        }.padding(.top)
                        Text(titleErr).font(.caption).foregroundColor(.red)
                        Spacer()
                        if let index = viewModel.currentGroup {
                            Button {
                                if titleNew != viewModel.groups[index].1.title && titleErr == "" {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    viewModel.editTitle(newTitle: titleNew)
                                    viewModel.groups[index].1.title = titleNew
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15).frame(height: 40)
                                        .foregroundColor((titleNew != viewModel.groups[index].1.title && titleErr == "" ? .blue : .gray)).opacity(0.7)
                                    Text("Save").bold().font(.title2).foregroundColor(.white)
                                }.padding(.horizontal, 20)
                            }
                        }
                    }
                } else if selectedFilter == .priv {
                    VStack {
                        VStack {
                            Text("Edit Public Status").font(.title).bold()
                        }.padding(.top, widthOrHeight(width: true) * 0.2)
                        HStack {
                            Text(publicStatus ? "Public" : "Private").font(.system(size: 18)).bold()
                            Spacer()
                            Toggle("", isOn: $publicStatus).tint(.green)
                        }.padding(.top).padding(.horizontal, widthOrHeight(width: true) * 0.15)
                        Spacer()
                        if let index = viewModel.currentGroup {
                            Button {
                                if publicStatus != viewModel.groups[index].1.publicstatus {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    viewModel.editPublic(publicStat: publicStatus)
                                    viewModel.groups[index].1.publicstatus = publicStatus
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15).frame(height: 40)
                                        .foregroundColor((publicStatus != viewModel.groups[index].1.publicstatus ? .blue : .gray)).opacity(0.7)
                                    Text("Save").bold().font(.title2).foregroundColor(.white)
                                }.padding(.horizontal, 20)
                            }
                        }
                    }
                } else if selectedFilter == .desc {
                    VStack {
                        ScrollView {
                            VStack{
                                Text("Edit Group Description").font(.title).bold().multilineTextAlignment(.center)
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
                                descErr = inputChecker().myInputChecker(withString: desc, withLowerSize: 0, withUpperSize: 500, needsLower: true)
                                if let newValueLastChar = desc.last, newValueLastChar == "\n" {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    desc.removeLast()
                                }
                            })
                            Text(descErr).foregroundColor(.red).font(.caption)
                        }
                        .scrollIndicators(.hidden)
                        .gesture (
                            DragGesture()
                                .onChanged { _ in
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                        )
                        Spacer()
                        if let index = viewModel.currentGroup {
                            Button {
                                if desc != viewModel.groups[index].1.desc && descErr == "" {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    viewModel.editDesc(desc: desc)
                                    viewModel.groups[index].1.desc = desc
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15).frame(height: 40)
                                        .foregroundColor((desc != viewModel.groups[index].1.desc && descErr == "") ? .blue : .gray).opacity(0.7)
                                    Text("Save").bold().font(.title2).foregroundColor(.white)
                                }.padding(.horizontal, 20)
                            }
                        }
                    }
                } else if selectedFilter == .rule {
                    VStack {
                        ScrollView {
                            VStack {
                                Text("Edit Group Rules").font(.title).bold().multilineTextAlignment(.center)
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
                                ruleErr = inputChecker().myInputChecker(withString: rules, withLowerSize: 0, withUpperSize: 500, needsLower: false)
                            })
                            Text(ruleErr).foregroundColor(.red).font(.caption)
                        }
                        .scrollIndicators(.hidden)
                        .gesture (
                            DragGesture()
                                .onChanged { _ in
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                        )
                        Spacer()
                        if let index = viewModel.currentGroup {
                            Button {
                                if rules != viewModel.groups[index].1.rules && ruleErr == "" {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    viewModel.editRules(rules: rules)
                                    viewModel.groups[index].1.rules = rules
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15).frame(height: 40)
                                        .foregroundColor((rules != viewModel.groups[index].1.rules && ruleErr == "") ? .blue : .gray).opacity(0.7)
                                    Text("Save").bold().font(.title2).foregroundColor(.white)
                                }.padding(.horizontal, 20)
                            }
                        }
                    }
                } else if selectedFilter == .image {
                    VStack {
                        VStack{
                            Text("Edit Group photo").font(.title).bold().multilineTextAlignment(.center)
                        }.padding(.top, widthOrHeight(width: true) * 0.2).padding(.horizontal)
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(.gray)
                                .frame(width: 100, height: 70)
                                .opacity(0.4)
                            Button {
                                addImage.toggle()
                            } label: {
                                if let jobImage = groupImage {
                                    jobImage.resizable().modifier(GroupImageModifier())
                                } else if let index = viewModel.currentGroup {
                                    KFImage(URL(string: viewModel.groups[index].1.imageUrl))
                                        .resizable()
                                        .modifier(GroupImageModifier())
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
                        if let index = viewModel.currentGroup {
                            Button {
                                if let image = selectedImage {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    viewModel.editCoverImage(image: image, oldImage: viewModel.groups[index].1.imageUrl)
                                    selectedImage = nil
                                    groupImage = nil
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15).frame(height: 40)
                                        .foregroundColor((selectedImage != nil) ? .blue : .gray).opacity(0.7)
                                    Text("Save").bold().font(.title2).foregroundColor(.white)
                                }.padding(.horizontal, 20)
                            }
                        }
                    }
                }
            }.padding(.bottom, 5)
        }
        .dynamicTypeSize(.large)
        .sheet(isPresented: $addImage, onDismiss: loadImage){
            ImagePicker(selectedImage: $selectedImage)
                .tint(colorScheme == .dark ? .white : .black)
        }
        .onAppear {
            if let index = viewModel.currentGroup, index < viewModel.groups.count {
                if viewModel.groups[index].1.leaders.contains(userId){
                    publicStatus = viewModel.groups[index].1.publicstatus
                    desc = viewModel.groups[index].1.desc
                    rules = viewModel.groups[index].1.rules ?? ""
                    titleNew = viewModel.groups[index].1.title
                }
            }
        }
    }
    func loadImage() {
        guard let selectedImage = selectedImage else {return}
        groupImage = Image(uiImage: selectedImage)
    }
}

extension EditGroupView {
    var promoteFilter: some View {
        HStack {
            if let index = viewModel.currentGroup {
                ForEach(EditGroupOptions.allCases, id: \.rawValue){ item in
                    if item == .image || item == .title {
                        if userId == viewModel.groups[index].1.leaders.first {
                            VStack{
                                Text(item.title)
                                    .font(.subheadline)
                                    .fontWeight(selectedFilter == item ? .semibold: .regular)
                                    .foregroundColor(selectedFilter == item ? colorScheme == .dark ? .white : .black : .gray)
                                
                                if selectedFilter == item{
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
                    } else {
                        VStack{
                            Text(item.title)
                                .font(.subheadline)
                                .fontWeight(selectedFilter == item ? .semibold: .regular)
                                .foregroundColor(selectedFilter == item ? colorScheme == .dark ? .white : .black : .gray)
                            
                            if selectedFilter == item{
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
                }
            }
        }.overlay(Divider().offset(x:0, y:16))
    }
}
