//
//  ConversationsViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/6/23.
//

import UIKit
import FirebaseAuth
import AlgoliaSearchClient

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

    private var shouldValidateUserAuthentication: Bool = true
    
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
    
    private let resultsTableController = ResultsTableController()
    private var searchController: UISearchController!
    
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
    
//    func filterContentForGlobalSearch(_ searchText: String) -> [ChatCellViewModel] {
//
//        Task {
//            let searchResults = await chatsViewModel.findUsersFromDB(where: searchText)
//
//        }
//        return []
//    }
    
//    func performGlobalSearch(_ searchText: String) {
//        let delimiters = CharacterSet(charactersIn: " /.:!?;[]%$£@^&()-+=<>,")
//
//        let searchTextComponents = searchText.components(separatedBy: delimiters)
//        let filteredSearchText = searchTextComponents.joined(separator: " ")
//        let trimmedSearchText = removeExcessiveSpaces(from: filteredSearchText).lowercased()
//
////        if !trimmedSearchText.isEmpty {
//            Task {
//                let searchResults = await chatsViewModel.findUsersFromDB(where: trimmedSearchText)
//                let resultCellsVM = searchResults.map { DBUser in
//                    ResultsCellViewModel(userDB: DBUser)
//                }
//                resultsTableController.filteredUsers = resultCellsVM
//                resultsTableController.userSearch = .global
//                resultsTableController.tableView.reloadData()
//            }
////        }
//    }
    
    func filterContentForSearchText(_ searchText: String) -> [ResultsCellViewModel] {
        var resultsCell: [ResultsCellViewModel] = []
        
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
        let searchResultData = AlgoliaSearchManager.shared.performSearch(searchBar.text!)
        
        let filteredUsers = searchResultData.compactMap { resultData in
            ResultsCellViewModel(user: resultData.name, userProfileImageLink: resultData.profileImageLink)
        }
        if let resultsTableVC = searchController.searchResultsController as? ResultsTableController {
////            if !filteredResults.isEmpty {
////                resultsTableVC.filteredUsers = filteredResults
////                resultsTableVC.userSearch = .local
////                resultsTableVC.tableView.reloadData()
////            } else {
//                performGlobalSearch(searchBar.text!)
            resultsTableVC.filteredUsers = filteredUsers
            resultsTableVC.tableView.reloadData()
////            }
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




final class AlgoliaSearchManager {
    
    static let shared = AlgoliaSearchManager()
    
    private let client = SearchClient(appID: "TRVTKK4YUR", apiKey: "5ba2aee5ee2c0879fcd16f112a66e821")
    private lazy var index = client.index(withName: "Users")
    
    private init() {}
    
    func performSearch(_ searchText: String) -> [AlgoliaResultData] {
//        let settings = Settings().set(\.searchableAttributes, to: ["name"])
        
        let text = Query(searchText)
        
//        var query = Query("s")
//        text.attributesToRetrieve = ["name"]
        do {
//            try index.setSettings(settings)
            let result = try index.search(query: text)
//            let hits = result.hits
            
            return result.hits.compactMap { hitJson in
                if let name = hitJson.object["name"]?.object() as? String,
                    let profileImage = hitJson.object["photo_url"]?.object() as? String
                {
                    print(name)
                    return AlgoliaResultData(name: name, profileImageLink: profileImage)
                }
                return nil
            }
            
//            for hit in hits {
//                if let name = hit.object["name"] {
//                    print(name)
//                }
//            }
        } catch {
            print("Error while searching for index field: ", error)
        }
        return []
    }
}

struct AlgoliaResultData {
    let name: String
    let profileImageLink: String
}


