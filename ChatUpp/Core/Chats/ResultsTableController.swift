//
//  ResultsTableController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/8/23.
//

import UIKit

class ResultsTableController: UITableViewController {
    
    var filteredChats: [ChatCellViewModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(ChatsCell.self, forCellReuseIdentifier: CellIdentifire.chatCell)
        setupTableViewConstraints()
    }
    
    func setupTableViewConstraints() {
//        tableView.pin(to: view)
        tableView.rowHeight = 70
        tableView.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
    }
    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredChats.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifire.chatCell, for: indexPath) as? ChatsCell
        else {fatalError("Could not dequeue Results cell")}
        
        cell.configure(viewModel: filteredChats[indexPath.item])
        
        return cell
    }
    
}
