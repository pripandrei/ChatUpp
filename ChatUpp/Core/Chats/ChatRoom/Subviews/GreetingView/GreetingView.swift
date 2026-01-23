//
//  GreetingView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/9/25.
//

import UIKit

final class GreetingView: UIView
{
    private let greetingStickerView: StickerView = .init(size: .init(width: 250, height: 250))
    private var blurredView: UIVisualEffectView?
    private var lastRenderTime: CFTimeInterval = 0.0
    private var isRendering: Bool = false
    
    private let animationName: String = {
        let animationName = ["hg_5","dd_5","duck_5", "lb_5", "mb_5"].randomElement() ?? "hg_5"
        return animationName
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "No messages here yet..."
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.textColor = .white
        return label
    }()
    
    private let subTitle: UILabel = {
        let label = UILabel()
        label.text = "Send a message or tap on the greeting below."
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.textColor = .white
        return label
    }()
    
    // MARK: - Init
    init() {
        super.init(frame: .zero)
        setupView()
        setupConstraints()
        setupGreetingStickerAnimation()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Setup
    private func setupView()
    {
        backgroundColor = .clear
        layer.cornerRadius = 15
        clipsToBounds = true
        
        self.blurredView = addBlurEffect(style: .systemThinMaterialDark,
                                         backgroundColor: #colorLiteral(red: 0.2272113562, green: 0.1652361751, blue: 0.2635013759, alpha: 1),
                                         alpha: 0.2)
        
        [titleLabel, subTitle, greetingStickerView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
    }
    
    // MARK: - Layout Constraints
    private func setupConstraints()
    {
        let paddingTop: CGFloat = 15
        let paddingSides: CGFloat = 10
        let spacing: CGFloat = 8
        
        NSLayoutConstraint.activate([
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: paddingTop),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: paddingSides),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -paddingSides),
            
            // Subtitle Label
            subTitle.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: spacing),
            subTitle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: paddingSides),
            subTitle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -paddingSides),
            
            // Lottie View
            greetingStickerView.topAnchor.constraint(equalTo: subTitle.bottomAnchor, constant: spacing),
            greetingStickerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            greetingStickerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -paddingTop),
            
            // Maintain aspect ratio: width = height
            greetingStickerView.widthAnchor.constraint(equalTo: greetingStickerView.heightAnchor)
        ])
    }
    
    //MARK: - Gesture
    
    private func setupGesture()
    {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc private func handleTapGesture()
    {
        ChatManager.shared.newStickerSubject.send((animationName))
    }
    
    // MARK: - Lottie Setup
    private func setupGreetingStickerAnimation()
    {
        greetingStickerView.setupSticker(animationName)
        FrameTicker.shared.add(self)
    }

    private func cleanup()
    {
        FrameTicker.shared.remove(self)
        greetingStickerView.cleanup(withBufferDestruction: true)
    }
    
    deinit
    {
        cleanup()
//        print("deinit GreetingView")
    }
}

extension GreetingView: FrameTickRecievable
{
    func didReceiveFrameTick(deltaTime: TimeInterval)
    {
        guard !isRendering else { return }

        //  Drop frames if renderer lags
//        if CACurrentMediaTime() - lastRenderTime < (1.0 / 60.0)
//        {
//            return
//        }

        lastRenderTime = CACurrentMediaTime()
        isRendering = true

        ThorVGRenderQueue.shared.async { [weak self] in
            guard let self else { return }
            defer { self.isRendering = false }
            self.greetingStickerView.render(deltaTime: deltaTime)
        }
    }
}
