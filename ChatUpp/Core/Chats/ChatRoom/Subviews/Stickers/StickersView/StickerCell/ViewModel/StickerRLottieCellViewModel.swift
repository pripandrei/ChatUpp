//
//  StickerRlottieCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/22/25.
//

import librlottie

final class StickerRLottieCellViewModel
{
    let stickerName: String
    var stickerAnimation: OpaquePointer?
    
    init(stickerName: String) {
        self.stickerName = stickerName
    }
    
    func destroyAnimation()
    {
        lottie_animation_render_flush(stickerAnimation)
        lottie_animation_destroy(stickerAnimation)
        stickerAnimation = nil
    }
    
    deinit {
        print("LottieCellViewModel DEINIT")
    }
}
