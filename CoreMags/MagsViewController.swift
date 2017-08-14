//
//  ViewController.swift
//  CoreMags
//
//  Created by Michael De La Cruz on 8/13/17.
//  Copyright © 2017 Michael De La Cruz. All rights reserved.
//

import UIKit

class MagsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the text from the zombie.txt file into a String
        guard let file = Bundle.main.path(forResource: "zombies", ofType: "txt") else { return }
        
        do {
            let text = try String(contentsOfFile: file, encoding: .utf8)
            // Create a new parser, feed in the text, then pase the returned attributed string to MagsViewController's MagsView
            let parser = MarkupParser()
            parser.parseMarkup(text)
            (view as? MagsView)?.buildFrames(withAttrString: parser.attrString, andImages: parser.images)
        } catch _ {
        }
    }
}

