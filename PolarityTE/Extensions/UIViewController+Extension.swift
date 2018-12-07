//
//  UIViewController+Extension.swift
//  PolarityTE
//
//  Created by Joel Arcos on 12/5/18.
//  Copyright © 2018 Joel Arcos. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAlert(message: String, closeTitle: String = "Ok", callback: ((UIAlertAction) -> Void)?=nil){
        let alertController = UIAlertController(title: "PolarityTE", message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: closeTitle, style: .default, handler: callback))
        
        present(alertController, animated: true, completion: nil)
    }
    
    func hideKeyboardWhenTappedAround() {
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
}
