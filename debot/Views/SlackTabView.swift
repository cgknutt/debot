import SwiftUI

struct SlackTabView: View {
    @ObservedObject var viewModel: SlackViewModel
    @Environment(\.themeColors) private var themeColors
    
    @State private var showingChannelSelector = false
    @State private var refreshingWithAnimation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section
            HStack {
                Text("Slack")
                    .font(.headline)
                    .padding(.leading)
                
                Spacer()
                
                Button {
                    viewModel.showingComposeSheet = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(themeColors.text)
                        .font(.system(size: 18))
                        .padding(8)
                        .background(themeColors.cardBackground)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .padding(.trailing)
                .sheet(isPresented: $viewModel.showingComposeSheet) {
                    SlackComposeView(viewModel: viewModel)
                }
            }
            .padding(.vertical, 8)
            .background(themeColors.cardBackground)
            
            // Channel selector
            HStack {
                Button {
                    showingChannelSelector = true
                } label: {
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(themeColors.text)
                        
                        Text(viewModel.selectedChannel ?? "All Channels")
                            .foregroundColor(themeColors.text)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(themeColors.secondaryText)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(themeColors.cardBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(themeColors.borderColor, lineWidth: 1)
                    )
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        refreshingWithAnimation = true
                    }
                    
                    Task {
                        await viewModel.loadMessages()
                        
                        withAnimation {
                            refreshingWithAnimation = false
                        }
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(themeColors.text)
                        .rotationEffect(.degrees(refreshingWithAnimation ? 360 : 0))
                        .animation(refreshingWithAnimation ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: refreshingWithAnimation)
                }
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(themeColors.background)
            
            if viewModel.isLoading && viewModel.messages.isEmpty {
                // Loading indicator
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Loading messages...")
                        .font(.caption)
                        .foregroundColor(themeColors.secondaryText)
                        .padding()
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                // Error view
                VStack {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                        .padding()
                    Text("Error loading messages")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(themeColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") {
                        Task {
                            await viewModel.loadMessages()
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    Spacer()
                }
                .padding()
            } else if viewModel.messages.isEmpty {
                // Empty state
                VStack {
                    Spacer()
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 40))
                        .foregroundColor(themeColors.secondaryText)
                        .padding()
                    Text("No messages")
                        .font(.headline)
                    Text("There are no messages to display.")
                        .font(.caption)
                        .foregroundColor(themeColors.secondaryText)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Message list
                List {
                    ForEach(viewModel.messages) { message in
                        SlackMessageRow(message: message, viewModel: viewModel)
                            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                            .listRowBackground(themeColors.cardBackground)
                    }
                    
                    if viewModel.isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                    
                    if viewModel.hasMoreMessages {
                        Button("Load More") {
                            Task {
                                await viewModel.loadMoreMessages()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .buttonStyle(BorderlessButtonStyle())
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    await viewModel.loadMessages()
                }
            }
        }
        .sheet(isPresented: $showingChannelSelector) {
            // Channel selector sheet
            ChannelSelectorView(
                viewModel: viewModel,
                selectedChannel: viewModel.selectedChannel,
                onChannelSelected: { channelName in
                    viewModel.selectedChannel = channelName
                    Task {
                        await viewModel.loadMessages()
                    }
                }
            )
        }
        .onAppear {
            // Load channels in background
            Task {
                await viewModel.loadChannels()
            }
        }
    }
}

// Channel selector sheet
struct ChannelSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeColors) private var themeColors
    
    @ObservedObject var viewModel: SlackViewModel
    let selectedChannel: String?
    let onChannelSelected: (String?) -> Void
    
    var body: some View {
        NavigationView {
            List {
                Button {
                    onChannelSelected(nil)
                    dismiss()
                } label: {
                    HStack {
                        Text("All Channels")
                            .foregroundColor(themeColors.text)
                        
                        Spacer()
                        
                        if selectedChannel == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ForEach(viewModel.channels) { channel in
                    Button {
                        onChannelSelected(channel.name)
                        dismiss()
                    } label: {
                        HStack {
                            Text("#\(channel.name)")
                                .foregroundColor(themeColors.text)
                            
                            Spacer()
                            
                            if selectedChannel == channel.name {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Channel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if viewModel.channels.isEmpty {
                    Task {
                        await viewModel.loadChannels()
                    }
                }
            }
        }
    }
}

// Message row
struct SlackMessageRow: View {
    let message: SlackMessage
    @ObservedObject var viewModel: SlackViewModel
    @Environment(\.themeColors) private var themeColors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Message header
            HStack {
                // User avatar
                if let avatar = message.userAvatar, !avatar.isEmpty {
                    AsyncImage(url: URL(string: avatar)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(message.userName.prefix(2).uppercased())
                                .font(.caption)
                                .foregroundColor(.white)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(message.userName)
                            .font(.headline)
                            .foregroundColor(themeColors.text)
                        
                        if message.channelName != nil {
                            Text("in #\(message.channelName!)")
                                .font(.caption)
                                .foregroundColor(themeColors.secondaryText)
                        }
                        
                        Spacer()
                        
                        if let timestamp = Double(message.timestamp) {
                            Text(Date(timeIntervalSince1970: timestamp).formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundColor(themeColors.secondaryText)
                        }
                    }
                }
            }
            
            // Message text
            Text(message.text)
                .foregroundColor(themeColors.text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            // Reactions
            if !message.reactions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(message.reactions, id: \.name) { reaction in
                            Button {
                                // Add this reaction
                                Task {
                                    try? await viewModel.addReaction(
                                        emoji: reaction.name,
                                        messageId: message.id
                                    )
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(reaction.name)
                                        .font(.system(size: 14))
                                    Text("\(reaction.count)")
                                        .font(.system(size: 12))
                                        .foregroundColor(
                                            reaction.users.contains(viewModel.currentUserId ?? "") 
                                            ? .blue 
                                            : themeColors.secondaryText
                                        )
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    reaction.users.contains(viewModel.currentUserId ?? "") 
                                    ? Color.blue.opacity(0.1) 
                                    : themeColors.cardBackground
                                )
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(themeColors.borderColor, lineWidth: 1)
                                )
                            }
                        }
                    }
                }
            }
            
            // Thread indicator
            if message.isThreadParent && message.replyCount > 0 {
                Button {
                    // Handle thread navigation
                } label: {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text("\(message.replyCount) replies")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.vertical, 4)
        .swipeActions {
            Button {
                // Mark as read/unread
                // Toggle the read status
                Task {
                    await viewModel.toggleMessageReadStatus(messageId: message.id)
                }
            } label: {
                Label(message.isRead ? "Unread" : "Read", systemImage: message.isRead ? "eye.slash" : "eye")
            }
            .tint(message.isRead ? .gray : .blue)
        }
    }
}

// Previews
struct SlackTabView_Previews: PreviewProvider {
    static var previews: some View {
        SlackTabView(viewModel: SlackViewModel())
    }
} 