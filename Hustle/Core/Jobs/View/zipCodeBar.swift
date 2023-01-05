import SwiftUI

struct zipCodeBar: View {
    @Binding var text: String
    var body: some View {
        HStack {
            TextField("ZipCode/City", text: $text)
                .padding(2)
                .padding(.horizontal, 32)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack{
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                    }
                )
        }.padding(.horizontal, 4)
    }
}
