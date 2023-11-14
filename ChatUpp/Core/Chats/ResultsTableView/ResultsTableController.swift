//
//  ResultsTableController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/8/23.
//

import UIKit

class ResultsTableController: UITableViewController {
    
    enum UsersSearch {
        case global
        case local
    }

    var filteredUsers: [ResultsCellViewModel] = []
//    var filteredGlobalUsers: [DBUser] = []
    private var noUserWasFoundLabel = UILabel()
    var userSearch: UsersSearch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.register(ResultsTableCell.self, forCellReuseIdentifier: CellIdentifire.resultsTableCell)
        setupTableViewConstraints()
        configureTextLabel()
    }
    
    private func configureTextLabel() {
        tableView.addSubview(noUserWasFoundLabel)
        
        noUserWasFoundLabel.isHidden = true
        noUserWasFoundLabel.text = "No user's have been found"
        noUserWasFoundLabel.textColor = #colorLiteral(red: 0.547631681, green: 0.7303310037, blue: 0.989274919, alpha: 1)
        noUserWasFoundLabel.sizeToFit()
        
        noUserWasFoundLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            noUserWasFoundLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            noUserWasFoundLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor, constant: -100),
        ])
    }
    
    private func setupTableViewConstraints() {
        tableView.rowHeight = 70
        tableView.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
    }
}

//MARK: - TABLE DATASOURCE
extension ResultsTableController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
//        if !filteredGlobalUsers.isEmpty && !filteredUsers.isEmpty {
//            return 2
//        } else if !filteredGlobalUsers.isEmpty || !filteredUsers.isEmpty {
//            return 1
//        }
        if !filteredUsers.isEmpty {
            return 1
        }
        noUserWasFoundLabel.isHidden = false
        return 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if section == 0 {
            return filteredUsers.count
//        }
//        return filteredGlobalUsers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifire.resultsTableCell, for: indexPath) as? ResultsTableCell
        else {fatalError("Could not dequeue Results cell")}
        
        cell.configure(viewModel: filteredUsers[indexPath.item])
        noUserWasFoundLabel.isHidden = true
        
        return cell
    }
    
//    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        if let cell = cell as? ResultsTableCell {
//            cell.resetImg()
//        }
//    }
}

//MARK: - TABLE DELEGATE
extension ResultsTableController {
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let tableViewHeaderFooterView = UITableViewHeaderFooterView()
        var configuration = UIListContentConfiguration.subtitleCell()
        
        if userSearch == .local {
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
    
    //    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    //        if section == 0 {
    //            return "Chats"
    //        }
    //        return "Global search"
    //    }
    
    
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
