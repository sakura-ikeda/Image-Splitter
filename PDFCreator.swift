//
//  PDFCreator.swift
//  splitImageConvertPDF
//
//  Created by 池田 博史 on 2022/06/01.
//

import Cocoa


class PDFCreator: NSView {

    var myClass:AppDelegate?

    override init(frame frameRect: NSRect) {
        super.init(frame:frameRect);
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)!
    }
    
    init(frame frameRect: NSRect, classObject:AppDelegate) {
        super.init(frame:frameRect)
        // other code
        myClass = classObject
    }


    override func draw(_ dirtyRect: NSRect) {
        
        super.draw(dirtyRect)
        
        if let classObj = myClass {
            
            let backgroundColor = classObj.backgroundColor.color
            backgroundColor.setFill()
            dirtyRect.fill()
            
            let numberFormatter = NumberFormatter().number(from: classObj.colNumber.title) ?? 0.0
            let colNumber = CGFloat(truncating: numberFormatter)
            
            let topMargin = classObj.topMargin * classObj.mm2point
            let btmMargin = classObj.bottomMargin * classObj.mm2point
            let widthNum = classObj.widthNum! * classObj.mm2point
            let paperHeight = classObj.paperHeight * classObj.mm2point
            let paperWidth = classObj.paperWidth * classObj.mm2point
            let spaceSize = (paperWidth - (widthNum * colNumber)) / (colNumber+1) //空きスペース

            var count = 0.0
            for imageIndex in classObj.targetImageRange {
                /*
                print(["topMargin":topMargin,
                       "btmMargin":btmMargin,
                       "widthNum":widthNum,
                       "paperHeight":paperHeight,
                       "paperWidth":paperWidth,
                       "spaceSize":spaceSize,
                       "count":count,
                      ])
                */
                let cgImage = classObj.images[imageIndex]
                
                var heightNum = paperHeight - topMargin - btmMargin
                var yMargin = btmMargin
                if classObj.heighPixcel != cgImage.height {
                    if let heighPixcel = classObj.heighPixcel {
                        let tmpvalue = heightNum
                        heightNum = heightNum * (CGFloat(cgImage.height) / CGFloat(heighPixcel))
                        yMargin = btmMargin + (tmpvalue - heightNum)
                    }
                }
                
                let imageRect = NSRect(x: spaceSize+((spaceSize + widthNum)*count),
                                       y: yMargin,
                                       width: widthNum,
                                       height: heightNum)

                guard let context = NSGraphicsContext.current else {
                    return
                }
                
                context.cgContext.draw(cgImage, in: imageRect)
                count+=1.0
            }
        }
    }
}
