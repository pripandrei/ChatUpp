//
//  ResultsTableController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/8/23.
//

import UIKit
import SkeletonView

enum Skeletonanimation {
    case initiate
    case terminate
}

final class ResultsTableController: UITableViewController {
    
    weak var coordinatorDelegate: Coordinator?
    
    enum UsersSearch {
        case local
        case global
    }
    
//    convenience init(coordinator: Coordinator) {
//        self.init(nibName: nil, bundle: nil)
//        self.coordinatorDelegate = coordinator
//    }
    
    var filteredUsers: [ResultsCellViewModel] = [] 
    var userSearch: UsersSearch!
    private var noUserWasFoundLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        configureTextLabel()
    }
   
    private func configureTextLabel() {
        tableView.addSubview(noUserWasFoundLabel)
        
        noUserWasFoundLabel.isHidden = true
        noUserWasFoundLabel.text = "No user's have been found"
        noUserWasFoundLabel.textColor = #colorLiteral(red: 0.547631681, green: 0.7303310037, blue: 0.989274919, alpha: 1)
        noUserWasFoundLabel.sizeToFit()
        
        noUserWasFoundLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            noUserWasFoundLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            noUserWasFoundLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor, constant: -100),
        ])
    }
    
    func toggleSkeletonAnimation(_ value: Skeletonanimation) {
        if value == .initiate {
            initiateSkeletonAnimation()
        } else {
            terminateSkeletonAnimation()
        }
    }

    private func initiateSkeletonAnimation() {
        let skeletonAnimationColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        let skeletonItemColor = #colorLiteral(red: 0.4780891538, green: 0.7549679875, blue: 0.8415568471, alpha: 1)
        tableView.showAnimatedGradientSkeleton(usingGradient: .init(baseColor: skeletonItemColor, secondaryColor: skeletonAnimationColor))
        noUserWasFoundLabel.isHidden = true
    }
    
    private func terminateSkeletonAnimation() {
        tableView.stopSkeletonAnimation()
        tableView.hideSkeleton(transition: .crossDissolve(0.25))
        noUserWasFoundLabel.isHidden = false
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ResultsTableCell.self, forCellReuseIdentifier: CellIdentifire.resultsTableCell)
        tableView.sectionHeaderTopPadding = 0
        tableView.rowHeight = 55
        tableView.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        tableView.isSkeletonable = true
        // Omit tableView to automatically go behind navigation bar
        // when Skeleton view is running
        edgesForExtendedLayout = []
    }
}

//MARK: - SKELETON TABLE VIEW DATA SOURCE

extension ResultsTableController: SkeletonTableViewDataSource {
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
       return CellIdentifire.resultsTableCell
    }
}

//MARK: - TABLE VIEW DATASOURCE
extension ResultsTableController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        if !filteredUsers.isEmpty {
            return 1
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredUsers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifire.resultsTableCell, for: indexPath) as? ResultsTableCell
        else {fatalError("Could not dequeue Results cell")}
        
        cell.configure(viewModel: filteredUsers[indexPath.item])
        noUserWasFoundLabel.isHidden = true
        
        return cell
    }
}

//MARK: - TABLE VIEW DELEGATE
extension ResultsTableController
{
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !tableView.sk.isSkeletonActive else {return nil}
        
        let tableViewHeaderFooterView = UITableViewHeaderFooterView()
        var configuration = UIListContentConfiguration.subtitleCell()
        
        if userSearch == .local {
            configuration.text = "Chats".uppercased()
        } else {
            configuration.text = "Global search".uppercased()
        }
        
        configuration.textProperties.color = .white
        configuration.textProperties.font = UIFont(name: "HelveticaNeue", size: 13)!
        
        tableViewHeaderFooterView.contentConfiguration = configuration
        tableViewHeaderFooterView.contentView.backgroundColor = .brown
        
        return tableViewHeaderFooterView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 24
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("ITEM",indexPath.item)
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        let chat = filteredUsers[indexPath.item].chat
        let memberID = filteredUsers[indexPath.item].userID
        let memberName = filteredUsers[indexPath.item].userName
        let memberPhoto = filteredUsers[indexPath.item].userImageData.value
        let conversationViewModel = ConversationViewModel(memberID: memberID, memberName: memberName, conversation: chat, imageData: memberPhoto)
        
        coordinatorDelegate?.openConversationVC(conversationViewModel: conversationViewModel)
    }
}
