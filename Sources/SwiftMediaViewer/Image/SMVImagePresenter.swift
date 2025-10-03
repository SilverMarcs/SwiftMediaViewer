//
//  SMVImagePresenter.swift
//  SwiftMediaViewer
//
//  Created by Zabir Raihan on 03/10/2025.
//

import SwiftUI

public struct SMVImageGateway: ViewModifier {
    let presenter: SMVImagePresenter

    public init(presenter: SMVImagePresenter) {
        self.presenter = presenter
    }

    public func body(content: Content) -> some View {
        @Bindable var p = presenter

        content
            .conditionalFullScreen(item: $p.payload) { payload in
                SMVImageModal(
                    urls: payload.urls,
                    startIndex: payload.startIndex,
                    targetSize: payload.targetSize,
                    namespace: Namespace().wrappedValue
                )
            }
    }
}

public extension View {
    func smvImageGateway(presenter: SMVImagePresenter) -> some View {
        modifier(SMVImageGateway(presenter: presenter))
    }
}

public struct SMVImagePayload: Identifiable, Equatable {
    public let id = UUID()
    public let urls: [String]
    public let startIndex: Int
    public let targetSize: Int

    public init(urls: [String], startIndex: Int = 0, targetSize: Int = 600) {
        self.urls = urls
        self.startIndex = startIndex
        self.targetSize = targetSize
    }
}

@Observable
public final class SMVImagePresenter {
    public var payload: SMVImagePayload?
    
    public init() {}

    public func present(urls: [String], startIndex: Int = 0, targetSize: Int) {
        payload = SMVImagePayload(urls: urls, startIndex: startIndex, targetSize: targetSize)
    }

    public func present(url: String, targetSize: Int) {
        present(urls: [url], startIndex: 0, targetSize: targetSize)
    }

    public func dismiss() {
        payload = nil
    }
}
