//
//  StickersPackCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/23/26.
//

import UIKit

//MARK: - Static variables
extension StickersPackCell
{
    private static let renderQueue = DispatchQueue(
        label: "thorvg.render.serial.queue",
        qos: .userInitiated
    )
    static let reuseID = "StickerCell"
}

final class StickersPackCell: UICollectionViewCell, FrameTickRecievable
{
    private let stickerView: StickerView!
    private var isVisible = false
    private var isRendering = false
    private var lastRenderTime: CFTimeInterval = 0
    
    // MARK: Init
    override init(frame: CGRect)
    {
        self.stickerView = .init()
        super.init(frame: frame)
        setupStickerView()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    deinit {
        cleanup(destroyBuffer: true)
    }

    // MARK: Setup
    private func setupStickerView()
    {
        stickerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stickerView)
        
        NSLayoutConstraint.activate([
            stickerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stickerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stickerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stickerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(name: String)
    {
        stickerView.cleanup()
        stickerView.setupSticker(name)
    }

    func setVisible(_ visible: Bool)
    {
        isVisible = visible
        if visible {
            FrameTicker.shared.add(self)
        } else {
            FrameTicker.shared.remove(self)
        }
    }

    func didReceiveFrameTick(deltaTime: CFTimeInterval)
    {
        guard isVisible, !isRendering else { return }

        //  Drop frames if renderer lags
        if CACurrentMediaTime() - lastRenderTime < (1.0 / 60.0)
        {
            return
        }

        lastRenderTime = CACurrentMediaTime()
        isRendering = true

        Self.renderQueue.async { [weak self] in
            guard let self else { return }
            defer { self.isRendering = false }
            self.stickerView.render(deltaTime: deltaTime)
        }
    }

    private func cleanup(destroyBuffer: Bool = false)
    {
        FrameTicker.shared.remove(self)
        stickerView.cleanup(withBufferDestruction: destroyBuffer)
    }

    override func prepareForReuse()
    {
        super.prepareForReuse()
        FrameTicker.shared.remove(self)
        stickerView.cleanup()
    }
}
