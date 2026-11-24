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
        /// only the bar itself renders the skeleton gradient; the cell and its
        /// content view stay plain (the SkeletonView data-source wrapper that
        /// used to skeletonize the whole cell tree is no longer involved)
        contentView.addSubview(customSkeletonView)
        
        /// temporary width; `setSkeletonBarWidth` always stamps the row's
        /// deterministic value when the cell is dequeued, before it is shown
        let widthConstraint = customSkeletonView.widthAnchor.constraint(equalToConstant: 150)
        
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
    /// Being diffable rows, the skeleton rows survive reloads, but the reuse
    /// pool may hand a cell back for a different row position; a width drawn
    /// once per cell instance would then re-appear at the wrong row. A
    /// deterministic pseudo-random value per row - shifted by a per-open seed
    /// so each chat still gets a fresh arrangement - keeps the bar in sync
    /// with whichever row the cell currently renders.
    func setSkeletonBarWidth(forRow row: Int, seed: Int)
    {
        let spread = 270 - 120 + 1
        let hash = (row + seed) * 48_271 % spread
        let width = CGFloat(120 + hash)
        
        /// a constraint change during a reload can be enrolled in Core
        /// Animation's current transaction (skeleton transitions / system
        /// animations), which makes the bar visibly glide between sizes
        /// instead of swapping instantly
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        barWidthConstraint?.constant = width
        CATransaction.commit()
    }
    
    /// The skeleton gradient lives on the plain bar view; each dequeue makes
    /// sure the bar is showing it (`showSkeleton` is a no-op if already active).
    func showBarSkeleton()
    {
        SkeletonAnimationAppearance.initiateSkeletonAnimation(for: customSkeletonView)
    }
}
