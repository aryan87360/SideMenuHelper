//
//  SideMenuHelper.swift
//  SideMenu
//
//  Created by Aryan Sharma on 28/08/24.
//

import UIKit

enum SideMenuLayout {
    case safeArea
    case fullScreen
}

enum Side {
    case left
    case right
}

protocol SideMenuHelperDelegate: AnyObject {
    func sideMenuDidShow()
    func sideMenuDidDismiss()
}

class SideMenuHelper {

    typealias DismissButtonConfiguration = (UIButton) -> Void
    typealias SideMenuCompletion = () -> Void

    static weak var delegate: SideMenuHelperDelegate?

    private static var currentSideMenuWindow: UIWindow?
    private static var currentSideMenuRootViewController: UIViewController?
    private static var currentSideMenuSide: Side?

    static func showSideMenu(
        contentViewController: UIViewController,
        layout: SideMenuLayout = .safeArea,
        sideLayout: Side,
        fractionalWidth: CGFloat = 0.6,
        edgeInsets: UIEdgeInsets = .zero,
        dismissButtonConfig: DismissButtonConfiguration? = nil,
        animationDuration: TimeInterval = 0.3,
        springDamping: CGFloat = 1.0,
        initialSpringVelocity: CGFloat = 0.5,
        options: UIView.AnimationOptions = [],
        dismissOnBackgroundTap: Bool = true,
        cornerRadius: CGFloat = 0,
        completion: SideMenuCompletion? = nil
    ) {
        let newWindow = UIWindow(frame: UIScreen.main.bounds)
        newWindow.windowLevel = UIWindow.Level.alert
        newWindow.backgroundColor = .clear

        let blackView = UIView(frame: CGRect(x: -(Int.max/2), y: 0, width: Int.max, height: Int.max))
                blackView.backgroundColor = .black
                blackView.alpha = 0.4

        if dismissOnBackgroundTap {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapOnDismissButton))
            blackView.addGestureRecognizer(tapGesture)
        }

        newWindow.addSubview(blackView)
        newWindow.makeKeyAndVisible()

        let containerVC = UIViewController()
        containerVC.view.backgroundColor = .clear

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        newWindow.addGestureRecognizer(panGesture)

        let dismissButton: UIButton = {
            let button = UIButton(type: .custom)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(didTapOnDismissButton), for: .touchUpInside)
            return button
        }()

        dismissButtonConfig?(dismissButton)

        newWindow.rootViewController = containerVC

        containerVC.addChild(contentViewController)
        containerVC.view.addSubview(dismissButton)
        containerVC.view.addSubview(contentViewController.view)
        contentViewController.didMove(toParent: containerVC)

        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentViewController.view.layer.cornerRadius = cornerRadius
        contentViewController.view.layer.masksToBounds = true

        let widthMultiplier = fractionalWidth // Use fractional width multiplier

        switch layout {
        case .safeArea:
            NSLayoutConstraint.activate([
                contentViewController.view.topAnchor.constraint(equalTo: containerVC.view.safeAreaLayoutGuide.topAnchor, constant: edgeInsets.top),
                contentViewController.view.bottomAnchor.constraint(equalTo: containerVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -edgeInsets.bottom),
                contentViewController.view.widthAnchor.constraint(equalTo: containerVC.view.widthAnchor, multiplier: widthMultiplier),
                sideLayout == .left ? contentViewController.view.leadingAnchor.constraint(equalTo: containerVC.view.leadingAnchor, constant: edgeInsets.left) : contentViewController.view.trailingAnchor.constraint(equalTo: containerVC.view.trailingAnchor, constant: -edgeInsets.right),
                
                dismissButton.centerYAnchor.constraint(equalTo: containerVC.view.centerYAnchor),
                sideLayout == .left ? dismissButton.leadingAnchor.constraint(equalTo: contentViewController.view.trailingAnchor, constant: 10) : dismissButton.trailingAnchor.constraint(equalTo: contentViewController.view.leadingAnchor, constant: -10)
            ])
            
        case .fullScreen:
            NSLayoutConstraint.activate([
                contentViewController.view.topAnchor.constraint(equalTo: containerVC.view.topAnchor, constant: edgeInsets.top),
                contentViewController.view.bottomAnchor.constraint(equalTo: containerVC.view.bottomAnchor, constant: -edgeInsets.bottom),
                contentViewController.view.widthAnchor.constraint(equalTo: containerVC.view.widthAnchor, multiplier: widthMultiplier),
                sideLayout == .left ? contentViewController.view.leadingAnchor.constraint(equalTo: containerVC.view.leadingAnchor, constant: edgeInsets.left) : contentViewController.view.trailingAnchor.constraint(equalTo: containerVC.view.trailingAnchor, constant: -edgeInsets.right),
                
                dismissButton.centerYAnchor.constraint(equalTo: containerVC.view.centerYAnchor),
                sideLayout == .left ? dismissButton.leadingAnchor.constraint(equalTo: contentViewController.view.trailingAnchor, constant: 10) : dismissButton.trailingAnchor.constraint(equalTo: contentViewController.view.leadingAnchor, constant: -10)
            ])
        }

        let screenWidth = UIScreen.main.bounds.width
        let initialX: CGFloat = sideLayout == .left ? -screenWidth * widthMultiplier : screenWidth
        
        newWindow.frame = CGRect(x: initialX, y: 0, width: screenWidth, height: UIScreen.main.bounds.height)

        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            usingSpringWithDamping: springDamping,
            initialSpringVelocity: initialSpringVelocity,
            options: options,
            animations: {
                newWindow.frame = CGRect(x: 0, y: 0, width: screenWidth, height: UIScreen.main.bounds.height)
            },
            completion: { _ in
                completion?()
                delegate?.sideMenuDidShow()
            }
        )

        self.currentSideMenuWindow = newWindow
        self.currentSideMenuRootViewController = containerVC
        self.currentSideMenuSide = sideLayout
    }

    @objc private static func didTapOnDismissButton() {
        dismissSideMenu()
    }

    static func dismissSideMenu() {
        guard let window = currentSideMenuWindow, let rootVC = currentSideMenuRootViewController else { return }

        UIView.animate(withDuration: 0.3, animations: {
            let screenWidth = UIScreen.main.bounds.width
            let finalX: CGFloat = currentSideMenuSide == .left ? -screenWidth * 0.60 : screenWidth
            window.frame = CGRect(x: finalX, y: 0, width: screenWidth, height: UIScreen.main.bounds.height)
        }) { _ in
            rootVC.children.forEach { childVC in
                childVC.willMove(toParent: nil)
                childVC.view.removeFromSuperview()
                childVC.removeFromParent()
            }
            window.removeFromSuperview()
            window.resignKey()
            currentSideMenuWindow = nil
            currentSideMenuRootViewController = nil
            delegate?.sideMenuDidDismiss()
        }
    }

    @objc private static func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let window = currentSideMenuWindow else { return }

        let translation = gesture.translation(in: window)
        let screenWidth = UIScreen.main.bounds.width

        switch gesture.state {
        case .began, .changed:
            let newX: CGFloat
            if currentSideMenuSide == .left {
                newX = min(max(-screenWidth * 0.60, window.frame.origin.x + translation.x), 0)
            } else {
                newX = min(max(screenWidth - window.frame.width * 0.60, window.frame.origin.x + translation.x), screenWidth - window.frame.width * 0.60)
            }
            window.frame.origin.x = newX
            gesture.setTranslation(.zero, in: window)
        case .ended:
            let velocity = gesture.velocity(in: window)
            let threshold: CGFloat = 0.3
            let shouldDismiss: Bool
            if currentSideMenuSide == .left {
                shouldDismiss = velocity.x < -500 || window.frame.origin.x < -screenWidth * threshold
            } else {
                shouldDismiss = velocity.x > 500 || window.frame.origin.x > screenWidth - window.frame.width * (1 - threshold)
            }
            if shouldDismiss {
                dismissSideMenu()
            } else {
                UIView.animate(withDuration: 0.3) {
                    window.frame.origin.x = 0
                }
            }
        default:
            break
        }
    }
}
