//
//  ConversationsViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/6/23.
//

import UIKit
import FirebaseAuth

class ConversationsViewController: UIViewController {
    
    struct Cells {
        static let conversationCell = "ConversationCell"
    }
    
    let tableView = UITableView()
    
    var conversationsViewModel = ConversationsViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
//        conversationsViewModel.signOut()
        setupBinding()
        tableView.register(ConversationCell.self, forCellReuseIdentifier: Cells.conversationCell)
        configureTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        conversationsViewModel.validateUserAuthentication()
    }
    
    private func setupBinding() {
        conversationsViewModel.showSignInForm.bind { [weak self] showForm in
            if showForm == true {
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Cells.conversationCell, for: indexPath) as? ConversationCell else {
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

// MARK: - Conversations ViewModel

final class ConversationsViewModel {
    
    var showSignInForm: ObservableObject<Bool> = ObservableObject(false)
    
    func validateUserAuthentication() {
        
        let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
        
        guard let user = authUser else {
            showSignInForm.value = true
            return
        }
        showSignInForm.value = false
        print("User:", user)
    }
}

// MARK: - Create separate file extansion for this

extension UIView {
    func pin(to superView: UIView) {
        translatesAutoresizingMaskIntoConstraints                             = false
        topAnchor.constraint(equalTo: superView.topAnchor).isActive           = true
        bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive     = true
        leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive   = true
        trailingAnchor.constraint(equalTo: superView.trailingAnchor).isActive = true
    }
}
