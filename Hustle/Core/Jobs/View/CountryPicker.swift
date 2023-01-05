import SwiftUI

func countryFlag(_ countryCode: String) -> String {
    String(String.UnicodeScalarView(countryCode.unicodeScalars.compactMap {
        UnicodeScalar(127397 + $0.value)
    }))
}

struct CountryPicker: View {
    @EnvironmentObject var auth: AuthViewModel
    @State var searchText: String = ""
    @State var country: String?
    @Binding var selectedCountry: String
    @Environment(\.colorScheme) var colorScheme
    let update: Bool
    let background: Bool
    @Binding var close: Bool
    var body: some View {
        ZStack {
            if background {
                Color(.gray).opacity(0.85).ignoresSafeArea().onTapGesture { close = false }
            }
            ZStack {
                RoundedRectangle(cornerRadius: 10).foregroundColor(.indigo)
                VStack{
                    Text("Select your Country").font(.system(size: 24)).bold().foregroundColor(.white)
                    ZStack{
                        SearchBar(text: $searchText, fill: "").tint(.blue)
                        if let selected = country {
                            HStack{
                                Spacer()
                                Button {
                                    selectedCountry = selected
                                    if update && selectedCountry != auth.currentUser?.userCountry ?? "" {
                                        withAnimation { auth.currentUser?.userCountry = selected }
                                        JobViewModel().updateCountry(country: selected)
                                    }
                                    close = false
                                } label: {
                                    Text("Save").font(.system(size: 14)).bold().foregroundColor(.white).padding(5).padding(.horizontal, 4).background(.blue).cornerRadius(5)
                                }
                            }.padding(.trailing, 5)
                        }
                    }.padding(.horizontal, 10)
                    Spacer()
                    List(NSLocale.isoCountryCodes, id: \.self) { countryCode in
                        if (Locale.current.localizedString(forRegionCode: countryCode) ?? "").lowercased().contains(searchText.lowercased()) || searchText.isEmpty {
                            ZStack {
                                if (country ?? "NA" == Locale.current.localizedString(forRegionCode: countryCode) ?? "") {
                                    Color.orange
                                }
                                Button {
                                    withAnimation {
                                        country = Locale.current.localizedString(forRegionCode: countryCode) ?? ""
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    HStack {
                                        Text(countryFlag(countryCode))
                                        Text(Locale.current.localizedString(forRegionCode: countryCode) ?? "")
                                    }
                                }
                            }
                        }
                    }
                    .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
                    .frame(width: widthOrHeight(width: true) * 0.76)
                    .listRowSeparatorTint(colorScheme == .dark ? .white : .black)
                    .listRowInsets(EdgeInsets())
                    .listStyle(PlainListStyle())
                    .padding(.bottom, 10)
                    .padding(.top, 5)
                }.padding(.top, 5)
            }.frame(width: widthOrHeight(width: true) * 0.8, height: 440)
        }
    }
}
