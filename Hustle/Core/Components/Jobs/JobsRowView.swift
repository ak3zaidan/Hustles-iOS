import SwiftUI
import Kingfisher

struct JobsRowView: View {
    @State private var showDeveloperOptions: Bool = false
    let canShowProfile: Bool
    let remote: Bool
    var job: Tweet
    let is100: Bool
    let canMessage: Bool
    @State var dateFinal: String = ""
    @State var promoted: String = ""
    @State var showComplete: Bool = false
    @State var showOptions: Bool = false
    @State var showDelete: Bool = false
    @State var showGlobe: Bool = false
    @EnvironmentObject var popRoot: PopToRoot
    @StateObject var viewModel = JobViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    let generator = UINotificationFeedbackGenerator()
    @State var showReport: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top, spacing: 12){
                VStack {
                    if canShowProfile {
                        NavigationLink {
                            ProfileView(showSettings: false, showMessaging: true, uid: job.uid, photo: job.profilephoto ?? "", user: nil, expand: true, isMain: false)
                                .dynamicTypeSize(.large)
                        } label: {
                            if let image = job.profilephoto {
                                ZStack {
                                    personView(size: 56)
                                    KFImage(URL(string: image))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width:56, height: 56)
                                        .clipShape(Circle())
                                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                }
                            } else {
                                personView(size: 56)
                            }
                        }
                    } else {
                        if let image = job.profilephoto {
                            ZStack {
                                personView(size: 56)
                                KFImage(URL(string: image))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width:56, height: 56)
                                    .clipShape(Circle())
                                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                            }
                        } else {
                            personView(size: 56)
                        }
                    }
                    if !remote {
                        Spacer()
                        Button {
                            showGlobe.toggle()
                        } label: {
                            Image(systemName: "globe").foregroundColor(.blue).font(.system(size: 26))
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 0){
                    HStack {
                        if canShowProfile {
                            NavigationLink {
                                ProfileView(showSettings: false, showMessaging: true, uid: job.uid, photo: job.profilephoto ?? "", user: nil, expand: true, isMain: false)
                                    .dynamicTypeSize(.large)
                            } label: {
                                Text("@\(job.username)").font(.title3).bold()
                            }
                        } else {
                            Text("@\(job.username)").font(.title3).bold()
                        }
                        Spacer()
                        if let id = authViewModel.currentUser?.id, job.start == nil {
                            Button {
                                if id == job.uid {
                                    showOptions.toggle()
                                } else {
                                    showReport.toggle()
                                }
                            } label: {
                                Image(systemName: "ellipsis").font(.system(size: 25))
                            }
                        }
                    }
                    HStack{
                        Text(dateFinal)
                            .foregroundColor(.gray)
                            .font(.caption)
                            .onAppear {
                                let dateString = job.timestamp.dateValue().formatted(.dateTime.month().day().year().hour().minute())
                                let dateFormatter = DateFormatter()
                                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                                dateFormatter.dateFormat = "MMMM dd, yyyy 'at' h:mm a"
                                if let date = dateFormatter.date(from:dateString){
                                    if Calendar.current.isDateInToday(date){
                                        dateFinal = job.timestamp.dateValue().formatted(.dateTime.hour().minute())}
                                    else if Calendar.current.isDateInYesterday(date) {dateFinal = "Yesterday"}
                                    else{
                                        if let dayBetween  = Calendar.current.dateComponents([.day], from: job.timestamp.dateValue(), to: Date()).day{
                                            dateFinal = String(dayBetween + 1) + "d"
                                        }
                                    }
                                }
                            }
                            .onLongPressGesture(minimumDuration: 2.0) {
                                if let id = authViewModel.currentUser?.dev {
                                    if id.contains("(DWK@)2))&DNWIDN:"){
                                        showDeveloperOptions = true
                                    }
                                }
                            }
                        RoundedRectangle(cornerRadius: 5)
                            .frame(width: 60, height: 20)
                            .foregroundColor(.orange).opacity(0.7)
                            .overlay(Text(self.remote ? "Remote" : "Local").font(.caption))
                        if !promoted.isEmpty {
                            RoundedRectangle(cornerRadius: 5)
                                .frame(width: 65, height: 20)
                                .foregroundColor(.orange).opacity(0.7)
                                .overlay(Text("Promoted").font(.caption).bold())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    VStack(alignment: .leading, spacing: 4){
                        Text(job.tag ?? "")
                            .font(.system(size: 18)).bold()
                            .multilineTextAlignment(.leading)
                        LinkedText(job.caption, tip: false, isMess: nil)
                            .font(.system(size: 16))
                            .multilineTextAlignment(.leading)
                            .padding(.top, 2)
                    }.padding(.top, 5)
                    if let jobImage = job.image{
                        if jobImage != "" {
                            HStack{
                                Spacer()
                                KFImage(URL(string: jobImage))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 250)
                                    .cornerRadius(5)
                                    .onTapGesture {
                                        popRoot.image = jobImage
                                        popRoot.showImage = true
                                    }
                                Spacer()
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            HStack{
                if let id = authViewModel.currentUser?.id {
                    if id != job.uid {
                        NavigationLink(){
                            MessagesView(exception: true, user: nil, uid: job.uid, tabException: true, canCall: true)
                                .onAppear {
                                    withAnimation(.spring()){
                                        self.popRoot.hideTabBar = true
                                    }
                                }
                        } label: {
                            HStack(spacing: 1){
                                Text("text").font(.subheadline)
                                Image(systemName: "message").font(.subheadline)
                            }
                        }.disabled(!canMessage)
                    }
                }
                Spacer()
                if let link = job.web, let url = URL(string: link) {
                    Link(destination: url) {
                        HStack(spacing: 3){
                            Image(systemName: "arrow.up.forward.app")
                                .resizable()
                                .frame(width: 17, height: 17)
                                .foregroundColor(.blue)
                            Text("Apply").foregroundColor(.blue).font(.subheadline)
                        }
                    }
                }
            }
            .padding((job.web != nil || authViewModel.currentUser?.id ?? "" != job.uid) ? 7 : 2)
            .foregroundColor(.gray)
            Divider().overlay(colorScheme == .dark ? Color(red: 220/255, green: 220/255, blue: 220/255) : .gray)
        }
        .sheet(isPresented: $showGlobe) {
            if let loc = job.appIdentifier {
                let components = loc.components(separatedBy: ",")
                ZStack(alignment: .bottom){
                    MapView(city: components[2], state: components[1], country: components[0], is100: is100).presentationDetents([.fraction(0.85)]).ignoresSafeArea()
                    Button {
                        showGlobe = false
                    } label: {
                        ZStack{
                            Text("Close").foregroundColor(colorScheme == .light ? .white : .black).bold()
                                .frame(width: 200, height: 45)
                                .background {
                                    TransparentBlurView(removeAllFilters: true)
                                        .blur(radius: 9, opaque: true)
                                        .background(colorScheme == .light ? .black.opacity(0.2) : .white.opacity(0.2))
                                }
                                .cornerRadius(10)
                        }
                    }.padding(.bottom)
                }
            }
        }
        .sheet(isPresented: $showComplete) {
            CompleteJobView(job: job)
        }
        .alert("Options", isPresented: $showOptions) {
            if dateFinal.contains("Yesterday") || dateFinal.contains("d") {
                Button("Complete Job", role: .destructive) {
                    showComplete.toggle()
                }
            }
            Button("Delete", role: .destructive) {
                showDelete.toggle()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Are you sure you want to delete this job", isPresented: $showDelete) {
            Button("Delete", role: .destructive) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                viewModel.deleteJob(job: job)
                popRoot.show = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Report this content?", isPresented: $showReport) {
            Button("Report", role: .destructive) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if let id = job.id {
                    UserService().reportContent(type: "Job", postID: id)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            if let dateTo = job.promoted {
                if dateTo.dateValue() > Date() {
                    promoted = "_Promoted_"
                }
            }
        }
        .alert("Dev Options", isPresented: $showDeveloperOptions) {
            Button("User ID", role: .destructive) {
                UIPasteboard.general.string = job.uid
            }
            Button("Job ID", role: .destructive) {
                UIPasteboard.general.string = job.id ?? ""
            }
            Button("Delete", role: .destructive) {
                viewModel.deleteJob(job: job)
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
