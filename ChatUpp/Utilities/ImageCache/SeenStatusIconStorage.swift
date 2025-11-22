//
//  SeenStatusIconStorage.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/22/25.
//

import UIKit

struct SeenStatusIconStorage
{
    static var cache = [String: UIImage]()
    
    static func image(named name: String,
                      size: CGSize,
                      color: UIColor) -> UIImage? {
        
        let key = "\(name)-\(size.width)x\(size.height)-\(color.description)"
        
        if let cached = cache[key]
        {
            return cached
        }
        
        guard let base = UIImage(named: name)?
            .withTintColor(color)
            .resize(to: size)
        else { return nil }
        
        cache[key] = base
        return base
    }
}
