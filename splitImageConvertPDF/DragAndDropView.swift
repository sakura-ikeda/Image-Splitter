//
//  MyNSView.swift
//  Image Splitter
//
//  Created by 池田 博史 on 2022/06/02.
//


import Cocoa

protocol DragAndDropViewDelegate {
    @discardableResult func setLoadFile(_ filePath:String)->Bool
    var contentTypeIdentifiers:NSArray { get }
}

class DragAndDropView: NSView {
    
    var delegate: DragAndDropViewDelegate?

    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        self.registerMyTypes()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.registerMyTypes()
    }

    final private func registerMyTypes()
    {
        registerForDraggedTypes(
            [NSPasteboard.PasteboardType.URL,
             NSPasteboard.PasteboardType.fileURL,
        ])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        //print("draggingEntered")
        
        var imageTypes:NSArray = []
        if let dg = self.delegate {
            imageTypes = dg.contentTypeIdentifiers
        }

        let pasteboard = sender.draggingPasteboard
        let filteringOptions = [NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes: imageTypes]
                if pasteboard.canReadObject(forClasses: [NSURL.self], options: filteringOptions) {
                        return NSDragOperation.copy
        }
        return NSDragOperation() //alternatively: []
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let allow = true // check your types...
        //print("prepareForDragOperation")
        return allow
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {

        let pasteBoard = sender.draggingPasteboard
        //print("performDragOperation")

        if let urls = pasteBoard.readObjects(forClasses: [NSURL.self]) as? [URL]{
            // consume them...
            if let dg = self.delegate {
                dg.setLoadFile(urls[0].path)
            }
            return true
        }
        return false
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
        /*
        NSColor.gray.set()
        let path = NSBezierPath(rect: dirtyRect)
        path.lineWidth = 4.0
        let pattern: [CGFloat] = [5.0, 4.0]
        path.setLineDash(pattern, count: pattern.count, phase: 0.0)
        path.stroke()
         */

        
    }
    
}
