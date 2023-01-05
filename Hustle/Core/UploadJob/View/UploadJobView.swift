import SwiftUI
import Kingfisher
import UIKit

struct UploadJobView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @ObservedObject var viewModel: UploadJobViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var goodTitle: String = ""
    @State private var goodDesc: String = ""
    @State private var goodZip: Bool = true
    @State private var goodLink: String = ""
    @Binding var selTab: Int
    let lastTab: Int
    let isProfile: Bool
    @State private var showCountryPicker = false
    @State var selectedCountry: String = ""
    @Environment(\.presentationMode) var presentationMode
    @State var showFixSheet = false
    @State var showAI = false
    
    var body: some View {
        ZStack {
            VStack{
                HStack(){
                    Text("Post a Job").bold().font(.title).padding(.leading).padding(.top, 25)
                    Spacer()
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if isProfile {
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            withAnimation(.easeInOut){
                                selTab = lastTab
                            }
                        }
                    } label: {
                        Text("Cancel")
                            .bold()
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(Color(.systemOrange).opacity(0.7))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .scaleEffect(0.9)
                    }.padding(.trailing).padding(.top, 25)
                }.frame(height: 55)
                ZStack{
                    if colorScheme == .dark {
                        LinearGradient(
                            gradient: Gradient(colors: [.black, .orange.opacity(0.7), .black]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                    } else {
                        LinearGradient(
                            gradient: Gradient(colors: [.white, .orange.opacity(0.7), .white]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                    }
                    ScrollView{
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
                                    CustomVideoField(place: "Add a title", text: $viewModel.title)
                                        .padding(.bottom)
                                        .onChange(of: viewModel.title) { _, _ in
                                            goodTitle = inputChecker().myInputChecker(withString: viewModel.title, withLowerSize: 5, withUpperSize: 60, needsLower: true)
                                            if viewModel.title.isEmpty {
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
                                    CustomVideoField(place: "Add a job description", text: $viewModel.caption)
                                        .padding(.bottom)
                                        .onChange(of: viewModel.caption, { _, new in
                                            goodDesc = inputChecker().myInputChecker(withString: viewModel.caption, withLowerSize: 30, withUpperSize: 500, needsLower: true)
                                            if viewModel.caption.isEmpty {
                                                goodDesc = ""
                                            }
                                            
                                            if viewModel.caption.count > 30 && !showAI {
                                                withAnimation(.easeInOut(duration: 0.15)){
                                                    showAI = true
                                                }
                                            } else if viewModel.caption.count <= 30 && showAI {
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
                                        Text("Link").font(.system(size: 22)).foregroundColor(colorScheme == .dark ? .black : .white).bold()
                                        Text(goodLink).font(.caption).foregroundColor(.red).bold()
                                        Spacer()
                                    }.padding()
                                    CustomVideoField(place: "Add a Link", text: $viewModel.link)
                                        .padding(.bottom)
                                        .onChange(of: viewModel.link) { _, _ in
                                            goodLink = inputChecker().myInputChecker(withString: viewModel.link, withLowerSize: 1, withUpperSize: 200, needsLower: false)
                                            if let url = URL(string: viewModel.link), UIApplication.shared.canOpenURL(url) { } else {
                                                goodLink = "invalid link"
                                            }
                                            if viewModel.link.isEmpty {
                                                goodLink = ""
                                            }
                                        }
                                    Spacer()
                                }.padding(5)
                            }
                            .frame(width: widthOrHeight(width: true) * 0.95, height: 125)
                            .padding(.top)
                            ZStack(alignment: .center){
                                RoundedRectangle(cornerRadius: 25).foregroundColor(.white)
                                RoundedRectangle(cornerRadius: 25).foregroundColor(.black).opacity(colorScheme == .dark ? 0.2 : 0.4)
                                VStack(spacing: 0){
                                    HStack{
                                        Text("Remote Job?").font(.system(size: 22)).foregroundColor(colorScheme == .dark ? .black : .white).bold()
                                        Spacer()
                                        Toggle("", isOn: $viewModel.selected)
                                            .tint(.green)
                                    }.padding()
                                }.padding(5)
                            }
                            .frame(width: widthOrHeight(width: true) * 0.95, height: 85)
                            .padding(.top)
                            ZStack(alignment: .center){
                                RoundedRectangle(cornerRadius: 25).foregroundColor(.white)
                                RoundedRectangle(cornerRadius: 25).foregroundColor(.black).opacity(colorScheme == .dark ? 0.2 : 0.4)
                                VStack(spacing: 0){
                                    HStack{
                                        Text("ZipCode").font(.system(size: 22)).foregroundColor(goodZip ? colorScheme == .dark ? .black : .white : .red).bold()
                                        Spacer()
                                        CustomVideoField(place: "zipCode/City", text: $viewModel.zipCode)
                                            .lineLimit(1)
                                            .frame(width: 125)
                                            .onChange(of: viewModel.zipCode) { _, _ in
                                                if viewModel.isValidZipCode(viewModel.zipCode){
                                                    goodZip = true
                                                } else {
                                                    goodZip = false
                                                }
                                                if viewModel.zipCode.isEmpty {
                                                    goodZip = true
                                                }
                                            }
                                        Spacer()
                                        if let country = auth.currentUser?.userCountry {
                                            Button {
                                                withAnimation(.easeInOut){ showCountryPicker = true }
                                            } label: {
                                                Text(country).font(.footnote).foregroundColor(.blue).underline()
                                            }
                                        }
                                    }.padding()
                                }.padding(5)
                            }
                            .frame(width: widthOrHeight(width: true) * 0.95, height: 85)
                            .padding(.top)
                            Button {
                                if viewModel.selected {
                                    if (goodDesc.isEmpty && goodTitle.isEmpty && !viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (viewModel.link.isEmpty || goodLink.isEmpty)){
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        withAnimation(.easeInOut){
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            selTab = 3
                                        }
                                    }
                                } else {
                                    if (goodDesc.isEmpty && goodTitle.isEmpty && !viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (viewModel.link.isEmpty || goodLink.isEmpty) && !viewModel.zipCode.isEmpty && goodZip){
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        withAnimation(.easeInOut){
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            selTab = 3
                                        }
                                    }
                                }
                            } label: {
                                ZStack(alignment: .center){
                                    RoundedRectangle(cornerRadius: 25).foregroundColor(.white)
                                    if viewModel.selected {
                                        if (goodDesc.isEmpty && goodTitle.isEmpty && !viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (viewModel.link.isEmpty || goodLink.isEmpty)) {
                                            RoundedRectangle(cornerRadius: 25).foregroundColor(.orange).opacity(0.7)
                                        } else {
                                            RoundedRectangle(cornerRadius: 25).foregroundColor(.black).opacity(colorScheme == .dark ? 0.2 : 0.4)
                                        }
                                    } else {
                                        if (goodDesc.isEmpty && goodTitle.isEmpty && !viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (viewModel.link.isEmpty || goodLink.isEmpty) && !viewModel.zipCode.isEmpty) {
                                            RoundedRectangle(cornerRadius: 25).foregroundColor(.orange).opacity(0.7)
                                        } else {
                                            RoundedRectangle(cornerRadius: 25).foregroundColor(.black).opacity(colorScheme == .dark ? 0.2 : 0.4)
                                        }
                                    }
                                    VStack(spacing: 0){
                                        HStack{
                                            Text("Continue").font(.system(size: 22)).foregroundColor(colorScheme == .dark ? .black : .white).bold()
                                        }.padding()
                                    }.padding(5)
                                }.frame(width: widthOrHeight(width: true) * 0.95, height: 70)
                            }.padding(.top, 5)
                            Color.clear.frame(height: 47)
                        }
                    }
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.immediately)
                }
            }
            if showCountryPicker {
                CountryPicker(selectedCountry: $selectedCountry, update: true, background: true, close: $showCountryPicker)
                    .onChange(of: selectedCountry) { _, _ in
                        withAnimation {
                            showCountryPicker = false
                        }
                    }
                
            }
        }
        .sheet(isPresented: $showFixSheet, content: {
            RecommendTextView(oldText: $viewModel.caption)
        })
        .ignoresSafeArea()
        .onChange(of: popRoot.tap) { _, _ in
            if popRoot.tap == 2 && selTab == 2 {
                popRoot.tap = 0
                withAnimation(.easeIn(duration: 0.2)){
                    selTab = lastTab
                }
            }
        }
    }
}
