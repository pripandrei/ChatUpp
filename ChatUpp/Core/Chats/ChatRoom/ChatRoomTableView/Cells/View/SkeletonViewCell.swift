//
//  SkeletonViewCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/7/25.
//

import UIKit
import SkeletonView

//MARK: - Skeleton cell
class SkeletonViewCell: UITableViewCell
{
    let customSkeletonView: UIView = {
        let skeletonView = UIView()
        skeletonView.translatesAutoresizingMaskIntoConstraints = false
        skeletonView.isSkeletonable = true
        skeletonView.skeletonCornerRadius = 15
        return skeletonView
    }()
    
    private var barWidthConstraint: NSLayoutConstraint?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        setupCustomSkeletonView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCustomSkeletonView()
    {
        self.isSkeletonable = true
        contentView.isSkeletonable = true
        contentView.addSubview(customSkeletonView)
        
        let widthConstraint = customSkeletonView.widthAnchor.constraint(equalToConstant: CGFloat((120...270).randomElement()!))
        
        NSLayoutConstraint.activate([
            customSkeletonView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            widthConstraint,
            customSkeletonView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            customSkeletonView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
        ])
        self.barWidthConstraint = widthConstraint
    }
    
    /// Sizes the skeleton bar from the row index instead of the cell instance.
    ///
    /// A reload under the skeleton (SkeletonView swizzles `traitCollectionDidChange`
    /// and any trait pass triggers `updateSkeleton` → `reloadData`) re-dequeues
    /// reuse-pool cells into different row positions, so a width drawn once per
    /// cell instance visibly re-shuffles the bar sizes on every reload. A
    /// deterministic pseudo-random value per row - shifted by a per-open seed
    /// so each chat still gets a fresh arrangement - keeps the skeleton static
    /// no matter how many times the table reloads.
    func setSkeletonBarWidth(forRow row: Int, seed: Int)
    {
        let spread = 270 - 120 + 1
        let hash = (row + seed) * 48_271 % spread
        let width = CGFloat(120 + hash)
        
        /// the recycled cell may carry another row's width; a constraint change
        /// during a reload can be enrolled in Core Animation's current
        /// transaction (skeleton transitions / system animations), which makes
        /// the bar visibly glide between sizes instead of swapping instantly
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if let barWidthConstraint
        {
            barWidthConstraint.constant = width
        }
        else
        {
            let widthConstraint = customSkeletonView.widthAnchor.constraint(equalToConstant: width)
            widthConstraint.isActive = true
            self.barWidthConstraint = widthConstraint
        }
        CATransaction.commit()
    }
    
    /// The skeleton gradient lives on the plain bar view (not via SkeletonView's
    /// table data-source wrapper, which is what made reloads re-shuffle cells),
    /// so each dequeue just makes sure the bar is showing it.
    func showBarSkeleton()
    {
        SkeletonAnimationAppearance.initiateSkeletonAnimation(for: customSkeletonView)
    }
    
    /// Removes the gradient when the cell leaves the display queue
    /// (e.g. parked in the reuse pool after the skeleton ends).
    func hideBarSkeleton()
    {
        SkeletonAnimationAppearance.stopSkeletonAnimation(for: customSkeletonView)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        hideBarSkeleton()
    }
}
