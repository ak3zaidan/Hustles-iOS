//
//  SwiftUIView.swift
//  Hustle
//
//  Created by Ahmed Zaidan on 8/31/23.
//

import SwiftUI

struct SwiftUIView: View {
    @State private var showDetails = false
    var body: some View {
        VStack {
            Button("Press to show details") {
                withAnimation {
                    showDetails.toggle()
                }
            }
            

            if showDetails {

                Text("Details go here.").foregroundColor(.black)
                    .transition(.move(edge: .bottom))

            }
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
