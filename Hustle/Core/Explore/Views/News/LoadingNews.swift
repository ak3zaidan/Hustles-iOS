import SwiftUI

struct LoadingNews: View {
    var body: some View {
        VStack(alignment: .leading){
            ZStack(alignment: .topLeading){
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(.gray).opacity(0.2)
                    .frame(height: 150)
                HStack(alignment: .top){
                    VStack(alignment: .leading, spacing: 8){
                        HStack(spacing: 4){
                            Capsule()
                                .foregroundColor(.black.opacity(0.7))
                                .frame(width: 80, height: 20)
                        }
                        .padding(.leading)
                        .padding(.bottom, 10)
                        Capsule()
                            .foregroundColor(.gray)
                            .frame(width: 170, height: 13)
                            .padding(.leading, 40)
                        Capsule()
                            .frame(width: 170, height: 13)
                            .foregroundColor(.gray)
                            .padding(.leading, 40)
                        Capsule()
                            .foregroundColor(.gray)
                            .frame(width: 170, height: 13)
                            .padding(.leading, 40)
                    }
                    .padding(.top, 5)
                    .padding(.leading, 5)
                    
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundColor(.gray)
                        .frame(width: 100, height: 100)
                        .padding(.top, 20)
                        .padding(.trailing, 8)
                }
            }
        }
    }
}
