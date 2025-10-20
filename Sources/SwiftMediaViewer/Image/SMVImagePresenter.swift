//
//  SMVImagePresenter.swift
//  SwiftMediaViewer
//
//  Created by Zabir Raihan on 03/10/2025.
//

import SwiftUI

@MainActor
public final class SMVImagePresenter {
    public static let shared = SMVImagePresenter()
    
    #if os(macOS)
    private var presentedWindow: NSWindow?
    #else
    private weak var presentedController: UIViewController?
    #endif
    
    private init() {}
    
    public func present(url: URL, targetSize: Int = 600) {
        #if os(macOS)
        presentMacOS(url: url, targetSize: targetSize)
        #else
        presentIOS(url: url, targetSize: targetSize)
        #endif
    }
    
    #if os(macOS)
    private func presentMacOS(url: URL, targetSize: Int) {
        guard let keyWindow = NSApplication.shared.keyWindow else {
            return
        }
        
        let view = SMVImageModal(
            urls: [url],
            targetSize: targetSize,
            namespace: Namespace().wrappedValue
        )
        
        let hosting = NSHostingController(rootView: view)
        
        // Present as sheet attached to the key window
        keyWindow.contentViewController?.presentAsSheet(hosting)
        presentedWindow = keyWindow
    }
    #else
    private func presentIOS(url: URL, targetSize: Int) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let topVC = windowScene.windows.first(where: \.isKeyWindow)?
                .rootViewController?.topMostViewController() else {
            return
        }
        
        let view = SMVImageModal(
            urls: [url],
            targetSize: targetSize,
            namespace: Namespace().wrappedValue
        )
        
        let hosting = UIHostingController(rootView: view)
        hosting.modalPresentationStyle = .formSheet
        
        topVC.present(hosting, animated: true)
        presentedController = hosting
    }
    #endif
}

#if !os(macOS)
extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }
        if let nav = self as? UINavigationController {
            return nav.visibleViewController?.topMostViewController() ?? self
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? self
        }
        return self
    }
}
#endif
