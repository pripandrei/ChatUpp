//
//  NewGroupSetupScreen.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/4/25.
//

import SwiftUI

struct NewGroupSetupScreen: View
{
    @State private var textFieldText: String = ""
    @ObservedObject var viewModel: GroupCreationViewModel

    var body: some View {
        List {
            headerSection()
            addedMembersSection()
        }
        .navigationTitle("New Group")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarTrailingItem()
        }
    }
    
    private func toolbarTrailingItem() -> some ToolbarContent
    {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                
            } label: {
                Text("Create")
            }
        }
    }
}

//MARK: Sections
extension NewGroupSetupScreen
{
    private func headerSection() -> some View
    {
        Section {
            HStack {
                addPictureButton()
                textField()
                removeTextButton()
            }
        }
    }
    
    private func addedMembersSection() -> some View
    {
        Section {
            ForEach(viewModel.selectedGroupMembers) { user in
                UserView(userItem: user)
            }
        }
    }
}

//MARK: Section Components
extension NewGroupSetupScreen
{
    private func addPictureButton() -> some View
    {
        Button {
            
        } label: {
            Image(systemName: "camera.fill")
//                .imageScale(.large)
                .resizable()
                .scaledToFit()
                .frame(width: 35, height: 35)
                .padding(.all, 15)
                .foregroundStyle(Color(#colorLiteral(red: 0.5159683824, green: 0.7356743217, blue: 0.9494176507, alpha: 1)))
                .background(Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)))
                .clipShape(.circle)
        }
        .buttonStyle(.plain)
    }
    
    private func textField() -> some View {
        TextField("Group Name", text: $textFieldText)
            .padding(.leading, 10)
            .font(Font.system(size: 19, weight: .semibold))
            .foregroundStyle(Color(#colorLiteral(red: 0.4086711407, green: 0.4086711407, blue: 0.4086711407, alpha: 1)))
    }
    
    private func removeTextButton() -> some View
    {
        Button {
            textFieldText = ""
        } label: {
            ZStack {
                Circle()
                    .fill(Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)))
                    .frame(width: 24, height: 24)
                
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    NavigationStack {
        NewGroupSetupScreen(viewModel: GroupCreationViewModel())
    }
}
