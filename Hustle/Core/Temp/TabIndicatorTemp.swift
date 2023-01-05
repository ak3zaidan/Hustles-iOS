import SwiftUI

#Preview {
    SwiftUIView()
}

struct SwiftUIView: View {
    @State private var selectedTab: TabProfile?
    @State private var tabProgress: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    let counts: [TabProfile.RawValue : Int] =  ["Hustles" : 20, "Jobs" : 2, "Likes" : 20]
    
    var body: some View {
        VStack(alignment: .leading){
            Color.red.frame(height: 100)
                .overlay {
                    Text("Header").foregroundStyle(.white)
                        .offset(y: 20).bold()
                }
            GeometryReader {
                let size = $0.size
                
                ScrollViewReader(content: { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                            
                            Color.blue.frame(height: 100)
                                .overlay {
                                    Text("Some content").foregroundStyle(.white).bold()
                                }
                            Section(header: buttonTab().id("top")) {
                                ScrollView(.horizontal) {
                                    LazyHStack(alignment: .top, spacing: 0) {
                                    
                                        SampleView(.purple, count: counts["Hustles"] ?? 20)
                                            .id(TabProfile.hustles)
                                            .containerRelativeFrame(.horizontal)
                                        
                                        SampleView(.red, count: counts["Jobs"] ?? 2)
                                            .id(TabProfile.jobs)
                                            .containerRelativeFrame(.horizontal)
                                        
                                        SampleView(.blue, count: counts["Likes"] ?? 20)
                                            .id(TabProfile.likes)
                                            .containerRelativeFrame(.horizontal)
                                    }
                                    .scrollTargetLayout()
                                    .offsetX { value in
                                        let progress = -value / (size.width * CGFloat(TabProfile.allCases.count - 1))
                                        tabProgress = max(min(progress, 1), 0)
                                    }
                                }
                                .scrollPosition(id: $selectedTab)
                                .scrollIndicators(.hidden)
                                .scrollTargetBehavior(.viewAligned)
                                .scrollClipDisabled()
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: selectedTab) { oldValue, newValue in
                        let old = counts[oldValue?.rawValue ?? ""] ?? 0
                        let new = counts[newValue?.rawValue ?? ""] ?? 0
                        
                        if old > new {
                            withAnimation { proxy.scrollTo("top", anchor: .top) }
                        }
                    }
                })
            }
        }
        .ignoresSafeArea()
    }
    func buttonTab() -> some View {
        HStack(spacing: 0) {
            ForEach(TabProfile.allCases, id: \.rawValue) { tab in
                HStack(spacing: 10) {
                    Text(tab.rawValue)
                        .font(.callout)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .contentShape(.capsule)
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.snappy) {
                        selectedTab = tab
                    }
                }
            }
        }
        .tabMask(tabProgress, tabCount: TabProfile.allCases.count)
        .padding(.horizontal, 8)
        .background {
            GeometryReader {
                let size = $0.size
                let capusleWidth = size.width / CGFloat(TabProfile.allCases.count)
                ZStack(alignment: .leading){
                    RoundedRectangle(cornerRadius: 0)
                        .fill(.gray)
                        .frame(height: 1)
                        .offset(y: 40)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.blue)
                        .frame(width: capusleWidth, height: 2)
                        .offset(x: tabProgress * (size.width - capusleWidth), y: 40)
                }
            }
        }
        .background(colorScheme == .dark ? .black : .white)
    }
    @ViewBuilder
    func SampleView(_ color: Color, count: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 2), content: {
            ForEach(1...count, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 15)
                    .fill(color.gradient)
                    .frame(height: 150)
            }
        }).padding(15)
    }
}

enum TabProfile: String, CaseIterable {
    case hustles = "Hustles"
    case jobs = "Jobs"
    case likes = "Likes"
    case sale = "4Sale"
    case question = "???"
}
