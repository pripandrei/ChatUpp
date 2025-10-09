//
//  GreetingView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/9/25.
//

import UIKit

final class GreetingView: UIView
{
//    private let greetingAnimationNames: [String] = ["hg_5","dd_5","duck_5", "lb_5", "mb_5"]
    private let greetingRLottieView: RLLottieView = .init(renderSize: .init(width: 250, height: 250))
    private var blurredView: UIVisualEffectView?
    
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
        setupGreetingRLottieAnimation()
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
        
        [titleLabel, subTitle, greetingRLottieView].forEach {
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
            greetingRLottieView.topAnchor.constraint(equalTo: subTitle.bottomAnchor, constant: spacing),
            greetingRLottieView.centerXAnchor.constraint(equalTo: centerXAnchor),
            greetingRLottieView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -paddingTop),
            
            // Maintain aspect ratio: width = height
            greetingRLottieView.widthAnchor.constraint(equalTo: greetingRLottieView.heightAnchor)
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
        print("yes")
        ChatManager.shared.newStickerSubject.send((animationName))
    }
    
    // MARK: - Lottie Setup
    private func setupGreetingRLottieAnimation()
    {
//        greetingRLottieView.loadAnimation(named: greetingAnimationNames.randomElement() ?? "hg_5")
        greetingRLottieView.loadAnimation(named: animationName)
        greetingRLottieView.setVisible(true)
        DisplayLinkManager.shered.addObject(greetingRLottieView)
    }

    private func cleanup()
    {
        DisplayLinkManager.shered.cleanup(greetingRLottieView)
        greetingRLottieView.setVisible(false)
        greetingRLottieView.destroyAnimation()
    }
    
    deinit
    {
        print("deinit GreetingView")
        cleanup()
    }
}
