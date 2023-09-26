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
    var conversationsViewModel = ChatsViewModel()
    
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
        20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Cell.chatCell, for: indexPath) as? ChatsCell else {
            fatalError("Unable to dequeu reusable cell")
        }
        
        cell.textLabel?.text = "+HO"
    
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



//
//  ConversationCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/7/23.
//

//import UIKit
//
//class ChatsCell: UITableViewCell {
//    
//    var userName: String?
//    var profilePhoto: String?
//    var date: Date?
//    var lastMessage: String?
////    var messageBadge: Int
//    
//    var messageLable = UILabel()
//    var profileImage = UIImageView()
//    var dateLable = UILabel()
//    var nameLabel = UILabel()
//    
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        setProfileImage()
//        setNameLabel()
//        setMessageLable()
//        setDateLable()
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    private func setNameLabel() {
//        self.addSubview(nameLabel)
//        nameLabel.backgroundColor = .brown
//        
//        setNameLableConstraints()
//    }
//    
//    private func setNameLableConstraints() {
//        nameLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            nameLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
//            nameLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -320),
//            nameLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5),
//            nameLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10)
//        ])
//    }
//    
//    private func setProfileImage() {
//        self.addSubview(profileImage)
//        profileImage.backgroundColor = .blue
//        setProfileImageConstraints()
//    }
//    
//    private func setProfileImageConstraints() {
//        profileImage.translatesAutoresizingMaskIntoConstraints = false
//    
//        NSLayoutConstraint.activate([
//            profileImage.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
//            profileImage.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -320),
//            profileImage.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5),
//            profileImage.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10)
//        ])
//    }
//    
//    private func setMessageLable() {
//        self.addSubview(messageLable)
//        messageLable.text = "Temporary message here, for testing purposes only."
//        messageLable.numberOfLines = 0
////        messageLable.adjustsFontSizeToFitWidth = true
//        messageLable.backgroundColor = .green
//        configureMessageLableConstraints()
//    }
//    
//    private func configureMessageLableConstraints() {
//        messageLable.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            messageLable.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
//            messageLable.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -55),
//            messageLable.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5),
//            messageLable.leadingAnchor.constraint(equalTo: profileImage.trailingAnchor, constant: 10)
//        ])
//    }
//    
//    private func setDateLable() {
//        self.addSubview(dateLable)
//        dateLable.backgroundColor = .cyan
//        
//        setDateLableConstraints()
//    }
//    
//    private func setDateLableConstraints() {
//        dateLable.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            dateLable.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
//            dateLable.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
//            dateLable.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5),
//            dateLable.leadingAnchor.constraint(equalTo: messageLable.trailingAnchor, constant: 10)
//        ])
//    }
//    
//}
//
