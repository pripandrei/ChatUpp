//
//  ChatsViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/6/23.
//

import UIKit
import SkeletonView
import Combine


class ChatsViewController: UIViewController {
    
    weak var coordinatorDelegate: Coordinator?
    
    private var tableView: UITableView!
    private var chatsViewModel: ChatsViewModel!
    private var tableViewDataSource: ChatsTableViewDataSource!
    private var subscriptions = Set<AnyCancellable>()

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
        
//        try? AuthenticationManager.shared.signOut()
//        FirebaseChatService.shared.migrateParticipantsField()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 200) {
        
        self.chatsViewModel = ChatsViewModel()
        setupBinding()
        configureTableView()
        setupSearchController()
        chatsViewModel.activateOnDisconnect()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        RealtimeUserService.shared.updateUserActiveStatus(isActive: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    deinit {
        print("ChatsVC was DEINITED!==")
    }
    
    private func configureTableView() {
        tableView = UITableView()
        tableView.register(ChatsCell.self, forCellReuseIdentifier: ReuseIdentifire.ChatTableCell.chat.identifire)
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
    
    private func setupBinding()
    {
        chatsViewModel.$chatModificationType
            .sink { [weak self] modificationType in
                guard let self = self else {return}
                
                switch modificationType 
                {
                case .added:
                    addNewRow()
                case .updated(let rowPosition):
                    moveRow(at: rowPosition)
                case .removed(let rowPosition):
                   removeRow(from: rowPosition)
                default: break
                }
            }.store(in: &subscriptions)
        
        chatsViewModel.$initialChatsDoneFetching
            .filter({ $0 == true })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }.store(in: &subscriptions)
    }
    
    // MARK: - SkeletonView
    
    func toggleSkeletonAnimation(_ value: SkeletonAnimationState) {
        if value == .initiated {
            initiateSkeletonAnimation()
        } else {
            terminateSkeletonAnimation()
        }
    }
    
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
            
            let conversation = chatsViewModel.cellViewModels[index].chat
            
            guard let user = chatCell.chatUser,
                  let userName = user.name else {return nil}
            
            let nameSubstrings = userName.lowercased().components(separatedBy: delimiters)
            
            for substring in nameSubstrings {
                if substring.hasPrefix(trimmedSearchText) {
                    return ResultsCellViewModel(memberUser: user, chat: conversation, imageData: chatCell.memberProfileImage, unreadMessageCount: chatCell.unreadMessageCount)
                }
            }
            if userName.lowercased().hasPrefix(trimmedSearchText) {
                return ResultsCellViewModel(memberUser: user, chat: conversation, imageData: chatCell.memberProfileImage, unreadMessageCount: chatCell.unreadMessageCount)
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
    
    /// - cleanup 
    func cleanup() {
        coordinatorDelegate = nil
        tableViewDataSource = nil
        searchController = nil
        lastSearchedText = nil
        searchTimer = nil
////        chatsViewModel.cancelUsersListener()
        chatsViewModel.chatsListener?.remove()
        chatsViewModel.usersListener?.remove()
        chatsViewModel = nil
        tableView = nil
    }
}

// MARK: - chats row update
extension ChatsViewController
{
    private func addNewRow() {
        let indexPath = IndexPath(row: 0, section: 0)
        self.tableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    private func moveRow(at position: Int) {
        let destinationIndexPath = IndexPath(row: 0, section: 0)
        self.tableView.moveRow(at: IndexPath(row: position, section: 0), to: destinationIndexPath)
    }
    
    private func removeRow(from position: Int) {
        let removedIndex = IndexPath(row: position, section: 0)
        self.tableView.deleteRows(at: [removedIndex], with: .none)
    }
}

//MARK: - Search controller results update

extension ChatsViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        searchTimer?.invalidate()
        // If seach bar is empty or contains spaces
        guard let text = searchBar.text,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else
        {
            lastSearchedText = nil
            updateTableView(withResults: [], toggleSkeletonAnimation: .terminated)
            return
        }
        
        // If search bar contains local names
        let filteredResults = filterContentForSearchText(searchBar.text!)
        guard filteredResults.isEmpty else {
            resultsTableController.userSearch = .local
            updateTableView(withResults: filteredResults, toggleSkeletonAnimation: .terminated)
            return
        }

        // If search is performed globaly (database)
        if resultsTableController.filteredUsers.isEmpty {
            resultsTableController.toggleSkeletonAnimation(.initiated)
        }
        lastSearchedText = text
        
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] _ in
            self?.performSearch(text)
        })
    }
    
    private func updateTableView(withResults filteredResults: [ResultsCellViewModel], toggleSkeletonAnimation value: SkeletonAnimationState) {
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
                    return ResultsCellViewModel(memberUser: resultData)
                }
                await MainActor.run {
                    resultsTableController.userSearch = .global
                    updateTableView(withResults: filteredResults, toggleSkeletonAnimation: .terminated)
                }
            }
        }
    }
}

//MARK: - Table view delegate
extension ChatsViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let cellVM = self.chatsViewModel.cellViewModels[indexPath.item]
        
        guard let user = cellVM.chatUser else {return}
        
        let chat = cellVM.chat
        let memberPhoto = cellVM.memberProfileImage
        
        let conversationViewModel = ConversationViewModel(conversationUser: user, conversation: chat, imageData: memberPhoto)
        coordinatorDelegate?.openConversationVC(conversationViewModel: conversationViewModel)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let deleteChat = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.presentDeletionAlert(for: indexPath)
            completion(true)
        }
        
        deleteChat.image = swipeLayout(icon: "trash", text: "Delete", size: 20)
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteChat])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}

//MARK: - Chat deletion
extension ChatsViewController
{
    private func presentDeletionAlert(for indexPath: IndexPath)
    {
        let participantName = chatsViewModel.cellViewModels[indexPath.row].chatUser?.name
        let alertTitle = "Permanently delete chat with \(participantName ?? "User")?"
        let alertTitleAttributes: [NSAttributedString.Key:Any] = [.font: UIFont.systemFont(ofSize: 15), .foregroundColor: #colorLiteral(red: 0.7950155139, green: 0.7501099706, blue: 0.7651557922, alpha: 1)]
        
        let alert = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet)
        
        alert.setValue(NSAttributedString(string: alertTitle, attributes: alertTitleAttributes), forKey: "attributedTitle")
        
        alert.addAction(UIAlertAction(title: "Delete just for me", style: .destructive) { [weak self] action in
            self?.chatsViewModel.initiateChatDeletion(for: .forMe, at: indexPath)
            self?.tableView.deleteRows(at: [indexPath], with: .fade)
            print("deleted just for me!!!")
        })
        
        alert.addAction(UIAlertAction(title: "Delete for me and \(participantName ?? "User")", style: .destructive) { [weak self] action in
            self?.chatsViewModel.initiateChatDeletion(for: .forBoth, at: indexPath)
            self?.tableView.deleteRows(at: [indexPath], with: .fade)
            print("deleted for both!!!")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        self.present(alert, animated: true)
    }
}

//MARK: - row swipe image configuration
extension ChatsViewController
{
    private func swipeLayout(icon: String, text: String, size: CGFloat) -> UIImage
    {
        let config = UIImage.SymbolConfiguration(pointSize: size, weight: .regular, scale: .large)
        let img = UIImage(systemName: icon, withConfiguration: config)?.withTintColor(.white, renderingMode: .alwaysOriginal)
        
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .white
        label.text = text
        
        let tempView = UIStackView(frame: .init(x: 0, y: 0, width: 50, height: 50))
        let imageView = UIImageView(frame: .init(x: 0, y: 0, width: img!.size.width, height: img!.size.height))
        imageView.contentMode = .scaleAspectFit
        tempView.axis = .vertical
        tempView.alignment = .center
        tempView.spacing = 2
        imageView.image = img
        tempView.addArrangedSubview(imageView)
        tempView.addArrangedSubview(label)
        
        let renderer = UIGraphicsImageRenderer(bounds: tempView.bounds)
        let image = renderer.image { rendererContext in
            tempView.layer.render(in: rendererContext.cgContext)
        }
        return image
    }
}

