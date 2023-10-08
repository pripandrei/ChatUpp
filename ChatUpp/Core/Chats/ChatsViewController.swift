//
//  ConversationsViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/6/23.
//

import UIKit
import FirebaseAuth

class ChatsViewController: UIViewController {
    
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
        
//        chatsViewModel.validateUserAuthentication()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("Appeared")
    }
    
    private func setupTableView() {
        tableView.register(ChatsCell.self, forCellReuseIdentifier: Cell.chatCell)
        configureTableView()

//        chatsViewModel.validateUserAuthentication()

    }
    
    private func setupBinding() {
        chatsViewModel.isUserSignedOut.bind { [weak self] isSignedOut in
            if isSignedOut == true { self?.presentLogInForm() }
        
            else {
                self?.chatsViewModel.onDataFetched = {
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                }
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
        present(nav, animated: true)
    }
}
