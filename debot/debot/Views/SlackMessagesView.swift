import SwiftUI

struct SlackMessagesView: View {
    @ObservedObject private var viewModel: SlackViewModel
    @Environment(\.themeColors) var colors
    
    @State private var selectedChannelId: String? = nil
    @State private var searchText: String = ""
    @State private var messageText: String = ""
    @State private var showingReactionPicker: Bool = false
    @State private var reactionTargetMessage: String? = nil
    @State private var showingThreadView: Bool = false
    @State private var threadParentId: String? = nil
    @State private var threadMessage: String = ""
    @State private var isComposing: Bool = false
    
    init(viewModel: SlackViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            
            // Filter and Search Bar
            filterAndSearchBar
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            
            // Messages
            if viewModel.isLoading && viewModel.messages.isEmpty {
                LoadingView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                errorView(error: error)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredMessages.isEmpty {
                emptyStateView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ZStack {
                    messageList
                    
                    // Thread view as sheet
                    if showingThreadView, let threadId = threadParentId {
                        threadView(parentId: threadId)
                            .transition(.move(edge: .trailing))
                    }
                }
            }
            
            // Message Composition Area
            if selectedChannelId != nil && !showingThreadView {
                messageCompositionArea
            }
        }
        .background(colors.background)
        .onAppear {
            refreshMessages()
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Slack Messages")
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundColor(colors.text)
            
            Spacer()
            
            Toggle(isOn: $viewModel.useMockData) {
                Text("Mock")
                    .font(.system(size: 12))
                    .foregroundColor(colors.secondaryText)
            }
            .toggleStyle(SwitchToggleStyle(tint: colors.accent))
            .frame(width: 90)
            
            Button(action: {
                Task {
                    let result = await viewModel.testAPIConnection()
                    print(result)
                }
            }) {
                Image(systemName: "network")
                    .font(.system(size: 20))
                    .foregroundColor(colors.accent)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            if viewModel.unreadCount > 0 {
                Text("\(viewModel.unreadCount)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.debotOrange)
                    .clipShape(Capsule())
            }
            
            Button(action: {
                viewModel.markAllAsRead()
            }) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 20))
                    .foregroundColor(colors.accent)
            }
            .buttonStyle(BorderlessButtonStyle())
            .disabled(viewModel.unreadCount == 0)
            .opacity(viewModel.unreadCount == 0 ? 0.5 : 1.0)
            
            Button(action: {
                refreshMessages()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 20))
                    .foregroundColor(colors.accent)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
    
    private var filterAndSearchBar: some View {
        VStack(spacing: 8) {
            // Channel selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    channelButton(nil, name: "All")
                    
                    ForEach(Array(viewModel.channels.keys.sorted()), id: \.self) { channelId in
                        if let channelName = viewModel.channels[channelId] {
                            channelButton(channelId, name: channelName)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(colors.secondaryText)
                
                TextField("Search messages", text: $searchText)
                    .foregroundColor(colors.text)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(colors.secondaryText)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding(8)
            .background(colors.cardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(colors.divider, lineWidth: 1)
            )
        }
    }
    
    private func channelButton(_ channelId: String?, name: String) -> some View {
        Button(action: {
            withAnimation {
                selectedChannelId = channelId
            }
        }) {
            Text("#\(name)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(selectedChannelId == channelId ? .white : colors.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedChannelId == channelId ? colors.accent : colors.cardBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(colors.divider, lineWidth: selectedChannelId == channelId ? 0 : 1)
                )
        }
        .buttonStyle(BorderlessButtonStyle())
    }
    
    private var messageList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredMessages) { message in
                    messageRow(message)
                        .onTapGesture {
                            viewModel.markAsRead(messageId: message.id)
                        }
                        .contextMenu {
                            messageContextMenu(message)
                        }
                }
            }
            .padding(12)
        }
    }
    
    private func messageRow(_ message: SlackMessage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Message header
            HStack {
                // User avatar placeholder
                Circle()
                    .fill(colors.accent)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(message.userName.prefix(1)))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(message.userName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(colors.text)
                        
                        Text("in #\(message.channelName)")
                            .font(.system(size: 13))
                            .foregroundColor(colors.secondaryText)
                        
                        Spacer()
                        
                        Text(formatDate(message.timestamp))
                            .font(.system(size: 12))
                            .foregroundColor(colors.secondaryText)
                    }
                    
                    if !message.isRead {
                        HStack {
                            Circle()
                                .fill(Color.debotOrange)
                                .frame(width: 8, height: 8)
                            
                            Text("New")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.debotOrange)
                        }
                    }
                }
            }
            
            // Message content
            Text(message.text)
                .font(.system(size: 15))
                .foregroundColor(colors.text)
                .padding(.leading, 44)
            
            // Attachments
            if !message.attachments.isEmpty {
                ForEach(message.attachments) { attachment in
                    attachmentView(attachment)
                        .padding(.leading, 44)
                }
            }
            
            // Thread indicator
            if message.isThreadParent {
                Button(action: {
                    threadParentId = message.id
                    showingThreadView = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 12))
                        
                        Text("\(message.replyCount ?? 0) \(message.replyCount == 1 ? "reply" : "replies")")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(colors.accent)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(colors.secondaryBackground.opacity(0.5))
                    .cornerRadius(12)
                    .padding(.leading, 44)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
            // Reactions
            if let reactions = message.reactions, !reactions.isEmpty {
                HStack(spacing: 4) {
                    ForEach(reactions, id: \.name) { reaction in
                        Button(action: {
                            Task {
                                await viewModel.addReaction(name: reaction.name, messageId: message.id, channelId: message.channelId)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(emojiFromName(reaction.name))
                                Text("\(reaction.count)")
                                    .font(.system(size: 12))
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .background(colors.secondaryBackground.opacity(0.5))
                            .cornerRadius(12)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    
                    // Add reaction button
                    Button(action: {
                        reactionTargetMessage = message.id
                        showingReactionPicker = true
                    }) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 12))
                            .padding(6)
                            .background(colors.secondaryBackground.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.leading, 44)
            } else {
                // Just add reaction button if no reactions yet
                Button(action: {
                    reactionTargetMessage = message.id
                    showingReactionPicker = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "face.smiling")
                        Text("Add Reaction")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(colors.secondaryText)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(colors.secondaryBackground.opacity(0.3))
                    .cornerRadius(12)
                    .padding(.leading, 44)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(12)
        .background(colors.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(message.isRead ? colors.divider : colors.accent, lineWidth: 1)
        )
        .sharedFlightGlassEffect()
        .sheet(isPresented: $showingReactionPicker) {
            reactionPickerView()
        }
    }
    
    private var messageCompositionArea: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(alignment: .bottom, spacing: 8) {
                if isComposing {
                    Button(action: {
                        messageText = ""
                        isComposing = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(colors.secondaryText)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                
                ZStack(alignment: .leading) {
                    if messageText.isEmpty {
                        Text("Message \(selectedChannelName)")
                            .foregroundColor(colors.secondaryText)
                            .padding(.leading, 4)
                            .padding(.top, 8)
                    }
                    
                    TextField("", text: $messageText, axis: .vertical)
                        .lineLimit(1...5)
                        .padding(4)
                        .onChange(of: messageText) { _ in
                            isComposing = !messageText.isEmpty
                        }
                }
                .padding(8)
                .background(colors.cardBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(colors.divider, lineWidth: 1)
                )
                
                Button(action: {
                    sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(isComposing ? colors.accent : colors.secondaryText)
                        .font(.system(size: 20))
                        .padding(8)
                }
                .disabled(!isComposing)
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(colors.cardBackground)
    }
    
    private func threadView(parentId: String) -> some View {
        let threadMessages = viewModel.getThreadMessages(parentId: parentId)
        
        return VStack(spacing: 0) {
            // Thread header
            HStack {
                Button(action: {
                    showingThreadView = false
                    threadParentId = nil
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18))
                        .foregroundColor(colors.accent)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Text("Thread")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(colors.text)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(colors.cardBackground)
            
            // Thread messages
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(threadMessages) { message in
                        messageRow(message)
                    }
                }
                .padding(12)
            }
            
            // Thread reply composition
            HStack(alignment: .bottom, spacing: 8) {
                ZStack(alignment: .leading) {
                    if threadMessage.isEmpty {
                        Text("Reply in thread")
                            .foregroundColor(colors.secondaryText)
                            .padding(.leading, 4)
                            .padding(.top, 8)
                    }
                    
                    TextField("", text: $threadMessage, axis: .vertical)
                        .lineLimit(1...5)
                        .padding(4)
                }
                .padding(8)
                .background(colors.cardBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(colors.divider, lineWidth: 1)
                )
                
                Button(action: {
                    sendThreadReply()
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(!threadMessage.isEmpty ? colors.accent : colors.secondaryText)
                        .font(.system(size: 20))
                        .padding(8)
                }
                .disabled(threadMessage.isEmpty)
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(colors.cardBackground)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
    }
    
    private func messageContextMenu(_ message: SlackMessage) -> some View {
        Group {
            if let threadParentId = message.threadParentId {
                Button {
                    self.threadParentId = threadParentId
                    showingThreadView = true
                } label: {
                    Label("View Thread", systemImage: "bubble.left.and.bubble.right")
                }
            } else if message.isThreadParent {
                Button {
                    threadParentId = message.id
                    showingThreadView = true
                } label: {
                    Label("View Thread", systemImage: "bubble.left.and.bubble.right")
                }
            }
            
            Button {
                reactionTargetMessage = message.id
                showingReactionPicker = true
            } label: {
                Label("Add Reaction", systemImage: "face.smiling")
            }
            
            Button {
                viewModel.markAsRead(messageId: message.id)
            } label: {
                Label(message.isRead ? "Mark as Unread" : "Mark as Read", systemImage: message.isRead ? "circle" : "checkmark.circle")
            }
            
            // Copy message text
            Button {
                UIPasteboard.general.string = message.text
            } label: {
                Label("Copy Text", systemImage: "doc.on.doc")
            }
        }
    }
    
    private func reactionPickerView() -> some View {
        let commonEmojis = ["👍", "👎", "😄", "🎉", "❤️", "🚀", "👀", "🙏"]
        
        return VStack(spacing: 16) {
            Text("Add Reaction")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 8) {
                ForEach(commonEmojis, id: \.self) { emoji in
                    Button(action: {
                        if let messageId = reactionTargetMessage {
                            addReaction(emoji: emoji, messageId: messageId)
                            showingReactionPicker = false
                        }
                    }) {
                        Text(emoji)
                            .font(.system(size: 24))
                            .padding(8)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding()
            
            Button("Cancel") {
                showingReactionPicker = false
            }
            .padding()
        }
        .padding()
        .presentationDetents([.height(300)])
    }
    
    // Helper to convert emoji name to emoji symbol
    private func emojiFromName(_ name: String) -> String {
        // This is a basic mapping - in a real app you'd have a complete mapping
        let emojiMap = [
            "thumbsup": "👍",
            "thumbsdown": "👎",
            "smile": "😄",
            "tada": "🎉",
            "heart": "❤️",
            "rocket": "🚀",
            "eyes": "👀",
            "pray": "🙏"
        ]
        
        return emojiMap[name] ?? ":\(name):"
    }
    
    private var selectedChannelName: String {
        if let channelId = selectedChannelId, let name = viewModel.channels[channelId] {
            return "#\(name)"
        }
        return "channel"
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        guard !messageText.isEmpty, let channelId = selectedChannelId else { return }
        
        Task {
            let result = await viewModel.sendMessage(text: messageText, channelId: channelId)
            
            // Reset message field regardless of success
            await MainActor.run {
                messageText = ""
                isComposing = false
            }
        }
    }
    
    private func sendThreadReply() {
        guard !threadMessage.isEmpty, let parentId = threadParentId, let parentMessage = viewModel.messages.first(where: { $0.id == parentId }) else { return }
        
        Task {
            let result = await viewModel.sendMessage(text: threadMessage, channelId: parentMessage.channelId, threadTs: parentId)
            
            // Reset message field regardless of success
            await MainActor.run {
                threadMessage = ""
            }
        }
    }
    
    private func addReaction(emoji: String, messageId: String) {
        // Convert emoji to name - in a real app you'd need a proper conversion
        let emojiNameMap = [
            "👍": "thumbsup",
            "👎": "thumbsdown",
            "😄": "smile",
            "🎉": "tada",
            "❤️": "heart",
            "🚀": "rocket",
            "👀": "eyes",
            "🙏": "pray"
        ]
        
        if let emojiName = emojiNameMap[emoji], let message = viewModel.messages.first(where: { $0.id == messageId }) {
            Task {
                await viewModel.addReaction(name: emojiName, messageId: messageId, channelId: message.channelId)
            }
        }
    }
    
    // MARK: - UI Components
    
    private func attachmentView(_ attachment: SlackAttachment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = attachment.title {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(colors.text)
            }
            
            if let text = attachment.text {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(colors.secondaryText)
            }
            
            if let imageUrl = attachment.imageUrl {
                // In a real app, use AsyncImage or an image loading library
                // For this example, we'll use a placeholder
                Rectangle()
                    .fill(colors.secondaryBackground)
                    .frame(height: 150)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(colors.secondaryText)
                            
                            Text("Image: \(imageUrl)")
                                .font(.system(size: 12))
                                .foregroundColor(colors.secondaryText)
                                .padding(.top, 4)
                        }
                    )
                    .cornerRadius(8)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colors.secondaryBackground)
        )
        .overlay(
            Rectangle()
                .fill(attachment.color ?? colors.accent)
                .frame(width: 4)
                .clipped(),
            alignment: .leading
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(colors.secondaryText)
            
            Text("No messages")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(colors.text)
            
            Text(searchText.isEmpty && selectedChannelId == nil ? 
                 "Your Slack messages will appear here" : 
                 "No messages match your filters")
                .font(.system(size: 15))
                .foregroundColor(colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                searchText = ""
                selectedChannelId = nil
                refreshMessages()
            }) {
                Text("Reset Filters")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(colors.accent)
                    .cornerRadius(8)
            }
            .opacity(searchText.isEmpty && selectedChannelId == nil ? 0 : 1)
            .animation(.easeInOut, value: searchText.isEmpty && selectedChannelId == nil)
        }
    }
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(colors.error)
            
            Text("Error")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(colors.text)
            
            Text(error)
                .font(.system(size: 15))
                .foregroundColor(colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                Task {
                    // Try to get a more informative error message
                    let result = await viewModel.testAPIConnection()
                    print(result)
                }
            }) {
                Text("Test API Connection")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(colors.accent)
                    .cornerRadius(8)
            }
            .padding(.bottom, 8)
            
            Button(action: {
                refreshMessages()
            }) {
                Text("Try Again")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(colors.accent)
                    .cornerRadius(8)
            }
            
            // If error is showing, give option to use mock data
            if !viewModel.useMockData {
                Button(action: {
                    viewModel.useMockData = true
                }) {
                    Text("Use Mock Data Instead")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(colors.accent)
                        .padding(.top, 8)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var filteredMessages: [SlackMessage] {
        let channelFiltered = viewModel.filterMessagesByChannel(selectedChannelId)
        
        if searchText.isEmpty {
            return channelFiltered
        } else {
            return channelFiltered.filter { message in
                message.text.lowercased().contains(searchText.lowercased()) ||
                message.userName.lowercased().contains(searchText.lowercased()) ||
                message.channelName.lowercased().contains(searchText.lowercased()) ||
                message.attachments.contains { attachment in
                    attachment.title?.lowercased().contains(searchText.lowercased()) ?? false ||
                    attachment.text?.lowercased().contains(searchText.lowercased()) ?? false
                }
            }
        }
    }
    
    private func refreshMessages() {
        Task {
            await viewModel.loadMessages()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// Container view that safely creates the ViewModel
struct SlackMessagesViewContainer: View {
    @State private var viewModel: SlackViewModel?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
                SlackMessagesView(viewModel: viewModel)
            } else {
                LoadingView()
                    .onAppear {
                        Task {
                            // Create the view model on the MainActor
                            let newViewModel = await MainActor.run {
                                return SlackViewModel()
                            }
                            
                            // Set the view model
                            await MainActor.run {
                                self.viewModel = newViewModel
                                self.isLoading = false
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    SlackMessagesViewContainer()
        .environment(\.themeColors, ThemeColors.colors(for: .light))
        .preferredColorScheme(.light)
} 