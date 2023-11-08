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
        
        tableView.delegate = self
        tableView.register(ChatsCell.self, forCellReuseIdentifier: CellIdentifire.chatCell)
        setupTableViewConstraints()
    }
    
    func setupTableViewConstraints() {
        tableView.rowHeight = 70
        tableView.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
    }
    
}

//MARK: - TABLE DATASOURCE
extension ResultsTableController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
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
    
//    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        if section == 0 {
//            return "Chats"
//        }
//        return "Global search"
//    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let tableViewHeaderFooterView = UITableViewHeaderFooterView()
        var configuration = UIListContentConfiguration.subtitleCell()
        
        if section == 0 {
            configuration.text = "Chats".uppercased()
        } else {
            configuration.text = "Global search".uppercased()
        }
        configuration.textProperties.color = .white
        configuration.textProperties.font = UIFont(name: "HelveticaNeue", size: 14)!
        
        tableViewHeaderFooterView.contentConfiguration = configuration
        tableViewHeaderFooterView.contentView.backgroundColor = .brown
        
        return tableViewHeaderFooterView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 25
    }
    
    
//    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
//        guard let headerView = view as? UITableViewHeaderFooterView else { return }
//        headerView.contentView.backgroundColor = .brown
//        var configuration = UIListContentConfiguration.subtitleCell()
//        if section == 0 {
//            configuration.text = "Chats"
//        } else {
//            configuration.text = "Global search"
//        }
//        configuration.textProperties.color = .white
//
//        headerView.contentConfiguration = configuration
//    }
}
