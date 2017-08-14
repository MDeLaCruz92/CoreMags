//
//  MagsSettings.swift
//  CoreMags
//
//  Created by Michael De La Cruz on 8/13/17.
//  Copyright © 2017 Michael De La Cruz. All rights reserved.
//

import UIKit

class MagsSettings {
    // MARK: - Properties
    let margin: CGFloat = 20 // choosing for the default page to be 20
    var columnsPerPage: CGFloat!
    var pageRect: CGRect!
    var columnRect: CGRect!
    
    // MARK: - Initializers
    init() {
        // show two columns on iPad and one on iPhone so the numbers of columns is appropriate for each screen size
        columnsPerPage = UIDevice.current.userInterfaceIdiom == .phone ? 1 : 2
        // Inset the entire bounds of the page by the size of the margin to calculate 'pageRect'
        pageRect = UIScreen.main.bounds.insetBy(dx: margin, dy: margin)
        // Divide pageRect's width by the number of columns per page and inset that new frame with the margin for columnRect
        columnRect = CGRect(x: 0, y: 0, width: pageRect.width / columnsPerPage, height: pageRect.height).insetBy(dx: margin, dy: margin)
    }
}
