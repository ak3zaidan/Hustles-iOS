import SwiftUI

struct subSquares: Identifiable, Hashable {
    var id: String
    var name: String
    var sub: [String]
    var show: Bool
}

struct CreateSquare: View {
    let colors: [Color] = [.blue, .red, .green, .purple, .pink, .yellow, .indigo, .mint, .teal]
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: GroupViewModel
    @State var pickedC: [String : Color] = [:]
    @State var titleNew: String = ""
    @State var titleErr: String = ""
    @State var showFinal: Bool = false
    @State var selectedSubGroup: String = ""
    @State var titleNew1: String = ""
    @State var titleErr1: String = ""
    @State var selection: Int = 0
    
    @State var showDelete: Bool = false
    @State var toDelete: String = ""
    
    @State var moveTo: String = ""
    @State var shuffleSquare: String = ""
    @State var shuffleAvoid: String = ""
    @State var showShuffle: Bool = false
    @State var justUploaded: Bool = false
    
    var body: some View {
        VStack {
            topView()
            pickerView()
            TabView(selection: $selection) {
                createSquare().tag(0)
                createSub().tag(1)
                editLayout().tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .onAppear(perform: {
            if let index = viewModel.currentGroup {
                if let all = viewModel.groups[index].1.squares {
                    all.forEach { element in
                        pickedC[element] = colors.randomElement() ?? .orange
                    }
                }
                if let all = viewModel.subContainers.first(where: { $0.0 == viewModel.groups[index].1.id }){
                    all.1.forEach { element in
                        element.sub.forEach { new in
                            pickedC[new] = colors.randomElement() ?? .orange
                        }
                    }
                }
            }
        })
        .dynamicTypeSize(.large)
        .overlay {
            if showFinal {
                selectSubView()
            } else if showShuffle {
                moveToNew()
            }
        }
        .alert("Confirm deletion of \(toDelete)", isPresented: $showDelete) {
            Button("Delete", role: .destructive) {
                deleteSub()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    func moveToNew() -> some View {
        ZStack {
            Color.gray.opacity(0.001).onTapGesture {
                moveTo = ""
                withAnimation {
                    showShuffle = false
                }
            }
            VStack {
                Spacer()
                VStack {
                    VStack {
                        HStack {
                            Text("Move Square To").font(.system(size: 18)).bold()
                            Spacer()
                        }
                        VStack(spacing: 10){
                            if shuffleAvoid != "None |*^&^@$^" {
                                Button(action: {
                                    moveTo = "None |*^&^@$^"
                                }, label: {
                                    Text("None").font(.system(size: 16))
                                        .foregroundStyle(moveTo == "None |*^&^@$^" ? .blue : .white)
                                })
                            }
                            if let index = viewModel.currentGroup, let all = viewModel.subContainers.first(where: { $0.0 == viewModel.groups[index].1.id }) {
                                ForEach(all.1){ element in
                                    if element.name != shuffleAvoid {
                                        Button(action: {
                                            moveTo = element.name
                                        }, label: {
                                            Text(element.name).font(.system(size: 16))
                                                .foregroundStyle(moveTo == element.name ? .blue : .white)
                                        })
                                    }
                                }
                            }
                        }.padding(.vertical, 20)
                        Button(action: {
                            if !moveTo.isEmpty {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                withAnimation {
                                    showShuffle = false
                                }
                                shuffleSub(square: shuffleSquare, moveToSub: moveTo)
                                moveTo = ""
                                shuffleAvoid = ""
                                shuffleSquare = ""
                            }
                        }, label: {
                            Text("Confirm").font(.system(size: 18)).bold()
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(.blue)
                                .clipShape(Capsule())
                        }).opacity(!moveTo.isEmpty ? 1.0 : 0.5)
                    }.padding()
                }
                .frame(width: 200)
                .background(colorScheme == .dark ? Color(UIColor.darkGray) : Color(UIColor.lightGray))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                Spacer()
            }
        }
        .transition(.move(edge: .bottom))
        .background(.ultraThinMaterial)
    }
    func editLayout() -> some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 5){
                    if let index = viewModel.currentGroup {
                        if let squares = viewModel.groups[index].1.squares {
                            ForEach(squares, id: \.self){ element in
                                HStack(spacing: 18){
                                    ColorsCard(gradientColors: [pickedC[element] ?? .orange, .black], size: 45)
                                    Text(element).font(.system(size: 18)).lineLimit(1).minimumScaleFactor(0.7)
                                    Spacer()
                                    Button(action: {
                                        toDelete = element
                                        showDelete.toggle()
                                    }, label: {
                                        Image(systemName: "trash").font(.subheadline).foregroundStyle(.red)
                                    })
                                    Button(action: {
                                        shuffleAvoid = "None |*^&^@$^"
                                        shuffleSquare = element
                                        withAnimation {
                                            showShuffle = true
                                        }
                                    }, label: {
                                        Image(systemName: "shuffle").font(.subheadline).foregroundStyle(.blue)
                                    })
                                }.padding(.leading, 20)
                            }
                        }
                        if let all = viewModel.subContainers.first(where: { $0.0 == viewModel.groups[index].1.id }){
                            ForEach(all.1){ element in
                                let nested = element.sub
                                HStack(spacing: 8){
                                    Image(systemName: "chevron.right")
                                    Text(element.name).font(.system(size: 16)).bold().lineLimit(1)
                                    if nested.isEmpty {
                                        Button(action: {
                                            toDelete = element.name
                                            showDelete.toggle()
                                        }, label: {
                                            Image(systemName: "trash").font(.subheadline).foregroundStyle(.red)
                                        })
                                    }
                                    Spacer()
                                }.padding(.top, 25)
                                ForEach(nested, id: \.self){ sec_element in
                                    HStack {
                                        ColorsCard(gradientColors: [pickedC[sec_element] ?? .orange, .black], size: 45)
                                        Text(sec_element).font(.system(size: 18)).lineLimit(1).minimumScaleFactor(0.7)
                                        Spacer()
                                        HStack(spacing: 18){
                                            Button(action: {
                                                toDelete = sec_element
                                                showDelete.toggle()
                                            }, label: {
                                                Image(systemName: "trash").font(.subheadline).foregroundStyle(.red)
                                            })
                                            Button(action: {
                                                shuffleAvoid = element.name
                                                shuffleSquare = sec_element
                                                withAnimation {
                                                    showShuffle = true
                                                }
                                            }, label: {
                                                Image(systemName: "shuffle").font(.subheadline).foregroundStyle(.blue)
                                            })
                                        }
                                    }.padding(.leading, 20)
                                }
                            }
                        }
                    }
                }.padding(.top, 30).padding(.horizontal)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
        }
    }
    func shuffleSub(square: String, moveToSub: String){
        if let index = viewModel.currentGroup {
            if !square.isEmpty && !moveToSub.isEmpty {
                if let squares = viewModel.groups[index].1.squares {
                    for i in 0..<squares.count {
                        if squares[i] == square {
                            viewModel.groups[index].1.squares?.remove(at: i)
                            addAll(square: square, moveToSub: moveToSub)
                            return
                        }
                    }
                }
                if let all = viewModel.subContainers.firstIndex(where: { $0.0 == viewModel.groups[index].1.id }) {
                    for i in 0..<viewModel.subContainers[all].1.count {
                        for j in 0..<viewModel.subContainers[all].1[i].sub.count {
                            if viewModel.subContainers[all].1[i].sub[j] == square {
                                viewModel.subContainers[all].1[i].sub.remove(at: j)
                                addAll(square: square, moveToSub: moveToSub)
                                return
                            }
                        }
                    }
                }
            }
        }
    }
    func addAll(square: String, moveToSub: String){
        if let index = viewModel.currentGroup {
            if moveToSub == "None |*^&^@$^" {
                if let squares = viewModel.groups[index].1.squares {
                    viewModel.groups[index].1.squares = squares + [square]
                } else {
                    viewModel.groups[index].1.squares = [square]
                }
            }else if let all = viewModel.subContainers.firstIndex(where: { $0.0 == viewModel.groups[index].1.id }) {
                if let position = viewModel.subContainers[all].1.firstIndex(where: { $0.name == moveToSub }) {
                    viewModel.subContainers[all].1[position].sub.append(square)
                }
            }
            
            let finalUpload = generateArr()
            if !finalUpload.isEmpty {
                ExploreService().addSquare(groupId: viewModel.groups[index].1.id, square: finalUpload)
            }
        }
    }
    func deleteSub(){
        if let index = viewModel.currentGroup {
            if let squares = viewModel.groups[index].1.squares {
                for i in 0..<squares.count {
                    if squares[i] == toDelete {
                        viewModel.groups[index].1.squares?.remove(at: i)
                        let finalUpload = generateArr()
                        if !finalUpload.isEmpty {
                            ExploreService().addSquare(groupId: viewModel.groups[index].1.id, square: finalUpload)
                        }
                        return
                    }
                }
            }
            if let all = viewModel.subContainers.firstIndex(where: { $0.0 == viewModel.groups[index].1.id }) {
                for i in 0..<viewModel.subContainers[all].1.count {
                    if viewModel.subContainers[all].1[i].name == toDelete {
                        viewModel.subContainers[all].1.remove(at: i)
                        let finalUpload = generateArr()
                        if !finalUpload.isEmpty {
                            ExploreService().addSquare(groupId: viewModel.groups[index].1.id, square: finalUpload)
                        }
                        return
                    } else {
                        for j in 0..<viewModel.subContainers[all].1[i].sub.count {
                            if viewModel.subContainers[all].1[i].sub[j] == toDelete {
                                viewModel.subContainers[all].1[i].sub.remove(at: j)
                                let finalUpload = generateArr()
                                if !finalUpload.isEmpty {
                                    ExploreService().addSquare(groupId: viewModel.groups[index].1.id, square: finalUpload)
                                }
                                return
                            }
                        }
                    }
                }
            }
        }
    }
    func createSub() -> some View {
        VStack {
            VStack{
                Text("Sub-Group Name").font(.title).bold()
            }.padding(.top, widthOrHeight(width: true) * 0.15)
            VStack {
                TextField("name...", text: $titleNew1)
                    .padding(.leading)
                    .onChange(of: titleNew1) { _ in
                        if justUploaded {
                            justUploaded = false
                        } else {
                            titleErr1 = inputChecker().myInputChecker(withString: titleNew1, withLowerSize: 1, withUpperSize: 25, needsLower: true)
                            if let index = viewModel.currentGroup {
                                if viewModel.groups[index].1.squares?.contains(":\(titleNew1)") ?? false {
                                    titleErr1 = "Sub-Group already exists."
                                }
                            }
                            if titleNew1.hasPrefix(":"){
                                titleErr1 = "Sub-Group cannot begin with :"
                            }
                        }
                    }
                    .frame(width: 230, height: 40)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5).stroke(.gray, lineWidth: 2)
                    }
            }.padding(.top)
            Text(titleErr1).font(.caption).foregroundColor(.red)
            Spacer()
            if let index = viewModel.currentGroup {
                if let all = viewModel.subContainers.first(where: { $0.0 == viewModel.groups[index].1.id })?.1 {
                    if all.contains(where: { $0.name == titleNew1 }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15).frame(height: 40)
                                .foregroundColor(.gray).opacity(0.7)
                            Text("Create").bold().font(.title2).foregroundColor(.white)
                        }.padding(.horizontal, 20).padding(.bottom, 10)
                    } else {
                        Button {
                            noRepeat()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15).frame(height: 40)
                                    .foregroundColor(titleErr1.isEmpty && !titleNew1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .blue : .gray).opacity(0.7)
                                Text("Create").bold().font(.title2).foregroundColor(.white)
                            }.padding(.horizontal, 20)
                        }.padding(.bottom, 10)
                    }
                } else {
                    Button {
                        noRepeat()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15).frame(height: 40)
                                .foregroundColor(titleErr1.isEmpty && !titleNew1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .blue : .gray).opacity(0.7)
                            Text("Create").bold().font(.title2).foregroundColor(.white)
                        }.padding(.horizontal, 20)
                    }.padding(.bottom, 10)
                }
            }
        }
    }
    func noRepeat(){
        if let index = viewModel.currentGroup {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            if !(viewModel.groups[index].1.squares?.contains(titleNew1) ?? false) && titleErr1 == "" && !titleNew1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                
                if let all = viewModel.subContainers.firstIndex(where: { $0.0 == viewModel.groups[index].1.id }) {
                    
                    viewModel.subContainers[all].1.append(subSquares(id: "\(UUID())", name: titleNew1, sub: [], show: false))
                    
                    let finalUpload = generateArr()
                    if !finalUpload.isEmpty {
                        ExploreService().addSquare(groupId: viewModel.groups[index].1.id, square: finalUpload)
                    }
                    justUploaded = true
                    titleNew1 = ""
                    titleErr1 = ""
                }
            }
        }
    }
    func uploadSquare(){
        if let index = viewModel.currentGroup, let all = viewModel.subContainers.firstIndex(where: { $0.0 == viewModel.groups[index].1.id }) {
            
            if selectedSubGroup == "None |*^&^@$^" {
                if let squares = viewModel.groups[index].1.squares {
                    viewModel.groups[index].1.squares = squares + [titleNew]
                } else {
                    viewModel.groups[index].1.squares = [titleNew]
                }
            } else if let position = viewModel.subContainers[all].1.firstIndex(where: {$0.name == selectedSubGroup }) {
                viewModel.subContainers[all].1[position].sub.append(titleNew)
            }
            let finalUpload = generateArr()
            
            if !finalUpload.isEmpty {
                ExploreService().addSquare(groupId: viewModel.groups[index].1.id, square: finalUpload)
            }
        }
    }
    func generateArr() -> [String] {
        if let index = viewModel.currentGroup, let all = viewModel.subContainers.first(where: { $0.0 == viewModel.groups[index].1.id }) {
            var sendBack = [String]()
            
            let noneSquares = viewModel.groups[index].1.squares ?? []
            noneSquares.forEach { element in
                sendBack.append(element)
            }
            all.1.forEach { element in
                sendBack.append(":\(element.name)")
                element.sub.forEach { small in
                    sendBack.append(small)
                }
            }
            
            return sendBack
        } else {
            return []
        }
    }
    func selectSubView() -> some View {
        ZStack {
            Color.gray.opacity(0.001).onTapGesture { withAnimation { showFinal = false } }
            VStack {
                Spacer()
                VStack {
                    VStack {
                        HStack {
                            Text("For Sub-Group").font(.system(size: 18)).bold()
                            Spacer()
                        }
                        VStack(spacing: 10){
                            Button(action: {
                                selectedSubGroup = "None |*^&^@$^"
                            }, label: {
                                Text("None").font(.system(size: 16))
                                    .foregroundStyle(selectedSubGroup == "None |*^&^@$^" ? .blue : .white)
                            })
                            if let index = viewModel.currentGroup, let all = viewModel.subContainers.first(where: { $0.0 == viewModel.groups[index].1.id }) {
                                ForEach(all.1){ element in
                                    Button(action: {
                                        selectedSubGroup = element.name
                                    }, label: {
                                        Text(element.name).font(.system(size: 16))
                                            .foregroundStyle(selectedSubGroup == element.name ? .blue : .white)
                                    })
                                }
                            }
                        }.padding(.vertical, 20)
                        Button(action: {
                            if !selectedSubGroup.isEmpty {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                withAnimation {
                                    showFinal = false
                                }
                                uploadSquare()
                                justUploaded = true
                                selectedSubGroup = ""
                                titleNew = ""
                                titleErr = ""
                            }
                        }, label: {
                            Text("Confirm").font(.system(size: 18)).bold()
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(.blue)
                                .clipShape(Capsule())
                        }).opacity(!selectedSubGroup.isEmpty ? 1.0 : 0.5)
                    }.padding()
                }
                .frame(width: 200)
                .background(colorScheme == .dark ? Color(UIColor.darkGray) : Color(UIColor.lightGray))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                Spacer()
            }
        }.transition(.move(edge: .bottom)).background(.ultraThinMaterial)
    }
    func createSquare() -> some View {
        VStack {
            VStack{
                Text("Square Name").font(.title).bold()
            }.padding(.top, widthOrHeight(width: true) * 0.15)
            VStack {
                TextField("name...", text: $titleNew)
                    .padding(.leading)
                    .onChange(of: titleNew) { _ in
                        if justUploaded {
                            justUploaded = false
                        } else {
                            titleErr = inputChecker().myInputChecker(withString: titleNew, withLowerSize: 1, withUpperSize: 25, needsLower: true)
                            if let index = viewModel.currentGroup {
                                if viewModel.groups[index].1.squares?.contains(titleNew) ?? false {
                                    titleErr = "Square already exists."
                                }
                            }
                            if titleNew == "Rules" || titleNew == "Info/Description" || titleNew == "Main" {
                                titleErr = "Square already exists."
                            }
                            if titleNew.hasPrefix(":"){
                                titleErr = "Square cannot begin with :"
                            }
                        }
                    }
                    .frame(width: 230, height: 40)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5).stroke(.gray, lineWidth: 2)
                    }
            }.padding(.top)
            Text(titleErr).font(.caption).foregroundColor(.red)
            Spacer()
            if let index = viewModel.currentGroup {
                Button {
                    if !(viewModel.groups[index].1.squares?.contains(titleNew) ?? false) && titleErr == "" && !titleNew.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation {
                            showFinal = true
                        }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15).frame(height: 40)
                            .foregroundColor((!(viewModel.groups[index].1.squares?.contains(titleNew) ?? false) && titleErr == "" && !titleNew.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .blue : .gray)).opacity(0.7)
                        Text("Create").bold().font(.title2).foregroundColor(.white)
                    }.padding(.horizontal, 20)
                }.padding(.bottom, 10)
            }
        }
    }
    func pickerView() -> some View {
        ZStack(alignment: .bottom){
            HStack {
                Button(action: {
                    selection = 0
                }, label: {
                    Text("+ Square").font(.system(size: 18))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                })
                Spacer()
            }.padding(.bottom, 6).padding(.leading, 20)
            HStack {
                Spacer()
                Button(action: {
                    selection = 1
                }, label: {
                    Text("+ Sub-Group").font(.system(size: 18))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                })
                Spacer()
            }.padding(.bottom, 6)
            HStack {
                Spacer()
                Button(action: {
                    selection = 2
                }, label: {
                    Text("Modify").font(.system(size: 18))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                })
            }.padding(.bottom, 6).padding(.trailing, 20)
            HStack {
                if selection == 1 || selection == 2 {
                    Spacer()
                }
                RoundedRectangle(cornerRadius: 20)
                    .frame(width: widthOrHeight(width: true) * 0.33, height: 3)
                    .foregroundStyle(.blue)
                    .animation(.easeInOut(duration: 0.2), value: selection)
                if selection == 0 || selection == 1 {
                    Spacer()
                }
            }
        }.padding(.top, 10)
    }
    func topView() -> some View {
        ZStack {
            Color(.orange).opacity(0.7).ignoresSafeArea()
            HStack {
                if selection == 0 {
                    Text("Create Square").font(.title2).bold()
                } else if selection == 1 {
                    Text("Create Sub-Group").font(.title2).bold()
                } else {
                    Text("Edit layout").font(.title2).bold()
                }
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
    }
}
