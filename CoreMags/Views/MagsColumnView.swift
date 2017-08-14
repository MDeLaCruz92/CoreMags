//
//  MagsColumnView.swift
//  CoreMags
//
//  Created by Michael De La Cruz on 8/13/17.
//  Copyright © 2017 Michael De La Cruz. All rights reserved.
//

import UIKit
import CoreText

class MagsColumnView: UIView {
    
    // MARK: - Properties
    var magsFrame: CTFrame!
    var images: [(image: UIImage, frame: CGRect)] = []
    
    // MARK: - Initializers
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required init(frame: CGRect, magsframe: CTFrame) {
        super.init(frame: frame)
        self.magsFrame = magsframe
        backgroundColor = .white
    }
    
    // MARK: - Life Cycles
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.textMatrix = .identity
        context.translateBy(x: 0, y: bounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        CTFrameDraw(magsFrame, context)
        
        for imageData in images {
            if let image = imageData.image.cgImage {
                let imgBounds = imageData.frame
                context.draw(image, in: imgBounds)
            }
        }
    }

}
