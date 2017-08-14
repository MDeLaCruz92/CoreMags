//
//  MagsView.swift
//  CoreMags
//
//  Created by Michael De La Cruz on 8/13/17.
//  Copyright © 2017 Michael De La Cruz. All rights reserved.
//

import UIKit
import CoreText

class MagsView: UIScrollView {
    
    // MARK: - Properties
    var imageIndex: Int!
    
    // create MagsColumns then add them to the scrollview.
    func buildFrames(withAttrString attrString: NSAttributedString, andImages images: [Dictionary<String,Any>])
    {
        imageIndex = 0
        
        // Enabled the scrollview's paging behavior; so, whenever the user stops scrolling, the scrollview snaps into place
        // so exactly one entire page is showing at a time.
        isPagingEnabled = true
        // CTFramesetter framesetter will create each column's CTFrame of attributed text.
        let framesetter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)
        var pageView = UIView()
        var textPos = 0
        var columnIndex: CGFloat = 0
        var pageIndex: CGFloat = 0
        let settings = MagsSettings()
        // loop through attrstring and layout the text column by column, until the current text position reaches the end
        while textPos < attrString.length {
            if columnIndex.truncatingRemainder(dividingBy: settings.columnsPerPage) == 0 {
                columnIndex = 0
                pageView = UIView(frame: settings.pageRect.offsetBy(dx: pageIndex * bounds.width, dy: 0))
                addSubview(pageView)
                
                pageIndex += 1
            }
            let columnXOrigin = pageView.frame.size.width / settings.columnsPerPage
            let columnOffset = columnIndex * columnXOrigin
            let columnFrame = settings.columnRect.offsetBy(dx: columnOffset, dy: 0)
            
            // Create CGMutablePath the size of the column, then starting from textPos, render a new MagsFrame with as much text as can
            let path = CGMutablePath()
            path.addRect(CGRect(origin: .zero, size: columnFrame.size))
            let magsframe = CTFramesetterCreateFrame(framesetter, CFRangeMake(textPos, 0), path, nil)
            //Create a MagsColumnView with a CGRect columnFare and MagsFrame magsFrame then add the column to 'pageView'
            let column = MagsColumnView(frame: columnFrame, magsframe: magsframe)
            
            if images.count > imageIndex {
                attachImagesWithFrame(images, magsframe: magsframe, margin: settings.margin, columnView: column)
            }
            pageView.addSubview(column)
            // calculate the range of text contained within the column, then increment 'textPos' by that range length to reflect
            // the current text position
            let frameRange = CTFrameGetVisibleStringRange(magsframe)
            textPos += frameRange.length
            
            columnIndex += 1
            
            contentSize = CGSize(width: CGFloat(pageIndex) * bounds.size.width, height: bounds.size.height)
        }
    }
    
    func attachImagesWithFrame(_ images: [Dictionary<String,Any>], magsframe: CTFrame, margin: CGFloat, columnView: MagsColumnView)
    {
        // Get an array of magsframe's CTLine objects
        let lines = CTFrameGetLines(magsframe) as NSArray
        // copy magsframe line origins into the origins array. By setting a range with 0, CTFrameGetOrigins know to traveerse the CTFrame
        var origins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(magsframe, CFRangeMake(0, 0), &origins)
        // contain the attr data of the current img. If nextImage contain's the image's location, use guard on it
        var nextImage = images[imageIndex]
        guard var imgLocation = nextImage["location"] as? Int else { return }
        // Loop through the text's lines
        for lineIndex in 0..<lines.count {
            let line = lines[lineIndex] as! CTLine
            // If the line's glyph runs, filename and images with filename all exist, loop through the glyphs runs of that line.
            if let glyphRuns = CTLineGetGlyphRuns(line) as? [CTRun],
            let imageFilename = nextImage["filename"] as? String,
                let img = UIImage(named: imageFilename) {
                for run in glyphRuns {
                   // if range of the present run does not contain the next image, skip the rest of the loop. Otherwise, render image
                    let runRange = CTRunGetStringRange(run)
                    if runRange.location > imgLocation || runRange.location + runRange.length <= imgLocation {
                        continue
                    }
                    // Calculate the image width using CTRunGetTypo and set the height to the found ascent
                    var imgBounds: CGRect = .zero
                    var ascent: CGFloat = 0
                    imgBounds.size.width = CGFloat(CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, nil, nil))
                    imgBounds.size.height = ascent
                    // Get the line's x offset with CTLineGetOffsetForStringIndex then add it to the imgBounds origin
                    let xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, nil)
                    imgBounds.origin.x = origins[lineIndex].x + xOffset
                    imgBounds.origin.y = origins[lineIndex].y
                    // Add the image and its frame to the current MagsColumnView
                    columnView.images += [(image: img, frame: imgBounds)]
                    // increment the imaage index. If there's an image at images[imageIndex], update the nextImage and imgLocation
                    // so they refer to that next image
                    imageIndex! += 1
                    if imageIndex < images.count {
                        nextImage = images[imageIndex]
                        imgLocation = (nextImage["location"] as AnyObject).intValue
                    }
                }
            }
        }
    }
   
}
