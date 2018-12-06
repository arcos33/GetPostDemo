//
//  UIImage.swift
//  PolarityTE
//
//  Created by Joel Arcos on 12/5/18.
//  Copyright © 2018 Joel Arcos. All rights reserved.
//

import UIKit

extension UIImage {
    func convertImageToBase64() -> String {
        let imageData = self.pngData()
        return imageData!.base64EncodedString()
    }
    
}
