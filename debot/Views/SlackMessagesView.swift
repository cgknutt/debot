import SwiftUI

struct SlackMessagesView: View {
    @ObservedObject var viewModel: SlackViewModel
    @State private var composeSheetPresented = false
    @State private var scrollToBottom = false
    @State private var isLoadingMore = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Channel header
                HStack {
                    Text(viewModel.selectedChannel?.name ?? "Select a channel")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await viewModel.refreshMessages()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Pull to load more indicator
                            if viewModel.messages.count > 0 {
                                HStack {
                                    Spacer()
                                    if isLoadingMore {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Pull to load more")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                                .onAppear {
                                    Task {
                                        isLoadingMore = true
                                        await viewModel.loadMoreMessages()
                                        isLoadingMore = false
                                    }
                                }
                            }
                            
                            // Messages
                            ForEach(viewModel.messages) { message in
                                SlackMessageRow(message: message)
                                    .id(message.id)
                            }
                            
                            // Empty state
                            if viewModel.messages.isEmpty && !viewModel.isLoading {
                                VStack(spacing: 20) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    
                                    Text("No messages in this channel")
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.top, 100)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .onChange(of: viewModel.messages) { oldValue, newValue in
                        if oldValue.count < newValue.count && scrollToBottom {
                            if let lastMessage = newValue.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                            scrollToBottom = false
                        }
                    }
                }
                
                // Compose message area
                HStack {
                    Button(action: {
                        composeSheetPresented = true
                    }) {
                        HStack {
                            Image(systemName: "plus.message")
                                .foregroundColor(.white)
                            Text("New message")
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.6))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.black.opacity(0.7))
            }
            
            // Loading overlay
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4))
            }
        }
        .sheet(isPresented: $composeSheetPresented) {
            SlackComposeView(viewModel: viewModel)
        }
        .onAppear {
            scrollToBottom = true
            Task {
                await viewModel.refreshMessages()
            }
        }
    }
}

struct SlackMessageRow: View {
    let message: SlackMessage
    @ObservedObject var viewModel = SlackViewModel.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header with user info
            HStack(alignment: .top, spacing: 8) {
                // User avatar
                if let avatarUrl = message.userAvatar {
                    AsyncImage(url: avatarUrl) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 36, height: 36)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        case .failure:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(String(message.userName.prefix(1)).uppercased())
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .bold))
                                )
                        @unknown default:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 36, height: 36)
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(String(message.userName.prefix(1)).uppercased())
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold))
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    // Username and timestamp
                    HStack {
                        Text(message.userName)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(message.formattedTime)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Message text
                    Text(message.text)
                        .font(.body)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Attachments
                    if !message.attachments.isEmpty {
                        ForEach(message.attachments) { attachment in
                            SlackAttachmentView(attachment: attachment)
                        }
                    }
                    
                    // Reactions
                    if !message.reactions.isEmpty {
                        HStack {
                            ForEach(message.reactions) { reaction in
                                HStack(spacing: 4) {
                                    Text(reaction.name)
                                    Text("\(reaction.count)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.top, 4)
                    }
                    
                    // Thread indicator
                    if message.threadReplies > 0 {
                        Button(action: {
                            // Open thread view
                        }) {
                            Text("\(message.threadReplies) replies")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SlackAttachmentView: View {
    let attachment: SlackAttachment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = attachment.title {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            if let text = attachment.text {
                Text(text)
                    .font(.body)
                    .foregroundColor(.white)
            }
            
            if let imageUrl = attachment.imageUrl {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fit)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.white)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fit)
                    }
                }
                .cornerRadius(8)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(attachment.color ?? Color.gray, lineWidth: 4)
                        .padding(.leading, -2)
                )
        )
        .padding(.top, 4)
    }
} 