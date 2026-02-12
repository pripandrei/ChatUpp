//
//  NicknameUpdateScreen.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/25/26.
//
import SwiftUI

struct NicknameUpdateScreen: View
{
    @State private var viewModel: NicknameUpdateViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var textValidationDebounceTask: Task<Void, Never>?
    @State private var isLoading: Bool = false
    let onUpdate: (String) -> Void
    
    init(nickname: String,
         onUpdate: @escaping (String) -> Void)
    {
        self.onUpdate = onUpdate
        self._viewModel = State(wrappedValue: NicknameUpdateViewModel(updatedNickname: nickname))
    }

    var body: some View
    {
        NavigationStack {
            ZStack
            {
                //            Color(#colorLiteral(red: 0.443, green: 0.165, blue: 0.322, alpha: 1))
                //                   .ignoresSafeArea()
                VStack(alignment: .leading)
                {
                    TextField
                    
                    CurrentStatusText
                    
                    DescriptionText("You can choose a nickname on ChatUpp. If you do so, peopler will e able to find you by this ursername.")
                    
                    DescriptionText("You can use a-z, 0-9 and underscores. Minimum lenght is 5 cahracters.")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 50)
                .animation(.easeInOut(duration: 0.25),
                           value: viewModel.nicknameValidationStatus)
                
                //            Spacer()
            }
            .frame(maxWidth: .infinity,
                   maxHeight: .infinity,
                   alignment: .topLeading) // alignes all content inside to topLeading
            .background(Color(ColorScheme.appBackgroundColor))
//            .ignoresSafeArea()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarContent()
            }
            .isLoading(isLoading)
            .toolbarBackground(Color(ColorScheme.appBackgroundColor), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

extension NicknameUpdateScreen
{
    private var CurrentStatusText: some View
    {
        return Text(viewModel.nicknameValidationStatus.statusTitle)
            .foregroundStyle(nicknameTextStatusColor)
            .padding(.horizontal, 10)
//            .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    var nicknameTextStatusColor: Color
    {
        switch viewModel.nicknameValidationStatus
        {
        case .invalid, .isShort, .isTaken: return .red
        case .isAvailable(name: _): return .green
        default: return .primary
        }
    }
}

// MARK: - Textfield
extension NicknameUpdateScreen
{
    var TextField: some View
    {
        return textField($viewModel.updatedNickname, placeholder: "Nickname")
            .padding(.leading, 20)
            .padding(.trailing, 55)
            .font(.system(size: 18, weight: .medium))
            .frame(height: 50)
            .background(Color(ColorScheme.messageTextFieldBackgroundColor))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RemoveTextButton()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(20)
            }
            .onChange(of: viewModel.updatedNickname)
        { oldValue, newValue in
            textValidationDebounceTask?.cancel()
            
            self.textValidationDebounceTask = Task
            {
                try? await Task.sleep(for: .seconds(0.3))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    viewModel.checkIfNicknameIsValid()
                }
            }
        }
    }
}

// MARK: - Toolbar Content
extension NicknameUpdateScreen
{
    @ToolbarContentBuilder
    private func ToolbarContent() -> some ToolbarContent
    {
        ToolbarItem(placement: .principal)
        {
            Text("Nickname")
                .font(.headline)
                .foregroundStyle(.white)
        }
        
        ToolbarItem(placement: .topBarLeading) {
            ToolbarItemButton(itemTitle: .cancel)
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            ToolbarItemButton(itemTitle: .save)
        }
    }
    
    private func onToolbarItemButtonTap(_ itemTitle: ToolbarItemTitle)
    {
        Task
        {
            if itemTitle == .save {
                self.isLoading = true
                try await viewModel.saveNickname()
                onUpdate(viewModel.updatedNickname)
                self.isLoading = false
            }
            dismiss()
        }
    }
    
    
    private func ToolbarItemButton(itemTitle: ToolbarItemTitle) -> some View
    {
        Group
        {
            if #available(iOS 26, *)
            {
                Button
                {
                    onToolbarItemButtonTap(itemTitle)
                } label: {
                    Text(itemTitle.rawValue)
                        .foregroundStyle(Color(.systemGray))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(ColorScheme.messageTextFieldBackgroundColor))
            } else {
                Button
                {
                    onToolbarItemButtonTap(itemTitle)
                } label: {
                    ToolbarItemButtonLabel(itemTitle)
                }
            }
        }
    }
    
    private func ToolbarItemButtonLabel(_ itemTitle: ToolbarItemTitle) -> some View
    {
        let saveItemColor = (itemTitle == .save) && viewModel.nicknameValidationStatus.isValid ? Color(.white) : Color(.gray)
        let textColor = (itemTitle == .save) ? saveItemColor : Color(.white)
        let disabled = (itemTitle == .save) && !viewModel.nicknameValidationStatus.isValid
        return Text(itemTitle.rawValue.capitalized)
            .foregroundStyle(textColor)
            .font(.system(size: 17, weight: .medium))
            .frame(height: 40)
            .padding(.horizontal, 10)
            .background(Color(ColorScheme.messageTextFieldBackgroundColor).opacity(0.9))
            .clipShape(.capsule)
            .overlay {
                //                            RoundedRectangle(cornerRadius: 100)
                Capsule()
                    .stroke(Color(#colorLiteral(red: 0.4868350625, green: 0.345061183, blue: 0.5088059902, alpha: 1)), lineWidth: 1)
            }
            .disabled(disabled)
    }
    
    enum ToolbarItemTitle: String
    {
        case save
        case cancel
    }
}

extension NicknameUpdateScreen
{
    private func DescriptionText(_ text: String) -> some View
    {
        Text(text)
            .font(.system(.headline, design: .default, weight: .medium))
            .foregroundStyle(Color(#colorLiteral(red: 0.5859215856, green: 0.5880212188, blue: 0.6103259325, alpha: 1)))
            .padding(.horizontal, 10)
            .padding(.top, 5)
    }
    
    private func RemoveTextButton() -> some View
    {
        Button {
            viewModel.updatedNickname = ""
        } label: {
            Image(systemName: "xmark")
                .imageScale(.small)
                .frame(width: 8, height: 8)
                .padding(8)
                .background(Color(#colorLiteral(red: 0.5859215856, green: 0.5880212188, blue: 0.6103259325, alpha: 1)))
                .foregroundStyle(Color(ColorScheme.messageTextFieldBackgroundColor))
                .clipShape(.circle)
        }
    }
}


#Preview
{
    NicknameUpdateScreen(nickname: "Damien") { nickname in }
}
