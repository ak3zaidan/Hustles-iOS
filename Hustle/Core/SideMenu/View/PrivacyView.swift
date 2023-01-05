import SwiftUI

struct PrivacyView: View {
    @EnvironmentObject var popRoot: PopToRoot
    @Environment(\.presentationMode) var presentationMode
    @State private var viewIsTop = false
    var body: some View {
        VStack {
            ZStack(alignment: .leading){
                Color(.orange)
                    .ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20){
                    HStack{
                        Text("Privacy Policy").font(.title).bold()
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
                    }
                    .padding(.horizontal, 25)
                    .padding(.top)
                }
            }.frame(height: 80)
            
            ScrollView{
                LinkedText("An up to date copy of our privacy policy can be located here: https://hustle.page/legal/. You can also view our Terms Of Use/Service here: https://hustle.page/terms-of-use/", tip: false, isMess: nil)
                    .padding(.top, 20)
                    .padding(.horizontal, 25)
                
                HStack{
                    Text("Your Data").font(.title3).bold()
                    Spacer()
                }
                .padding(.top, 15)
                .padding(.leading)
                
                Text("To keep your data private, we do not sell or distribute your data or information to any 3rd party.")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.top, 10)
                    .padding(.horizontal, 25)
                
                HStack{
                    Text("Information We Collect").font(.title3).bold()
                    Spacer()
                }
                .padding(.top, 30)
                .padding(.leading)
                
                Text("The data we gather concerning your device usage with our products can be categorized into a single classification. In order to enhance the user experience, we utilize user location information to present relevant job opportunities in proximity to their geographic region. Access to user location is contingent upon the user's permission, and we do not obtain this data unless granted explicit consent. Additionally, we access the visual appearance settings of your mobile device (light or dark mode) to ensure a seamless and user-friendly interface. During your usage of our products, we collect and securely store various data pertaining to your account, including uploads, jobs, marketplace items, questions, answers, likes, comments, messages, sent photos, profile pictures, user identifiers (such as full name and username), marketplace listings, and tips. This collected data empowers us to deliver our utmost service quality. The data originating from your device undergoes encryption before transmission and subsequently remains securely stored. You retain control over this data, as you have the option to delete specific posts or delete your entire account. In order to delete messages from a specific conversation, navigate to the chat and long press on the desired message, this will display an option to delete that particular message. To delete a whole conversation execute a left-swipe gesture on the designated chat within the platform. It is important to note that deleting the conversation on your end will not delete messages permanently if the counterpart you were messaging has not deleted the conversation as well. To ensure the comprehensive deletion of a particular conversation, it is advised to request the other party to undertake the same action of deleting the conversation on their end. Should you suspect that the content of the conversation infringes upon your legal rights, we encourage you to notify our customer service team for further assistance. It should be noted that 'Tips' are not directly accessible for deletion by users. Should you wish to delete a tip that you have posted, you will be required to contact our customer service department for necessary support and resolution. Opinions and replies posted by users are not directly accessible for deletion. However these uploads are automatically deleted in 2-4 day cycles as the News on our platform change. The singular piece of data that falls under the exception of non-deletion pertains to accepted answers. It is imperative to recognize that you retain complete autonomy to delete any answer posted by you, contingent upon its non-acceptance. However, it is incumbent upon us to elucidate that in the event of the question's owner accepting your response, the prerogative of deletion becomes obsolete. It is consequential to acknowledge that upon submission of a response, you voluntarily relinquish your entitlement to delete said answer, should it garner the aforementioned endorsement. If, however, you believe that the answer infringes upon your rights, we recommend contacting our customer service for resolution.It is important to note that your data is not shared with members, companies, or organizations who upload advertisements on the Hustler Platform.")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.top, 10)
                    .padding(.horizontal, 25)
                
                HStack {
                    Text("Managing your Data").font(.title3).bold()
                    Spacer()
                }
                .padding(.top, 30)
                .padding(.leading)
                
                Text("We keep different types of information, for different amounts of times.")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.top, 10)
                    .padding(.horizontal, 25)
                Text("Profile information is saved for the duration of your account. Information surrounding uploads (hustles, jobs, comments, tips, collections, Opinions, marketplace listings) are kept for the duration of that post/thread. You can take control of your data by deleting or editing your uploads. Deleting your account will result in your personal data to be deleted. However violations may result in data (phone number, name, email) to be held for a longer period to help prevent future violations. We may keep certain information longer to comply with legal requirements, security, and safety reasons.")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
                    .padding(.bottom)
                    .padding(.horizontal, 25)
            }
        }
        .navigationBarBackButtonHidden(true)
        .padding(.bottom, 45)
        .onChange(of: popRoot.tap, perform: { _ in
            if popRoot.tap == 6 && viewIsTop {
                presentationMode.wrappedValue.dismiss()
                popRoot.tap = 0
            }
        })
        .onAppear { viewIsTop = true }
        .onDisappear { viewIsTop = false }
    }
}
