//
//  ConversationsViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/6/23.
//

import UIKit
import FirebaseAuth


class ChatsViewController: UIViewController {
    
    weak var coordinatorDelegate: Coordinator?
    
    let tableView = UITableView()
    var chatsViewModel = ChatsViewModel()
    var tableViewDataSource: UITableViewDataSource!
    
    // MARK: - CELL IDENTIFIER
    
    struct Cell {
        static let chatCell = "ChatCell"
    }
    
    // MARK: - UI SETUP

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupBinding()
        setupTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        chatsViewModel.validateUserAuthentication()
    }
    
    private func setupTableView() {
        tableView.register(ChatsCell.self, forCellReuseIdentifier: Cell.chatCell)
        configureTableView()
    }
    
    private func setupBinding() {
        chatsViewModel.onDataFetched = {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
        }
        chatsViewModel.isUserSignedOut.bind { [weak self] isSignedOut in
            if isSignedOut == true { self?.presentLogInForm() }
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

// MARK: - Navigation

extension ChatsViewController
{
    func presentLogInForm() {
        let loginVC = LoginViewController()
        let nav = UINavigationController(rootViewController: loginVC)
        nav.modalPresentationStyle = .fullScreen
        self.tabBarController?.present(nav, animated: true)
    }
}

extension ChatsViewController {

    
}
