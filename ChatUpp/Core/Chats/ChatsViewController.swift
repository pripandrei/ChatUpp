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
    
    // MARK: - CELL IDENTIFIER
    
    struct Cell {
        static let chatCell = "ChatCell"
    }
    
    // MARK: - UI SETUP

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupBinding()
        tableView.register(ChatsCell.self, forCellReuseIdentifier: Cell.chatCell)
        configureTableView()
        chatsViewModel.validateUserAuthentication()
        Task {
            await chatsViewModel.getRecentMessages()
        }
    }
    
    private func setupBinding() {
        chatsViewModel.isUserSignedOut.bind { [weak self] isSignedOut in
            if isSignedOut == true {
                self?.presentLogInForm()
            }
        }
        
        chatsViewModel.recentMessages.bind { [weak self] messages in
            guard let self = self else { return }
            if let _ = messages {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func configureTableView() {
        view.addSubview(tableView)
        setTableViewDelegates()
        tableView.pin(to: view)
        tableView.rowHeight = 70
        
    }
    
    func setTableViewDelegates() {
        tableView.dataSource = self
//        tableView.delegate = self
    }
}


// MARK: - TableView DataSource

extension ChatsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let messageCount = chatsViewModel.recentMessages.value?.count else { return 0}
        return messageCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Cell.chatCell, for: indexPath) as? ChatsCell else {
            fatalError("Unable to dequeu reusable cell")
        }
    
        if chatsViewModel.recentMessages.value != nil {
            cell.messageLable.text = self.chatsViewModel.recentMessages.value![indexPath.item].messageBody
            cell.dateLable.text = self.chatsViewModel.recentMessages.value![indexPath.item].timestamp
        }
    
        return cell
    }
}

// MARK: - Navigation

extension ChatsViewController
{
    func presentLogInForm() {
        let nav = UINavigationController(rootViewController: LoginViewController())
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

