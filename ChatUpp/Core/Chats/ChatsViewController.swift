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

//    private var shouldValidateUserAuthentication: Bool = true
    
    private var lastSearchedText: String?
    private var searchTimer: Timer?
    
    // MARK: - UI SETUP

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        setupBinding()
        configureTableView()
        setupSearchController()
        chatsViewModel.reloadChatsCellData()
    }
    
    deinit {
        print("ChatsVC was DEINITED!==")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        if shouldValidateUserAuthentication {
//            chatsViewModel.validateUserAuthentication()
//        }
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
        tableView.separatorColor = #colorLiteral(red: 0.6390894651, green: 0.6514347792, blue: 0.6907400489, alpha: 1).withAlphaComponent(0.6)
    }
    
    private func setupBinding() {
        chatsViewModel.onDataFetched = { [weak self] in
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
        }
//        chatsViewModel.isUserLoggedOut.bind { [weak self] isSignedOut in
//            if isSignedOut == true {
//                self?.coordinatorDelegate?.presentLogInForm()
//            }
//            else {
//                self?.chatsViewModel.reloadChatsCellData()
//                self?.shouldValidateUserAuthentication = false
//            }
//        }
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
        return chatsViewModel.cellViewModels.compactMap ({ chat in
           
            let delimiters = CharacterSet(charactersIn: " /.:!?;[]%$£@^&()-+=<>,")
            
            let searchTextComponents = searchText.components(separatedBy: delimiters)
            let filteredSearchText = searchTextComponents.joined(separator: " ")
            let trimmedSearchText = removeExcessiveSpaces(from: filteredSearchText).lowercased()
            
            let nameSubstrings = chat.userMame.lowercased().components(separatedBy: delimiters)
            
            for substring in nameSubstrings {
                if substring.hasPrefix(trimmedSearchText) {
                    return ResultsCellViewModel(user: chat.userMame, userProfileImageLink: chat.user.photoUrl!)
                }
            }
            if chat.userMame.lowercased().hasPrefix(trimmedSearchText) {
                return ResultsCellViewModel(user: chat.userMame, userProfileImageLink: chat.user.photoUrl!)
            }
            return nil
        })
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
        searchTimer?.invalidate()
        // If seach bar is empty or contains spaces
        guard let text = searchBar.text,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else
        {
            lastSearchedText = nil
            updateTableView(withResults: [], toggleSkeletonAnimation: .terminate)
            return
        }
        
        // If search bar contains local names
        let filteredResults = filterContentForSearchText(searchBar.text!)
        guard filteredResults.isEmpty else {
            resultsTableController.userSearch = .local
            updateTableView(withResults: filteredResults, toggleSkeletonAnimation: .terminate)
            return
        }

        // If search is performed globaly (database)
        if resultsTableController.filteredUsers.isEmpty {
            resultsTableController.toggleSkeletonAnimation(.initiate)
        }
        lastSearchedText = text
        
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] _ in
            self?.performSearch(text)
        })
    }
    
    private func updateTableView(withResults filteredResults: [ResultsCellViewModel], toggleSkeletonAnimation value: Skeletonanimation) {
        resultsTableController.filteredUsers = filteredResults
        resultsTableController.tableView.reloadData()
        resultsTableController.toggleSkeletonAnimation(value)
    }
    
    // Transfer to viewModel
    private func performSearch(_ text: String) {
        Task {
            let searchResultData = await AlgoliaSearchManager.shared.performSearch(text)
            if text == lastSearchedText {
                let filteredResults = searchResultData.compactMap { resultData in
                    ResultsCellViewModel(user: resultData.name, userProfileImageLink: resultData.profileImageLink)
                }
                await MainActor.run {
                    resultsTableController.userSearch = .global
                    updateTableView(withResults: filteredResults, toggleSkeletonAnimation: .terminate)
                }
            }
        }
    }
}

extension ChatsViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let chat = chatsViewModel.chats[indexPath.item]
        let memberName = chatsViewModel.cellViewModels[indexPath.item].userMame
        let memberPhoto = chatsViewModel.cellViewModels[indexPath.item].otherUserProfileImage.value
        
        let conversationViewModel = ConversationViewModel(memberName: memberName, conversation: chat, imageData: memberPhoto)
        
        coordinatorDelegate?.openConversationVC(conversationViewModel: conversationViewModel)
    }
    
}
