//
//  UIViewController+ActivityIndicator.swift
//  PolarityTE
//
//  Created by Joel Arcos on 12/8/18.
//  Copyright © 2018 Joel Arcos. All rights reserved.
//

import UIKit

var overalyView: UIView = UIView()
var activityIndicatorOverlay: UIView = UIView()
var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()

//  =================================================================================================
//  API
//  =================================================================================================
extension UIViewController {
    func showActivityIndicatorOverlay() {
        setupOverlay()
        setupActivityIndicatorOverlay()
        setupActivityIndicator()
        stackViews()
        activityIndicator.startAnimating()
    }
    
    // remove activity indicator from this view
    func hideActivityIndicatorOverlay() {
        activityIndicator.stopAnimating()
        activityIndicatorOverlay.removeFromSuperview()
    }
}

//  =================================================================================================
//  Internal Methods
//  ================================================================================================
extension UIViewController {
    struct Colors {
        static let white = UIColorFromHex(rgbValue: 0xffffff, alpha: 0.3)
        static let dark = UIColorFromHex(rgbValue: 0x444444, alpha: 0.7)
    }
    
    private func setupOverlay() {
        overalyView.frame = self.view.frame
        overalyView.center = self.view.center
        overalyView.backgroundColor = Colors.dark
    }
    
    private func setupActivityIndicatorOverlay() {
        activityIndicatorOverlay.frame = CGRect.init(x: 0, y: 0, width: 80, height: 80)
        activityIndicatorOverlay.center = self.view.center
        activityIndicatorOverlay.backgroundColor = Colors.dark
        activityIndicatorOverlay.clipsToBounds = true
        activityIndicatorOverlay.layer.cornerRadius = 10
    }
    
    private func setupActivityIndicator() {
        activityIndicator.frame = CGRect.init(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        activityIndicator.style = UIActivityIndicatorView.Style.whiteLarge
        activityIndicator.center = CGPoint.init(x: activityIndicatorOverlay.frame.size.width / 2, y: activityIndicatorOverlay.frame.size.height / 2)
    }
    
    private func stackViews() {
        activityIndicatorOverlay.addSubview(activityIndicator)
        overalyView.addSubview(activityIndicatorOverlay)
        self.view.addSubview(overalyView)
    }
    
    //Define UIColor from hex value

    private static func UIColorFromHex(rgbValue:UInt32, alpha:Double=1.0)->UIColor {
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        return UIColor(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
    }
    

}
