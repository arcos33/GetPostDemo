//
//  String+Extension.swift
//  PolarityTE
//
//  Created by Joel Arcos on 12/5/18.
//  Copyright © 2018 Joel Arcos. All rights reserved.
//

import UIKit

extension String {
    func convertBase64ToImage() -> UIImage? {
        var result: UIImage?
        if let data = NSData(base64Encoded: self, options: []) as Data? {
            result = UIImage.init(data: data)!
        }
        return result
    }
}

