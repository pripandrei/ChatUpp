//
//  ChatsTableViewDataSource.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/6/23.
//

import UIKit

class ChatsTableViewDataSource: NSObject, UITableViewDataSource {

    let chatsViewModel: ChatsViewModel!
    
    init(viewModel: ChatsViewModel) {
        self.chatsViewModel = viewModel
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatsViewModel.cellViewModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatsViewController.Cell.chatCell, for: indexPath) as? ChatsCell else {
            fatalError("Unable to dequeu reusable cell")
        }
        cell.configure(viewModel: chatsViewModel.cellViewModels[indexPath.row])
        
        return cell
    }
}
