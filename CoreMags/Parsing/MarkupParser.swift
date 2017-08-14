//
//  MarkupParser.swift
//  CoreMags
//
//  Created by Michael De La Cruz on 8/13/17.
//  Copyright © 2017 Michael De La Cruz. All rights reserved.
//

import UIKit
import CoreText

class MarkupParser: NSObject {
    
    // MARK: - Properties
    var color: UIColor = .black
    var fontName: String = "Arial"
    var attrString: NSMutableAttributedString!
    var images: [Dictionary<String,Any>] = []
    
    // MARK: - Initializers
    override init() {
        super.init()
    }
    
    // MARK: - Internal
    func parseMarkup(_ markup: String) {
        // starts as an empty string but will contain the parsed markup
        attrString = NSMutableAttributedString(string: "")
        // look through the string until you find an opening bracket, then look through the string until you hit a closing bracket
        do {
            let regax = try NSRegularExpression(pattern: "(.*?)(<[^>]+|\\Z)", options: [.caseInsensitive, .dotMatchesLineSeparators])
            // search the entire range of the markup for 'regax' matches, then produce an array of the resulting NSTextCheckingResultS
            let chunks = regax.matches(in: markup,
                                       options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                       range: NSRange(location: 0, length: markup.characters.count))
            
            let defaultFont: UIFont = .systemFont(ofSize: UIScreen.main.bounds.size.height / 40)
            
            for chunk in chunks {
                guard let markupRange = markup.range(from: chunk.range) else { continue }
                // Break chunks into parts by separated by "<". First part contains mags text and second part contains the tag
                let parts = markup.substring(with: markupRange).components(separatedBy: "<")
                // If fontName doesn't produce a valid UIFont, set font to the default font
                let font = UIFont(name: fontName, size: UIScreen.main.bounds.size.height / 40) ?? defaultFont
                // Create a dictionary of the font format, apply it to parts[0] to create the attr string, then append it to the result
                let attrs = [NSAttributedStringKey.foregroundColor: color,
                             NSAttributedStringKey.font: font] as [NSAttributedStringKey : Any]
                let text = NSMutableAttributedString(string: parts[0], attributes: attrs)
                attrString.append(text)
                
                // If less than two parts, skip the rest of the loop body. Otherwise, store that second part as 'tag'
                if parts.count <= 1 {
                    continue
                }
                let tag = parts[1]
                // If tag starts with 'font', create a regex to find the fonts 'color' value,
                // Then use regex to enumerate through 'tags' matching "color" values.
                if tag.hasPrefix("font") {
                    let colorRegex = try NSRegularExpression(pattern: "(?<=color=\")\\w+",
                                                             options: NSRegularExpression.Options(rawValue: 0))
                    colorRegex.enumerateMatches(in: tag,
                                                options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                                range: NSMakeRange(0, tag.characters.count)) { (match, _, _) in
                                                    // If enumerateMatches returns a valid match with a valid range in tag, find the indicated value and append
                                                    // "Color" to form a UIColor selector. Perform that selector then set your class's color to the returned color.
                                                    if let match = match,
                                                        let range = tag.range(from: match.range) {
                                                        let colorSel = NSSelectorFromString(tag.substring(with: range) + "Color")
                                                        color = UIColor.perform(colorSel).takeRetainedValue() as? UIColor ?? .black
                                                    }
                    }
                    // Create a regax to process the fon'ts 'face' value. If it finds a match, set fontName to that string.
                    let faceRegex = try NSRegularExpression(pattern: "(?<=face=\")[^\"]+",
                                                            options: NSRegularExpression.Options(rawValue: 0))
                    faceRegex.enumerateMatches(in: tag,
                                               options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                               range: NSMakeRange(0, tag.characters.count)) { (match, _, _) in
                                                
                                                if let match = match, let range = tag.range(from: match.range) {
                                                    fontName = tag.substring(with: range)
                                                }
                    }
                }
                // if 'tags' starts with "img", use a regex to search for the image's "src" value, i.e. the filename
                else if tag.hasPrefix("img") {
                    var filename: String = ""
                    let imageRegex = try NSRegularExpression(pattern: "(?<=src=\")[^\"]+",
                                                             options: NSRegularExpression.Options(rawValue: 0))
                    imageRegex.enumerateMatches(in: tag,
                    options: NSRegularExpression.MatchingOptions(rawValue: 0),
                    range: NSMakeRange(0, tag.characters.count)) { (match, _, _) in
                    if let match = match,
                        let range = tag.range(from: match.range) {
                            filename = tag.substring(with: range)
                        }
                    }
                    // Set image width to the width of the column and set its height so the image maintains its height-width aspect ratio
                    let settings = MagsSettings()
                    var width: CGFloat = settings.columnRect.width
                    var height: CGFloat = 0
                    
                    if let image = UIImage(named: filename) {
                        height = width * (image.size.height / image.size.width)
                        //if height of image is long for the column, set the height to fit the column and reduce the width to maintain
                        // image. text containing the empty space info must fit within the same column as the image, so image height
                        if height > settings.columnRect.height - font.lineHeight {
                            height = settings.columnRect.height - font.lineHeight
                            width = height * (image.size.width / image.size.height)
                        }
                    }
                    // Append an Dictionary containing the image's size, filename and text location to images
                    images += [["width": NSNumber(value: Float(width)),
                                "height": NSNumber(value: Float(height)),
                                "filename": filename,
                                "location": NSNumber(value: attrString.length)]]
                    // hold properties that will delineate the empty spaces. Then init a pointer to contain a RunStruct with an 'ascent'
                    // equal to the image height and a width property equal to the image width
                    struct RunStruct {
                        let ascent: CGFloat
                        let descent: CGFloat
                        let width: CGFloat
                    }
                    
                    let extentBuffer = UnsafeMutablePointer<RunStruct>.allocate(capacity: 1)
                    extentBuffer.initialize(to: RunStruct(ascent: height, descent: 0, width: width))
                    // Create CTRunDelegateCalbacks that returns ascent,descent, and width properties belonging to pointers of RunStruct
                    var callbacks = CTRunDelegateCallbacks(version: kCTRunDelegateVersion1, dealloc: { (pointer) in
                    }, getAscent: { (pointer) -> CGFloat in
                        let d = pointer.assumingMemoryBound(to: RunStruct.self)
                        return d.pointee.ascent
                    }, getDescent: { (pointer) -> CGFloat in
                        let d = pointer.assumingMemoryBound(to: RunStruct.self)
                        return d.pointee.descent
                    }, getWidth: { (pointer) -> CGFloat in
                        let d = pointer.assumingMemoryBound(to: RunStruct.self)
                        return d.pointee.width
                    })
                    // Create a delegate instance binding the callbacks and the data parameter together
                    let delegate = CTRunDelegateCreate(&callbacks, extentBuffer)
                    // Create an attributed dictionary containing the delegate instance, then append a single space to attrString which
                    // holds the position and sizing information for the hole in the text
                    let attrDictionaryDelegate = [(kCTRunDelegateAttributeName as NSAttributedStringKey): (delegate as Any)]
                    attrString.append(NSAttributedString(string: " ", attributes: attrDictionaryDelegate))
                }
            }
        } catch _ {
        }
    }
}

extension String {
    func range(from range: NSRange) -> Range<String.Index>? {
        guard let from16 = utf16.index(utf16.startIndex, offsetBy: range.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: range.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) else {
                return nil
        }
        return from ..< to
    }
}
