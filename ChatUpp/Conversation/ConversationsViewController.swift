//
//  ConversationsViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/6/23.
//

import UIKit
import FirebaseAuth

class ConversationsViewController: UIViewController {
    
    struct Cell {
        static let conversationCell = "ConversationCell"
    }
    
    let tableView = UITableView()
    
    var conversationsViewModel = ConversationsViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
//        conversationsViewModel.signOut()
        setupBinding()
        tableView.register(ConversationCell.self, forCellReuseIdentifier: Cell.conversationCell)
        configureTableView()
        conversationsViewModel.validateUserAuthentication()
    }
    
    private func setupBinding() {
        conversationsViewModel.isUserSignedOut.bind { [weak self] isSignedOut in
            if isSignedOut == true {
                self?.presentLogInForm()
            }
        }
    }
    
    func configureTableView() {
        view.addSubview(tableView)
        setTableViewDelegates()
        tableView.pin(to: view)
        tableView.rowHeight = 50
    }
    
    func setTableViewDelegates() {
        tableView.dataSource = self
//        tableView.delegate = self
    }
}


// MARK: - TableView DataSource

extension ConversationsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Cell.conversationCell, for: indexPath) as? ConversationCell else {
            fatalError("Unable to dequeu reusable cell")
        }
        
        return cell
    }
}

// MARK: - Navigation

extension ConversationsViewController
{
    func presentLogInForm() {
        let nav = UINavigationController(rootViewController: LoginViewController())
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

