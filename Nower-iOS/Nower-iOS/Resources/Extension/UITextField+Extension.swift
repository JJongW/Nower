//
//  UITextField+Extension.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/16/25.
//
import UIKit

extension UITextField {
    func setPlaceholder(color: UIColor) {
        guard let string = self.placeholder else {
            return
        }
        attributedPlaceholder = NSAttributedString(string: string, attributes: [.foregroundColor: color])
    }
}
