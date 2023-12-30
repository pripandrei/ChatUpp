//
//  ProfileEditingViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/30/23.
//

import UIKit

class ProfileEditingViewController: UIViewController {

    weak var coordinatorDelegate: Coordinator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)
//        navigationController?.isNavigationBarHidden = true
        // Do any additional setup after loading the view.
    }
    
 
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
