//
//  UIViewController+Extension.swift
//  Nower-iOS
//
//  Created by 신종원 on 5/5/25.
//

import UIKit

extension UIViewController {
    func showToast(message: String, duration: TimeInterval = 2.0) {
        let toast = ToastView(message: message)
        toast.alpha = 0
        toast.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)

        view.addSubview(toast)
        toast.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(40)
            $0.leading.greaterThanOrEqualToSuperview().offset(40)
            $0.trailing.lessThanOrEqualToSuperview().inset(40)
        }

        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseOut,
                       animations: {
            toast.alpha = 1
            toast.transform = .identity
        }, completion: { _ in
            UIView.animate(withDuration: 0.3,
                           delay: duration,
                           options: .curveEaseIn,
                           animations: {
                toast.alpha = 0
                toast.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }, completion: { _ in
                toast.removeFromSuperview()
            })
        })
    }
}
