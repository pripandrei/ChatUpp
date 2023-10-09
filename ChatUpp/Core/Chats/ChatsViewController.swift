//
//  ConversationsViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/6/23.
//

import UIKit
import FirebaseAuth

// MARK: - CELL IDENTIFIER

struct Cell {
    static let chatCell = "ChatCell"
}

class ChatsViewController: UIViewController {
    
    weak var coordinatorDelegate: Coordinator?
    
    let tableView = UITableView()
    var chatsViewModel = ChatsViewModel()
    var tableViewDataSource: UITableViewDataSource!
    
    // MARK: - UI SETUP

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupBinding()
        setupTableView()
//        chatsViewModel.validateUserAuthentication()
    }
    deinit {
        print(" DEINITED!==")
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        chatsViewModel.validateUserAuthentication()
//        self.removeFromParent()
    }
    
    private func setupTableView() {
        tableView.register(ChatsCell.self, forCellReuseIdentifier: Cell.chatCell)
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
            }
        }
    }
    
    func configureTableView() {
        view.addSubview(tableView)
        tableViewDataSource = ChatsTableViewDataSource(viewModel: chatsViewModel)
        tableView.dataSource = tableViewDataSource
        tableView.pin(to: view)
        tableView.rowHeight = 70
    }
}

