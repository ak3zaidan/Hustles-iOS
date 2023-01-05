import SwiftUI

struct SearchGroupsView: View {
    @State private var viewTop = false
    @State private var showFullHeader = true
    @State private var offset: Double = 0
    @State private var offsetSec: Double = 0
    @State var search: String = ""
    @EnvironmentObject var viewModel: ExploreViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var focusField: FocusedField?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            ZStack {
                Image("backSearch")
                    .resizable()
                    .scaledToFill()
                    .blur(radius: headerBlur())
                    .clipped()
                VStack {
                    if showFullHeader {
                        ZStack {
                            HStack {
                                Button {
                                    presentationMode.wrappedValue.dismiss()
                                } label: {
                                    ZStack {
                                        Circle().foregroundStyle(.gray).frame(width: 37)
                                        Image(systemName: "arrow.backward").bold()
                                    }
                                }
                                Spacer()
                            }
                            HStack {
                                Spacer()
                                if (auth.currentUser?.elo ?? 0 >= 600 || auth.currentUser?.groupIdentifier == nil) {
                                    NavigationLink {
                                        CreateGroupView()
                                    } label: {
                                        ZStack {
                                            Circle().foregroundStyle(.gray).frame(width: 37)
                                            Image(systemName: "lock.open").bold()
                                        }
                                    }
                                }
                            }
                            Text("Find a Channel")
                                .font(.title2).foregroundStyle(.black).bold()
                        }
                    }
                    TextField("", text: $search)
                        .submitLabel(.search)
                        .focused($focusField, equals: .one)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(.white)
                        .foregroundStyle(.black)
                        .tint(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onSubmit {
                            if !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                viewModel.getSearchGroups(query: search)
                            }
                        }
                        .overlay {
                            if search.isEmpty {
                                HStack {
                                    Text("Search Groups")
                                        .font(.headline)
                                        .foregroundStyle(.gray)
                                    Spacer()
                                    Image(systemName: "magnifyingglass")
                                        .font(.headline).foregroundStyle(.black)
                                }
                                .padding(.horizontal)
                                .onTapGesture {
                                    focusField = .one
                                }
                            } else if viewModel.submittedSearch {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(.gray)
                                        .foregroundStyle(.gray)
                                }
                                .padding(.trailing)
                                .onTapGesture {
                                    focusField = .one
                                }
                            }
                        }
                }.padding(.horizontal, 30).padding(.top, 30).padding(.top, showFullHeader ? 0 : 20)
            }.frame(height: showFullHeader ? 200 : 100)
            ScrollView {
                let all = viewModel.matchedG + viewModel.exploreGroups
                if all.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 18){
                            Text("Couldn't locate any Groups...")
                                .gradientForeground(colors: [.blue, .purple])
                                .font(.headline).bold()
                            LottieView(loopMode: .playOnce, name: "nofound")
                                .scaleEffect(0.3)
                                .frame(width: 100, height: 100)
                        }
                        Spacer()
                    }.padding(.top, 70)
                } else {
                    HStack {
                        Spacer()
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            ForEach(all){ group in
                                NavigationLink {
                                    GroupView(group: group, imageName: "", title: "", remTab: true, showSearch: false)
                                        .onAppear {
                                            withAnimation {
                                                self.popRoot.hideTabBar = true
                                            }
                                        }
                                        .onDisappear {
                                            withAnimation {
                                                self.popRoot.hideTabBar = false
                                            }
                                        }
                                } label: {
                                    GroupFindRow(group: group)
                                }
                            }
                        }
                        .padding(.top)
                        .background(GeometryReader {
                            Color.clear.preference(key: ViewOffsetKey.self,
                                                   value: -$0.frame(in: .named("scroll")).origin.y)
                        })
                        .onPreferenceChange(ViewOffsetKey.self) { value in
                            offset = value
                            if all.count > 4 {
                                if value > (offsetSec + 80) {
                                    offsetSec = value
                                    withAnimation(.easeIn(duration: 0.15)){
                                        showFullHeader = false
                                    }
                                }
                                if value < 15 {
                                    offsetSec = value
                                    withAnimation(.easeIn(duration: 0.15)){
                                        showFullHeader = true
                                    }
                                }
                            }
                        }
                        Spacer()
                    }
                    Color.clear.frame(height: 120)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .background(colorScheme == .dark ? .black : .white)
            .coordinateSpace(name: "scroll")
            .scrollIndicators(.hidden)
        }
        .navigationBarBackButtonHidden()
        .ignoresSafeArea()
        .onChange(of: search) { _ in
            viewModel.matchedG = viewModel.matchedG.sorted { element1, element2 in
                let similarityFirst = search.localizedCaseInsensitiveCompare(element1.title).rawValue
                let similaritySecond = search.localizedCaseInsensitiveCompare(element2.title).rawValue
                return similarityFirst < similaritySecond
            }
        }
        .onAppear {
            viewTop = true
            if viewModel.exploreGroups.isEmpty {
                viewModel.get10GroupCovers(groupId: auth.currentUser?.groupIdentifier ?? [], joinedGroups: auth.currentUser?.pinnedGroups ?? [])
            }
        }
        .onDisappear { viewTop = false }
        .onChange(of: popRoot.tap) { _ in
            if (popRoot.tap == 3 || popRoot.tap == 5) && viewTop {
                presentationMode.wrappedValue.dismiss()
                popRoot.tap = 0
            }
        }
    }
    func headerBlur() -> CGFloat {
        let final = abs(offset)
        if final >= 60 {
            return 8.0
        }
        let ratio = final / 60
        
        return ratio * 8.0
    }
}
