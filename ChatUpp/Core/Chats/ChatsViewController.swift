//
//  ConversationsViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/6/23.
//

import UIKit
import SkeletonView

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

    lazy private var resultsTableController = {
        let resultsTableController = ResultsTableController()
        resultsTableController.coordinatorDelegate = self.coordinatorDelegate
        return resultsTableController
    }()
    
    private var searchController: UISearchController!
    
    private var lastSearchedText: String?
    private var searchTimer: Timer?
    
    // MARK: - UI SETUP

    override func viewDidLoad() {
        super.viewDidLoad()
//        view.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        setupBinding()
        configureTableView()
        setupSearchController()
        chatsViewModel.setupChatListener()
        self.toggleSkeletonAnimation(.initiate)
    }
    
    deinit {
        print("ChatsVC was DEINITED!==")
    }
    
    private func configureTableView() {
        tableView.register(ChatsCell.self, forCellReuseIdentifier: CellIdentifire.chatCell)
        view.addSubview(tableView)
        tableView.delegate = self
        tableViewDataSource = ChatsTableViewDataSource(viewModel: chatsViewModel)
        tableView.dataSource = tableViewDataSource
        tableView.isSkeletonable = true
        tableView.pin(to: view)
        tableView.rowHeight = 70
        tableView.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        tableView.separatorColor = #colorLiteral(red: 0.6390894651, green: 0.6514347792, blue: 0.6907400489, alpha: 1).withAlphaComponent(0.6)
    }
    
    // MARK: - Binding
    
    private func setupBinding() {
        chatsViewModel.onInitialChatsFetched = { [weak self] in
            Task { @MainActor in
                self?.tableView.reloadData()
                self?.toggleSkeletonAnimation(.terminate)
            }
        }
        
        chatsViewModel.reloadCell = {
            DispatchQueue.main.async {
                let indexPath = IndexPath(row: 0, section: 0)
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        }
    }
    
    func toggleSkeletonAnimation(_ value: Skeletonanimation) {
        if value == .initiate {
            initiateSkeletonAnimation()
        } else {
            terminateSkeletonAnimation()
        }
    }
    // MARK: - SkeletonView
    
    private func initiateSkeletonAnimation() {
        let skeletonAnimationColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        let skeletonItemColor = #colorLiteral(red: 0.4780891538, green: 0.7549679875, blue: 0.8415568471, alpha: 1)
        tableView.showGradientSkeleton(usingGradient: .init(baseColor: skeletonItemColor, secondaryColor: skeletonAnimationColor), delay: TimeInterval(0), transition: SkeletonTransitionStyle.crossDissolve(0.7))
        
//        tableView.showAnimatedGradientSkeleton(usingGradient: .init(baseColor: skeletonItemColor, secondaryColor: skeletonAnimationColor), transition: .crossDissolve(.signalingNaN))
    }
    
    private func terminateSkeletonAnimation() {
        tableView.stopSkeletonAnimation()
        tableView.hideSkeleton(transition: SkeletonTransitionStyle.none)
    }
    
    func setupSearchController() {
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        resultsTableController.searchBar = searchController.searchBar
        navigationItem.searchController = searchController
        definesPresentationContext = true
        navigationItem.hidesSearchBarWhenScrolling = true
    }
    
    func filterContentForSearchText(_ searchText: String) -> [ResultsCellViewModel] {
       
        return chatsViewModel.cellViewModels.enumerated().compactMap ({ index, chatCell in
           
            let delimiters = CharacterSet(charactersIn: " /.:!?;[]%$£@^&()-+=<>,")
            
            let searchTextComponents = searchText.components(separatedBy: delimiters)
            let filteredSearchText = searchTextComponents.joined(separator: " ")
            let trimmedSearchText = removeExcessiveSpaces(from: filteredSearchText).lowercased()
            
            let conversation = chatsViewModel.chats[index]
            
            guard let user = chatCell.member,
                  let userName = user.name,
                  let userProfilePhotoURL = user.photoUrl else {return nil}
            
            let nameSubstrings = userName.lowercased().components(separatedBy: delimiters)
            
            for substring in nameSubstrings {
                if substring.hasPrefix(trimmedSearchText) {
                    return ResultsCellViewModel(userID: user.userId, userName: userName, userImageURL: userProfilePhotoURL, chat: conversation, imageData: chatCell.memberProfileImage.value)
                }
            }
            if userName.lowercased().hasPrefix(trimmedSearchText) {
                return ResultsCellViewModel(userID: user.userId, userName: userName, userImageURL: userProfilePhotoURL, chat: conversation)
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
    
    // TODO: Transfer to viewModel
    private func performSearch(_ text: String) {
        Task {
            let searchResultData = await AlgoliaSearchManager.shared.performSearch(text)
            if text == lastSearchedText {
                let filteredResults = searchResultData.compactMap { resultData in
                    return ResultsCellViewModel(userID: resultData.userID, userName: resultData.name, userImageURL: resultData.profileImageLink)
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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let cellVM = self.chatsViewModel.cellViewModels[indexPath.item]
        
        guard let user = cellVM.member,
              let memberName = user.name else {return}
        
        let memberID = user.userId
        let chat = cellVM.chat
        let memberPhoto = cellVM.memberProfileImage.value
        
        let conversationViewModel = ConversationViewModel(memberID: memberID, memberName: memberName, conversation: chat, imageData: memberPhoto)
        conversationViewModel.updateUnreadMessagesCount = {
            try await cellVM.fetchUnreadMessagesCount()
        }
        coordinatorDelegate?.openConversationVC(conversationViewModel: conversationViewModel)
    }
}
