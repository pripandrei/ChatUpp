//
//  ConversationsViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/6/23.
//

import UIKit
import FirebaseAuth

// MARK: - CELL IDENTIFIER

struct CellIdentifire {
    static let chatCell = "ChatTableVwCell"
    static let conversationMessageCell = "ConversationCollectionViewCell"
}

class ChatsViewController: UIViewController {
    
    weak var coordinatorDelegate: Coordinator?
    
    let tableView = UITableView()
    var chatsViewModel = ChatsViewModel()
    var tableViewDataSource: UITableViewDataSource!

    var shouldValidateUserAuthentication: Bool = true
    
    // MARK: - UI SETUP

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .orange
        setupBinding()
        setupTableView()
        setupSearchController()
    }
    
    deinit {
        print("ChatsVC was DEINITED!==")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldValidateUserAuthentication {
            chatsViewModel.validateUserAuthentication()
        }
    }
    
    private func setupTableView() {
        tableView.register(ChatsCell.self, forCellReuseIdentifier: CellIdentifire.chatCell)
        configureTableView()
    }
    
    private func setupBinding() {
        chatsViewModel.onDataFetched = { [weak self] in
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
        }
        chatsViewModel.isUserLoggedOut.bind { [weak self] isSignedOut in
            if isSignedOut == true {
                self?.coordinatorDelegate?.presentLogInForm()
            }
            else {
                self?.chatsViewModel.reloadChatsCellData()
                self?.shouldValidateUserAuthentication = false
            }
        }
    }
    
    func configureTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableViewDataSource = ChatsTableViewDataSource(viewModel: chatsViewModel)
        tableView.dataSource = tableViewDataSource
        tableView.pin(to: view)
        tableView.rowHeight = 70
        tableView.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
    }
    
    let resultsTableController = ResultsTableController()
    var searchController: UISearchController!
    
//    var filteredChats: [ChatCellViewModel] = []
    
//    var isSearchBarEmpty: Bool {
//        searchController.searchBar.text?.isEmpty ?? true
//    }
//
//    var isFiltering: Bool {
//        searchController.isActive && !isSearchBarEmpty
//    }
    
    func filterContentForSearchText(_ searchText: String) -> [ChatCellViewModel] {
        return chatsViewModel.cellViewModels.filter({ chat -> Bool in
            chat.userMame.lowercased().contains(searchText.lowercased())
        })
//        tableView.reloadData()
    }
    
    func setupSearchController() {
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
//        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        navigationItem.hidesSearchBarWhenScrolling = true
    }
}

extension ChatsViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let filteredResults = filterContentForSearchText(searchBar.text!)
        
        if let resultsTableVC = searchController.searchResultsController as? ResultsTableController {
            resultsTableVC.filteredChats = filteredResults
            resultsTableVC.tableView.reloadData()
        }
    }
}


extension ChatsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let chat = chatsViewModel.chats[indexPath.item]
        let memberName = chatsViewModel.cellViewModels[indexPath.item].userMame
        let memberPhoto = chatsViewModel.cellViewModels[indexPath.item].otherUserProfileImage.value
        
        let conversationViewModel = ConversationViewModel(memberName: memberName, conversation: chat, imageData: memberPhoto)
        
        coordinatorDelegate?.openConversationVC(conversationViewModel: conversationViewModel)
    }
}



