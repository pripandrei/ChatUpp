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
    static let resultsTableCell = "ResultsTableCell"
}

class ChatsViewController: UIViewController {
    
    weak var coordinatorDelegate: Coordinator?
    
    private let tableView = UITableView()
    private var chatsViewModel = ChatsViewModel()
    private var tableViewDataSource: UITableViewDataSource!
    
    private let resultsTableController = ResultsTableController()
    private var searchController: UISearchController!

    private var shouldValidateUserAuthentication: Bool = true
    
    private var lastSearchedText: String?
    private var searchTimer: Timer?
    
    // MARK: - UI SETUP

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .orange
        setupBinding()
        configureTableView()
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
    
    private func configureTableView() {
        tableView.register(ChatsCell.self, forCellReuseIdentifier: CellIdentifire.chatCell)
        view.addSubview(tableView)
        tableView.delegate = self
        tableViewDataSource = ChatsTableViewDataSource(viewModel: chatsViewModel)
        tableView.dataSource = tableViewDataSource
        tableView.pin(to: view)
        tableView.rowHeight = 70
        tableView.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
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
    
    func filterContentForSearchText(_ searchText: String) -> [ResultsCellViewModel] {
        let resultsCell: [ResultsCellViewModel] = []
        
        let chatsViewModels = chatsViewModel.cellViewModels.filter({ chat -> Bool in
           
            let delimiters = CharacterSet(charactersIn: " /.:!?;[]%$£@^&()-+=<>,")
            
            let searchTextComponents = searchText.components(separatedBy: delimiters)
            let filteredSearchText = searchTextComponents.joined(separator: " ")
            let trimmedSearchText = removeExcessiveSpaces(from: filteredSearchText).lowercased()
            
            let nameSubstrings = chat.userMame.lowercased().components(separatedBy: delimiters)
            
            for substring in nameSubstrings {
                if substring.hasPrefix(trimmedSearchText) {
                    return true
                }
            }
            if chat.userMame.lowercased().hasPrefix(trimmedSearchText) {
                return true
            }
            return false
        })
        
//        for chatVM in chatsViewModels {
//            let resultsCellVM = ResultsCellViewModel(userName: chatVM.userMame, userImageData: chatVM.otherUserProfileImage.value!)
//            resultsCell.append(resultsCellVM)
//        }
        return resultsCell
    }
    
    func removeExcessiveSpaces(from input: String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: "\\s+", options: .caseInsensitive)
            let range = NSRange(location: 0, length: input.utf16.count)
            let result = regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: " ")
            return result.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("Error creating regular expression: \(error)")
            return input
        }
    }
}

extension ChatsViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
//        let filteredResults = filterContentForSearchText(searchBar.text!)
        guard let text = searchBar.text,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else
        {
            lastSearchedText = nil
            resultsTableController.filteredUsers = []
            resultsTableController.tableView.reloadData()
            return
        }
        
        lastSearchedText = text
        
        if resultsTableController.filteredUsers.isEmpty {
            resultsTableController.initiateSkeletonAnimation()            
        }
        
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { _ in
            self.performSearch(text)
        })
    }
    
    // Transfer to viewModel
    private func performSearch(_ text: String) {
        Task {
            let searchResultData = await AlgoliaSearchManager.shared.performSearch(text)
            if text == lastSearchedText {
                let filteredUsers = searchResultData.compactMap { resultData in
                    ResultsCellViewModel(user: resultData.name, userProfileImageLink: resultData.profileImageLink)
                }
                await MainActor.run {
                    resultsTableController.filteredUsers = filteredUsers
                    resultsTableController.terminateSkeletonAnimation()
                    resultsTableController.tableView.reloadData()
                }
            }
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
