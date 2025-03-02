import SwiftUI

struct SlackComposeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeColors) private var themeColors
    
    @ObservedObject var viewModel: SlackViewModel
    
    @State private var messageText = ""
    @State private var selectedChannelIndex = 0
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showingChannelPicker = false
    @State private var showingEmojiPicker = false
    @State private var selectedEmojis: [String] = []
    
    let emojiOptions = ["👍", "❤️", "😂", "🎉", "🚀", "👀", "💯", "🙏"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Channel selector
                Button {
                    showingChannelPicker = true
                } label: {
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.gray)
                        
                        if viewModel.channels.isEmpty {
                            Text("Loading channels...")
                                .foregroundColor(.gray)
                        } else {
                            Text(viewModel.channels[selectedChannelIndex].name)
                                .foregroundColor(themeColors.text)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(themeColors.cardBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(themeColors.borderColor, lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                .disabled(viewModel.channels.isEmpty)
                .sheet(isPresented: $showingChannelPicker) {
                    ChannelPickerView(
                        channels: viewModel.channels,
                        selectedIndex: $selectedChannelIndex,
                        onSelect: { index in
                            selectedChannelIndex = index
                            showingChannelPicker = false
                        }
                    )
                }
                
                // Message composer
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    TextEditor(text: $messageText)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(themeColors.cardBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(themeColors.borderColor, lineWidth: 1)
                        )
                        .padding(.horizontal)
                }
                
                // Emoji selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add reactions")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(emojiOptions, id: \.self) { emoji in
                                Button {
                                    toggleEmoji(emoji)
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 24))
                                        .padding(8)
                                        .background(selectedEmojis.contains(emoji) ? Color.purple.opacity(0.2) : Color.clear)
                                        .cornerRadius(8)
                                }
                            }
                            
                            Button {
                                showingEmojiPicker = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 16))
                                    .padding(12)
                                    .background(themeColors.cardBackground)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(themeColors.borderColor, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
                
                // Send button
                Button {
                    sendMessage()
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Send Message")
                                .bold()
                        }
                        Spacer()
                    }
                    .padding()
                    .background(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding()
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Load channels if needed
                if viewModel.channels.isEmpty {
                    Task {
                        await viewModel.loadChannels()
                    }
                }
            }
        }
    }
    
    private func toggleEmoji(_ emoji: String) {
        if selectedEmojis.contains(emoji) {
            selectedEmojis.removeAll { $0 == emoji }
        } else {
            selectedEmojis.append(emoji)
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !viewModel.channels.isEmpty else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let channelId = viewModel.channels[selectedChannelIndex].id
        
        Task {
            do {
                // Send the message
                let messageId = try await viewModel.sendMessage(
                    text: messageText,
                    channelId: channelId
                )
                
                // Add reactions if any
                if !selectedEmojis.isEmpty && messageId != nil {
                    for emoji in selectedEmojis {
                        try? await viewModel.addReaction(
                            emoji: emoji,
                            messageId: messageId!
                        )
                    }
                }
                
                // Refresh messages to show the new one
                await viewModel.loadMessages()
                
                // Close the compose view
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to send message: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

// Channel picker sheet
struct ChannelPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeColors) private var themeColors
    
    let channels: [SlackChannel]
    @Binding var selectedIndex: Int
    let onSelect: (Int) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(channels.enumerated()), id: \.element.id) { index, channel in
                    Button {
                        onSelect(index)
                    } label: {
                        HStack {
                            Text("#\(channel.name)")
                                .foregroundColor(themeColors.text)
                            
                            Spacer()
                            
                            if index == selectedIndex {
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
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Preview provider for SwiftUI canvas
struct SlackComposeView_Previews: PreviewProvider {
    static var previews: some View {
        SlackComposeView(viewModel: SlackViewModel())
    }
} 