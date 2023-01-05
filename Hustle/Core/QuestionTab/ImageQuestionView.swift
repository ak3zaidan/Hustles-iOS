import SwiftUI
import Kingfisher
import Firebase

struct ImageQuestionView: View {
    @EnvironmentObject var viewModel: QuestionModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var selection = true
    
    @State var imageHeightOne: Double = 0.0
    @State var imageWidthOne: Double = 0.0
    @State var imageHeightTwo: Double = 0.0
    @State var imageWidthTwo: Double = 0.0
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGPoint = .zero
    @State private var lastTranslation: CGSize = .zero

    @State private var showQuestion = false
    @State private var showAnswer = false
    @State private var selectedAnswer: Answer?
    @State private var canRefresh = true
    @State private var viewID = "\(UUID())"
    @State var showComments: Bool = false
        
    let question: Question
    let disableUser: Bool
    let shouldShowTab: Bool
    
    var body: some View {
        ZStack {
            if let url1 = question.image1 {
                GeometryReader { geometry in
                    KFImage(URL(string: url1))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(x: offset.x + (geometry.size.width - imageWidthOne) / 2.0, y: offset.y + (geometry.size.height - imageHeightOne) / 2.0)
                        .gesture(makeDragGesture(size: geometry.size))
                        .gesture(makeMagnificationGesture(size: geometry.size))
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .onChange(of: proxy.size.height) { _ in
                                        imageHeightOne = proxy.size.height
                                        imageWidthOne = proxy.size.width
                                    }

                            }
                        )
                        .onTapGesture(count: 2){
                            reset()
                        }
                }.zIndex(selection ? 2 : 0)
            }
            Rectangle().foregroundColor(.black).zIndex(1)
            if let url2 = question.image2 {
                GeometryReader { geometry in
                    KFImage(URL(string: url2))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(x: offset.x + (geometry.size.width - imageWidthTwo) / 2.0, y: offset.y + (geometry.size.height - imageHeightTwo) / 2.0)
                        .gesture(makeDragGesture(size: geometry.size))
                        .gesture(makeMagnificationGesture(size: geometry.size))
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .onChange(of: proxy.size.height) { _ in
                                        imageHeightTwo = proxy.size.height
                                        imageWidthTwo = proxy.size.width
                                    }

                            }
                        )
                        .onTapGesture(count: 2){
                            reset()
                        }
                }.zIndex(selection ? 0 : 2)
            }
            VStack {
                HStack {
                    Button {
                        if canRefresh {
                            canRefresh = false
                            viewModel.getAnswersForImageQ(questionID: question.id, refresh: true)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
                                canRefresh = true
                            }
                        }
                    } label: {
                        Image(systemName: "repeat").padding(10).foregroundColor(.white).background(.blue).cornerRadius(30)
                    }
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                        if shouldShowTab {
                            withAnimation(.spring()){
                                popRoot.hideTabBar = false
                            }
                        }
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Image(systemName: "xmark").padding(10).background(.gray)
                            .foregroundColor(.white).cornerRadius(30)
                    }
                }
                Spacer()
            }.padding(.horizontal).padding(.top, top_Inset() + 20).zIndex(5)
            
            VStack(spacing: 15){
                Spacer()
                HStack(spacing: 10){
                    Button {
                        showQuestion.toggle()
                    } label: {
                        TagView("Question", .gray, "questionmark")
                    }
                    Button {
                        showComments.toggle()
                    } label: {
                        TagView("", .gray, "ellipsis.message.fill")
                    }
                    Spacer()
                }
                if let element = viewModel.allQuestions.first(where: { $0.0 == question.id ?? "" }), element.1.count > 0 {
                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(Array(element.1.enumerated()), id: \.element.id) { index, answer in
                                Button {
                                    viewID = "\(UUID())"
                                    selectedAnswer = answer
                                    withAnimation {
                                        showAnswer.toggle()
                                    }
                                } label: {
                                    if let id1 = answer.id, let id2 = question.acceptedAnswer, id1 == id2 {
                                        TagView("Answer \(index + 1)", .green, "checkmark")
                                    } else if (viewModel.goodAnswers.first(where: { $0.0 == question.id ?? "" && $0.1 == answer.id ?? "" }) != nil) {
                                        TagView("Answer \(index + 1)", .green, "checkmark")
                                    } else {
                                        TagView("Answer \(index + 1)", .orange, "")
                                    }
                                }
                            }
                            Spacer()
                        }
                    }.scrollIndicators(.hidden).frame(height: 35)
                }
            }.zIndex(6).padding(.bottom, widthOrHeight(width: false) * 0.07).padding(.leading)
        }
        .sheet(isPresented: $showComments, content: {
            if #available(iOS 16.4, *){
                QuestionCommentView(question: question, canShowProfile: true, imageQ: true)
                    .presentationDetents([.medium, .large])
                    .presentationCornerRadius(40)
            } else {
                QuestionCommentView(question: question, canShowProfile: true, imageQ: true)
                    .presentationDetents([.medium, .large])
            }
        })
        .id(viewID)
        .onAppear {
            viewModel.getAnswersForImageQ(questionID: question.id, refresh: false)
        }
        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea()
        .sheet(isPresented: $showQuestion) {
            if #available(iOS 16.4, *) {
                QuestionForDisplay(question: question, disableUser: disableUser)
                    .presentationDetents([.medium, .large]).presentationCornerRadius(50)
            } else {
                QuestionForDisplay(question: question, disableUser: disableUser).presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $showAnswer) {
            if let answer = selectedAnswer {
                if #available(iOS 16.4, *) {
                    ImageAnswerRow(answer: answer, question: question, disableUser: disableUser)
                        .presentationCornerRadius(50).presentationDetents([.medium, .large])
                } else {
                    ImageAnswerRow(answer: answer, question: question, disableUser: disableUser)
                        .presentationDetents([.medium, .large])
                }
            }
        }
    }
    private func makeMagnificationGesture(size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                
                if abs(1 - delta) > 0.01 {
                    scale *= max(delta, 1/scale)
                }
            }
            .onEnded { _ in
                lastScale = 1
                if scale < 1 {
                    withAnimation {
                        scale = 1
                    }
                }
                adjustMaxOffset(size: size)
            }
    }
    func reset() {
        withAnimation {
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastTranslation = .zero
        }
    }
    private func makeDragGesture(size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let diff = CGPoint(
                    x: value.translation.width - lastTranslation.width,
                    y: value.translation.height - lastTranslation.height
                )
                if scale < 1.04 {
                    offset = .init(x: offset.x + diff.x, y: offset.y)
                    lastTranslation.width = value.translation.width
                } else {
                    offset = .init(x: offset.x + diff.x, y: offset.y + diff.y)
                    lastTranslation = value.translation
                }
            }
            .onEnded { value in
                if question.image2 != nil && abs(value.translation.width) > 100 && scale < 1.04 {
                    withAnimation {
                        selection.toggle()
                    }
                }
                adjustMaxOffset(size: size)
            }
    }
    private func adjustMaxOffset(size: CGSize) {
        let maxOffsetX = (size.width * (scale - 1)) / 2
        let maxOffsetY = (size.height * (scale - 1)) / 2
        
        var newOffsetX = offset.x
        var newOffsetY = offset.y

        if abs(newOffsetX) > maxOffsetX {
            newOffsetX = maxOffsetX * (abs(newOffsetX) / newOffsetX)
        }
        if abs(newOffsetY) > maxOffsetY {
            newOffsetY = maxOffsetY * (abs(newOffsetY) / newOffsetY)
        }

        let newOffset = CGPoint(x: newOffsetX, y: newOffsetY)
        if newOffset != offset {
            withAnimation {
                offset = newOffset
            }
        }
        self.lastTranslation = .zero
    }
    @ViewBuilder
    func TagView(_ tag: String, _ color: Color, _ icon: String) -> some View {
        HStack(spacing: 10) {
            if !tag.isEmpty {
                Text(tag).font(.callout).fontWeight(.semibold)
            }
            if !icon.isEmpty {
                Image(systemName: icon)
            }
        }
        .frame(height: 35)
        .foregroundStyle(.white)
        .padding(.horizontal, 15)
        .background {
            Capsule().fill(color.gradient).opacity(0.8)
        }
    }
}

struct ImageAnswerRow: View {
    @EnvironmentObject var viewModel: QuestionModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @Environment(\.colorScheme) var colorScheme
    let answer: Answer
    let question: Question
    let disableUser: Bool
    @State var delete: Bool = false
    @State var showApprove: Bool = false
    @State var dateFinal: String = "Answered recently"
    @State var showComments: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Answered by:").font(.system(size: 18))
                NavigationLink {
                    ProfileView(showSettings: false, showMessaging: true, uid: answer.id ?? "", photo: "", user: nil, expand: true, isMain: false)
                        .dynamicTypeSize(.large)
                } label: {
                    Text(answer.username).foregroundColor(.blue).font(.system(size: 18)).bold()
                    if let image = answer.profilePhoto {
                        KFImage(URL(string: image))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width:30, height: 30)
                            .clipShape(Circle())
                    } else {
                        ZStack(alignment: .center){
                            Image(systemName: "circle.fill")
                                .resizable()
                                .foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : .black)
                                .frame(width: 35, height: 35)
                            Image(systemName: "questionmark")
                                .resizable()
                                .foregroundColor(.white)
                                .frame(width: 12, height: 15)
                        }
                    }
                }.disabled(disableUser)
                if let id = answer.id, question.acceptedAnswer ?? "" != id {
                    if let uid = auth.currentUser?.id, id == uid {
                        if !viewModel.goodAnswers.contains(where: { $0.0 == question.id ?? "" && $0.1 == id }) {
                            Button {
                                delete.toggle()
                            } label: {
                                Image(systemName: "trash").scaleEffect(0.8).foregroundColor(.red)
                            }
                        }
                    }
                }
                if let id = auth.currentUser?.dev, id.contains("(DWK@)2))&DNWIDN:") {
                    Button {
                        delete.toggle()
                    } label: {
                        Image(systemName: "trash").scaleEffect(0.8).foregroundColor(.red)
                    }
                }
                Spacer()
                if let id = question.acceptedAnswer, let id2 = answer.id, id == id2 {
                    Image(systemName: "checkmark").foregroundColor(.green).bold().font(.title)
                } else if viewModel.goodAnswers.contains(where: { $0.0 == question.id ?? "" && $0.1 == answer.id ?? "" }) {
                    Image(systemName: "checkmark").foregroundColor(.green).bold().font(.title)
                } else if let id = auth.currentUser?.id, id == question.uid, question.acceptedAnswer == nil {
                    Button {
                        showApprove.toggle()
                    } label: {
                        Image(systemName: "checkmark").foregroundColor(.gray).bold().font(.title)
                    }
                }
            }.padding(.top, 20).padding(.horizontal)
            HStack {
                Text(dateFinal).foregroundColor(.gray).font(.subheadline)
                Spacer()
            }.padding(.horizontal)
            if let url = answer.image {
                HStack {
                    KFImage(URL(string: url))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipped()
                        .cornerRadius(15)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            popRoot.image = url
                            popRoot.showImage = true
                        }
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        downloadAndSaveImage(url: url)
                    } label: {
                        Image(systemName: "square.and.arrow.down.fill").foregroundColor(.white).font(.system(size: 20)).padding(8).background(.blue).clipShape(Circle())
                    }.padding(.leading, 10)
                    Button {
                        showComments.toggle()
                    } label: {
                        Image(systemName: "ellipsis.message.fill").foregroundColor(.white).font(.system(size: 20)).padding(8).background(.blue).clipShape(Circle())
                    }.padding(.leading, 10)
                    Spacer()
                }.padding(.top).padding(.leading, 40)
            } else {
                HStack(spacing: 5){
                    Button {
                        showComments.toggle()
                    } label: {
                        Text("Comments")
                        Image(systemName: "ellipsis.message.fill")
                    }.foregroundColor(.gray).font(.subheadline)
                    Spacer()
                }.padding(.horizontal)
            }
            VStack {
                HStack {
                    Text("Answer Description:").bold().font(.system(size: 19))
                    Spacer()
                }
                LinkedText(answer.caption, tip: false, isMess: nil).padding()
                    .background(.orange.opacity(0.3)).cornerRadius(20)
            }.padding(.horizontal, 20).padding(.top)
            Spacer()
        }
        .padding(.top, 20)
        .sheet(isPresented: $showComments, content: {
            if #available(iOS 16.4, *){
                QuestionCommentView(question: question, answer: answer, canShowProfile: true, imageQ: true)
                    .presentationDetents([.medium, .large])
                    .presentationCornerRadius(40)
            } else {
                QuestionCommentView(question: question, answer: answer, canShowProfile: true, imageQ: true)
                    .presentationDetents([.medium, .large])
            }
        })
        .alert("Options", isPresented: $delete) {
            Button("Delete Answer", role: .destructive) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                viewModel.deleteAnswer(id: question.id, id2: answer.id, image: answer.image)
                if let index = viewModel.allQuestions.firstIndex(where: { $0.0 == question.id }) {
                    viewModel.allQuestions[index].1.removeAll(where: { $0.id == answer.id })
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Confirm to accept this answer, this action is not reversable", isPresented: $showApprove) {
            Button("Confirm", role: .destructive) {
                viewModel.acceptAnswer(id: question.id, id2: answer.id)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if let id1 = question.id, let id2 = answer.id {
                    viewModel.goodAnswers.append((id1, id2))
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            let dateString = answer.timestamp.dateValue().formatted(.dateTime.month().day().year().hour().minute())
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "MMMM dd, yyyy 'at' h:mm a"
            if let date = dateFormatter.date(from:dateString){
                if Calendar.current.isDateInToday(date){
                    dateFinal = "Answered today at \(answer.timestamp.dateValue().formatted(.dateTime.hour().minute()))"
                }
                else if Calendar.current.isDateInYesterday(date) {
                    dateFinal = "Answered Yesterday"}
                else{
                    if let dayBetween  = Calendar.current.dateComponents([.day], from: answer.timestamp.dateValue(), to: Date()).day{
                        dateFinal = "Answered \(dayBetween + 1) days ago"
                    }
                }
            }
        }
    }
}
