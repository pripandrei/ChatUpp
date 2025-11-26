//
//  ChatsViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/6/23.
//

import UIKit
import SkeletonView
import Combine

extension UITableView {
    func contains(indexPath: IndexPath) -> Bool {
        guard indexPath.section < numberOfSections else { return false }
        return indexPath.row < numberOfRows(inSection: indexPath.section)
    }
}

class ChatsViewController: UIViewController {
    
    weak var coordinatorDelegate: Coordinator?
    
    private var tableView: UITableView!
    private var chatsViewModel: ChatsViewModel!
    private var tableViewDataSource: ChatsTableViewDataSource!
    private var subscriptions = Set<AnyCancellable>()
    private var alertPresenter: AlertPresenter = .init()

    lazy private var resultsTableController = {
        let resultsTableController = ResultsTableController()
        resultsTableController.coordinatorDelegate = self.coordinatorDelegate
        return resultsTableController
    }()
    
    private var searchController: UISearchController!
    
    private var lastSearchedText: String?
    private var searchTimer: Timer?

    // MARK: - UI SETUP
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.chatsViewModel = ChatsViewModel()
        setupBinding()
        configureTableView()
        setupSearchController()
        chatsViewModel.activateOnDisconnect()
        setupNavigationBarItems()
//        testFunction()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        RealtimeUserService.shared.updateUserActiveStatus(isActive: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if resultsTableController.shouldHideTabBar {
            resultsTableController.tabBarVisibilityProtocol?.hideTabBar()
            resultsTableController.shouldHideTabBar = false
        }
    }
    
    deinit {
        print("ChatsVC was DEINITED!==")
    }
    
    private func configureTableView() {
        tableView = UITableView()
        tableView.register(ChatCell.self, forCellReuseIdentifier: ReuseIdentifire.ChatTableCell.chat.identifire)
        view.addSubview(tableView)
        tableView.delegate = self
        tableViewDataSource = ChatsTableViewDataSource(viewModel: chatsViewModel)
        tableView.dataSource = tableViewDataSource
        tableView.isSkeletonable = true
        tableView.pin(to: view)
        tableView.rowHeight = 70
//        createBackgroundView(for: tableView)
        tableView.backgroundColor = ColorScheme.appBackgroundColor
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
        
        ChatManager.shared.$totalUnseenMessageCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.navigationItem.backBarButtonItem?.title = count > 0 ? "\(count)" : nil
                self?.navigationController?.navigationBar.setNeedsLayout()
            }.store(in: &subscriptions)
        
        MessageBannerPresenter.shared.requestChatOpenSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] chat in
                let chatVM = ChatRoomViewModel(conversation: chat)
                self?.coordinatorDelegate?.openConversationVC(conversationViewModel: chatVM)
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
    
    func setupSearchController()
    {
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        
        resultsTableController.tabBarVisibilityProtocol = tabBarController as? TabBarViewController
        resultsTableController.searchBar = searchController.searchBar
        resultsTableController.searchBar?.delegate = resultsTableController
        
        navigationItem.searchController = searchController
        definesPresentationContext = true
        navigationItem.hidesSearchBarWhenScrolling = true
        
//        searchController.searchBar.searchTextPositionAdjustment =  UIOffset(horizontal: (searchController.searchBar.bounds.width / 2), vertical: 0)
        
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField, let searchIcon = textField.leftView
        {
            textField.backgroundColor = ColorScheme.navigationSearchFieldBackgroundColor
            textField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: [.foregroundColor: #colorLiteral(red: 0.5177090168, green: 0.5074607134, blue: 0.5254157186, alpha: 1)])
            textField.textColor = ColorScheme.textFieldTextColor
            searchIcon.tintColor = #colorLiteral(red: 0.5177090168, green: 0.5074607134, blue: 0.5254157186, alpha: 1)
        }
    }
    
    func filterContentForSearchText(_ searchText: String) -> [ResultsCellViewModel]
    {
        let delimiters = CharacterSet(charactersIn: " /.:!?;[]%$£@^&()-+=<>,")
        
        let filteredSearchText = searchText
            .components(separatedBy: delimiters)
            .joined(separator: " ")
        let trimmedSearchText = removeExcessiveSpaces(from: filteredSearchText).lowercased()
        
        return chatsViewModel.cellViewModels.compactMap { chatCell in
            let searchedTitle: String? = chatCell.chat.isGroup ? chatCell.chat.name : chatCell.chatUser?.name
            
            guard let title = searchedTitle?.lowercased(), !title.isEmpty else { return nil }
            
            let resultSubstrings = title.components(separatedBy: delimiters)
            
            let isMatching = resultSubstrings.contains { $0.hasPrefix(trimmedSearchText) }
                          || title.contains(trimmedSearchText)
            
            guard isMatching else { return nil }
           
            return ResultsCellViewModel(chat: chatCell.chat, memberUser: chatCell.chatUser)
        }
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
        chatsViewModel.stopUserUpdateTimer()
        coordinatorDelegate = nil
        tableViewDataSource = nil
        searchController = nil
        lastSearchedText = nil
        searchTimer = nil
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
    
    private func removeRow(from position: Int)
    {
        let removedIndex = IndexPath(row: position, section: 0)
        guard let cell = self.tableView.dequeueReusableCell(withIdentifier: ReuseIdentifire.ChatTableCell.chat.identifire, for: removedIndex) as? ChatCell else {return}
        cell.cleanup()
        
        if navigationController?.topViewController != self {
            Utilities.windowRoot?.chatsNavigationController?.popToRootViewController(animated: true)
        }
        
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
            resultsTableController.searchType = .local
            updateTableView(withResults: filteredResults, toggleSkeletonAnimation: .terminated)
            return
        }

        // If search is performed globaly (database)
        if resultsTableController.filteredResults.isEmpty {
            resultsTableController.toggleSkeletonAnimation(.initiated)
        }
        lastSearchedText = text
        
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] _ in
            self?.performSearch(text)
        })
    }
    
    private func updateTableView(withResults filteredResults: [ResultsCellViewModel],
                                 toggleSkeletonAnimation value: SkeletonAnimationState)
    {
        resultsTableController.filteredResults = filteredResults
        resultsTableController.tableView.reloadData()
        resultsTableController.toggleSkeletonAnimation(value)
    }
    
    // TODO: Transfer to viewModel
    private func performSearch(_ text: String) {
        Task {
            if text == lastSearchedText
            {
                let searchResultData = await AlgoliaSearchManager.shared.performSearch(text)

                let usersResults = searchResultData?.users.compactMap { users in
                    return ResultsCellViewModel(memberUser: users)
                }
                
                let groupsResults = searchResultData?.groups.compactMap { groups in
                    return ResultsCellViewModel(chat: groups)
                }
                
                let filteredResults: [ResultsCellViewModel] = (usersResults ?? []) + (groupsResults ?? [])
                
                await MainActor.run {
                    resultsTableController.searchType = .global
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
        let chat = cellVM.chat

        let conversationViewModel = ChatRoomViewModel(conversation: chat)
        coordinatorDelegate?.openConversationVC(conversationViewModel: conversationViewModel)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let deleteChat = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.presentDeletionAlert(for: indexPath)
//            self?.testPresentAlert()
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
        let vm = chatsViewModel.cellViewModels[indexPath.row]
        
        alertPresenter.presentDeletionAlert(from: self, using: vm)
        { [weak self] deletionOption in
            self?.initiateChatDeletion(at: indexPath, deleteOption: deletionOption)
        }
    }

    
    private func initiateChatDeletion(at indexPath: IndexPath,
                                      deleteOption option: ChatDeletionOption)
    {
        chatsViewModel.initiateChatDeletion(for: option, at: indexPath)
        guard let cell = self.tableView.dequeueReusableCell(withIdentifier: ReuseIdentifire.ChatTableCell.chat.identifire, for: indexPath) as? ChatCell else {return}
        cell.cleanup()
        tableView.deleteRows(at: [indexPath], with: .fade)
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
//MARK: - Navigation bar items
extension ChatsViewController
{
    private func setupNavigationBarItems()
    {
        setupRightBarButtonItem()
        setupBackBackBarButtonItem()
    }
    
    private func setupRightBarButtonItem()
    {
        let trailingBarItem = UIBarButtonItem(image: UIImage(systemName: "plus.circle.fill"),
                                              style: .plain,
                                              target: self,
                                              action: #selector(presentGropupOptionScreen))
        self.navigationItem.rightBarButtonItem = trailingBarItem
        self.navigationItem.rightBarButtonItem?.tintColor = ColorScheme.actionButtonsTintColor
    }
    
    private func setupBackBackBarButtonItem()
    {
        let backButtonItem = UIBarButtonItem()
        let font = UIFont.systemFont(ofSize: 18, weight: .medium)
        backButtonItem.setTitleTextAttributes([.font: font], for: .normal)
        navigationItem.backBarButtonItem = backButtonItem
    }
    
    @objc private func presentGropupOptionScreen()
    {
        coordinatorDelegate?.showGroupCreationScreen()
    }
}


extension UIAlertController
{
    func setBackgroundColor(color: UIColor)
    {
        if let bgView = self.view.subviews.first,
           let groupView = bgView.subviews.first,
           let contentView = groupView.subviews.last,
           let second = self.view.subviews.first?.subviews.last?.subviews.last?.subviews.first?.subviews.first?.subviews.first?.subviews.first?.subviews.last // yeah i know ...
        {
            contentView.backgroundColor = color
            second.backgroundColor = color
        }
    }
}


//MARK: - Test functions
extension ChatsViewController
{
    private func testFunction()
    {
        /// - observe subcollections with user id
        ///
        Task {
            // - add empty reactions field to every message
            do {
                try await FirebaseChatService.shared.addEmptyReactionsToAllMessagesBatched()
            } catch {
                print("could not add reactions empty field to messages: ", error)
            }
    
            await FirebaseChatService.shared.observeUserChats(userId: "DESg2qjjJPP20KQDWfKpJJnozv53")
                .receive(on: DispatchQueue.main)
                .sink { chats in
                    print("Count: \(chats.count) \n Chats: \(chats)")
                }.store(in: &subscriptions)
        
        /// - update messages seen_by field from group with auth user id
            ///
            do {
                try await FirebaseChatService.shared.markAllGroupMessagesAsSeen(by: AuthenticationManager.shared.authenticatedUser?.uid ?? "")
            } catch {
                print("Error marking all group messages as seen: \(error)")
            }
        }
        
//        FirestoreUserService.shared.updateUserActiveStatus()
        
        /// - avatar downlaod
        ///
//        TestHelper.shared.downlaodUserAvatar()
        
        /// - sing out
        ///
//        try? AuthenticationManager.shared.signOut()
    }
}
