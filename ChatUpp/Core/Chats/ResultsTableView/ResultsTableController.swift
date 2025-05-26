//
//  ResultsTableController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/8/23.
//

import UIKit
import SkeletonView

enum SkeletonAnimationState {
    case initiated
    case terminated
    case none
}

final class ResultsTableController: UITableViewController {
    
    enum SearchType {
        case local
        case global
    }
    
    weak var coordinatorDelegate: Coordinator?
    
    var searchBar: UISearchBar?
    
    var filteredResults: [ResultsCellViewModel] = [] 
    var searchType: SearchType!
    private var noUserWasFoundLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
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
    
    func toggleSkeletonAnimation(_ value: SkeletonAnimationState) {
        if value == .initiated {
            Utilities.initiateSkeletonAnimation(for: tableView)
            noUserWasFoundLabel.isHidden = true
        } else {
            Utilities.terminateSkeletonAnimation(for: tableView)
            noUserWasFoundLabel.isHidden = false
        }
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ResultsTableCell.self, forCellReuseIdentifier: ReuseIdentifire.SearchRusultsTableCell.searchResult.identifire)
        tableView.sectionHeaderTopPadding = 0
        tableView.rowHeight = 55
        tableView.backgroundColor = ColorManager.appBackgroundColor
        tableView.isSkeletonable = true
        
        // Omit tableView to automatically go behind navigation bar
        // when Skeleton view is running
        edgesForExtendedLayout = []
    }
}

//MARK: - SKELETON TABLE VIEW DATA SOURCE

extension ResultsTableController: SkeletonTableViewDataSource {
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
       return ReuseIdentifire.SearchRusultsTableCell.searchResult.identifire
    }
}

//MARK: - TABLE VIEW DATASOURCE
extension ResultsTableController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        if !filteredResults.isEmpty {
            return 1
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifire.SearchRusultsTableCell.searchResult.identifire,
                                                       for: indexPath) as? ResultsTableCell
        else {fatalError("Could not dequeue Results cell")}
        
        cell.configure(viewModel: filteredResults[indexPath.item])
        noUserWasFoundLabel.isHidden = true
        
        return cell
    }
}

//MARK: - TABLE VIEW DELEGATE
extension ResultsTableController
{
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !tableView.sk.isSkeletonActive else {return nil}
        
        let tableViewHeaderFooterView = UITableViewHeaderFooterView()
        var configuration = UIListContentConfiguration.subtitleCell()
        
        if searchType == .local {
            configuration.text = "Chats".uppercased()
        } else {
            configuration.text = "Global search".uppercased()
        }
        
        configuration.textProperties.color = ColorManager.textFieldPlaceholderColor
        configuration.textProperties.font = UIFont(name: "HelveticaNeue", size: 13)!
        
        tableViewHeaderFooterView.contentConfiguration = configuration
        tableViewHeaderFooterView.contentView.backgroundColor = ColorManager.navigationBarBackgroundColor
        
        return tableViewHeaderFooterView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 24
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        searchBar?.resignFirstResponder()
        
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
            let user = self.filteredResults[indexPath.item].participant
            var conversationViewModel: ChatRoomViewModel!
        
            defer {
                self.coordinatorDelegate?.openConversationVC(conversationViewModel: conversationViewModel)
            }

            if let existingChat = self.filteredResults[indexPath.item].chat {
                conversationViewModel = ChatRoomViewModel(conversation: existingChat)
            } else {
                conversationViewModel = ChatRoomViewModel(participant: user)
            }
        }
    }
}
