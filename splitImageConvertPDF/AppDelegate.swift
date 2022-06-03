//
//  AppDelegate.swift
//  splitImageConvertPDF
//
//  Created by 池田 博史 on 2022/05/31.
//

import Cocoa
import PDFKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet var window: NSWindow!
    @IBOutlet weak var fileName: NSTextField!
    @IBOutlet weak var colNumber: NSPopUpButton!
    @IBOutlet weak var widthNumber: NSTextField!
    @IBOutlet weak var spaceNumber: NSTextField!
    @IBOutlet weak var backgroundColor: NSColorWell!
    @IBOutlet weak var fileChooseButton: NSButton!
    @IBOutlet weak var clearFileNameButton: NSButton!
    @IBOutlet weak var procButton: NSButton!
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var dragAndDropView: DragAndDropView!
    @IBOutlet weak var lapNumber: NSTextField!
    
    
    //
    //var this_file = ""
    let inchi2mm:CGFloat = 0.03937007874016
    let mm2point:CGFloat = 2.8346456692913
    let topMargin:CGFloat = 10
    let bottomMargin:CGFloat = 10
    var lap:CGFloat = 20

    var loadFile:URL?
    var dpmm:CGFloat?
    var heighPixcel,dpi,W,H:Int?
    var widthNum:CGFloat?
    var images = [CGImage]()
    var targetImageRange = 0...0
    var paperHeight:CGFloat = 0.0
    var paperWidth:CGFloat = 0.0
    var contentTypeIdentifiers:NSArray = []

    func application(sender: NSApplication, openFile filename: String) -> Bool {
        setLoadFile(filename)
        return true
    }
    
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        setLoadFile(filenames[0])
    }

    @discardableResult func setLoadFile(_ filePath:String)->Bool {
        loadFile = URL(fileURLWithPath: filePath)
        if let myURL = loadFile {
            fileName.stringValue = myURL.lastPathComponent
            fileChooseButton.isHidden = true
            clearFileNameButton.isHidden = false
            procButton.isEnabled = true
            return true
        }
        fileChooseButton.isHidden = false
        clearFileNameButton.isHidden = true
        procButton.isEnabled = false
        return false
    }
    
    func applicationShouldTerminateAfterLastWindowClosed (_ theApplication: NSApplication) -> Bool {
        return true
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        paperWidth = 210.0
        paperHeight = 297.0
        initPopButton()
        colNumber.setTitle("2")
        widthNumber.stringValue = "75"
        lapNumber.stringValue = "20"
        witdhField(widthNumber)
        fileName.stringValue = ""
        backgroundColor.color = NSColor(deviceCyan: 0.0, magenta: 0.0, yellow: 0.0, black: 0.2, alpha: 1.0)
        clearFileNameButton.isHidden = true
        procButton.isEnabled = false
        progress.isHidden = true
        
        if let documentTypes = ((Bundle.main.object(forInfoDictionaryKey: "CFBundleDocumentTypes") as! NSArray)[0] as! NSDictionary)["LSItemContentTypes"] as? NSArray {
            contentTypeIdentifiers = documentTypes
        }
        
        dragAndDropView.delegate = self

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    @IBAction func clearFileName(_ sender: Any) {
        fileName.stringValue = ""
        loadFile = URL(string: "")
        fileChooseButton.isHidden = false
        clearFileNameButton.isHidden = true
        procButton.isEnabled = false
    }
    
    @IBAction func chooseFile(_ sender: Any) {
        //NSLog("chooseFile work")
        if openFile() {
            if let myURL = loadFile {
                fileName.stringValue = myURL.lastPathComponent
            }
        }
    }
    
    @IBAction func proc(_ sender: Any) {
        
        let queue = DispatchQueue(label: "jp.co.sakura-pr.imagesplitter.upload_queue",
                                  qos: .default,
                                  attributes: [])


        if let myURL = loadFile {
            queue.async {
                
                DispatchQueue.main.async { () -> Void in
                    self.procButton.isEnabled = false
                    self.progress.isHidden = false
                    self.progress.startAnimation(self)
                }
                
                self.readImage(image_url:myURL)
                self.createPDF(image_url:myURL)

                DispatchQueue.main.async { () -> Void in
                    self.procButton.isEnabled = true
                    self.progress.isHidden = true
                }
            }
        }
 
    }
    
    @IBAction func witdhField(_ sender: NSTextField) {
        if let w = NumberFormatter().number(from: sender.stringValue),
           let col = NumberFormatter().number(from: colNumber.title)
        {
            let w = CGFloat(truncating: w)
            let col = CGFloat(truncating: col)
            let s = (paperWidth - (w * col)) / (col+1)
            spaceNumber.stringValue = "\(s)"
        }
    }
    
    @IBAction func spaceFiled(_ sender: NSTextField) {
        if let s = NumberFormatter().number(from: sender.stringValue),
           let col = NumberFormatter().number(from: colNumber.title)
        {
            let s = CGFloat(truncating: s)
            let col = CGFloat(truncating: col)
            let w = (paperWidth - ((col+1)*s)) / col
            widthNumber.stringValue = "\(w)"
        }
    }
    
    @IBAction func colField(_ sender: NSPopUpButton) {
        witdhField(widthNumber)
        if let s = NumberFormatter().number(from: spaceNumber.stringValue),
           let col = NumberFormatter().number(from: sender.title)
        {
            let s = CGFloat(truncating: s)
            if s < 0 {
                switch col {
                case 1:
                    widthNumber.stringValue = "120"
                case 2:
                    widthNumber.stringValue = "75"
                case 3:
                    widthNumber.stringValue = "35"
                default:
                    widthNumber.stringValue = "35"
                }
            }
            witdhField(widthNumber)
        }
    }
    
    @discardableResult func readImage(image_url:URL)->NSImage! {
        
        let image = NSImage(contentsOf: image_url)
        
        if let image = image {
            
            var cgimages = [CGImage]()
            var imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            let srcImageRef = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
            
            self.W = Int(image.size.width)
            self.H = Int(image.size.height)
            
            var lapNumberString:String = "", widthNumberString:String = ""
            DispatchQueue.main.sync {
                lapNumberString = lapNumber.stringValue
                widthNumberString = widthNumber.stringValue
            }
            
            if let n = NumberFormatter().number(from: widthNumberString),
               let l = NumberFormatter().number(from: lapNumberString)
            {
                
                self.widthNum = CGFloat(truncating: n)
                self.lap = CGFloat(truncating: l)
                self.dpmm = image.size.width/self.widthNum!
                
                self.heighPixcel = Int(round((paperHeight - topMargin - bottomMargin) * self.dpmm!))
                self.dpi = Int(self.dpmm!/self.inchi2mm)

                let hp = self.heighPixcel! - Int(lap*self.dpmm!)
                
                for offsetY in stride(from: 0, to: self.H!, by: hp) {
                //for offsetY in stride(from: 0, to: self.H!, by: self.heighPixcel!) {

                    var heightValue:Int
                    if offsetY+self.heighPixcel! > self.H! {
                         heightValue = self.H! - offsetY
                    } else {
                         heightValue = self.heighPixcel!
                    }
                    let trimArea = CGRect(x: 0, y: offsetY, width: self.W!, height: heightValue)
                    if let crop = srcImageRef!.cropping(to: trimArea) {
                        cgimages.append(crop)
                    }
                }
            }
            self.images = cgimages
        }
        return image
    }
    
    @discardableResult func writeCGImage(_ image: CGImage, to destinationURL: URL) -> Bool {
        guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, kUTTypeJPEG, 1, nil) else { return false }
        CGImageDestinationAddImage(destination, image, nil)
        return CGImageDestinationFinalize(destination)
    }

    func initPopButton() {
        colNumber.removeAllItems()
        for i in 1...4 {
            colNumber.addItem(withTitle: String(i))
        }
    }
    
    func openFile()->Bool {

        let openPanel = NSOpenPanel()
        openPanel.title = "画像を選択"
        openPanel.allowedFileTypes = ["jpg", "jpeg", "JPG", "JPEG", "png", "PNG", "tiff", "TIFF", "tif", "TIF", "PSD", "psd"]
        openPanel.beginSheetModal(for: window, completionHandler: { num in
            if num == NSApplication.ModalResponse.OK {
                if let myURL = openPanel.url {
                    self.setLoadFile(myURL.path)
                }
            }
        })
        return true
    }

        /*
        if openPanel.runModal() == NSApplication.ModalResponse.OK {
            if let myURL = openPanel.url {
                setLoadFile(myURL.path)
            } else {
                return false
            }
            return true
        } else {
            return false
        }
         }
         */
    
 
    @discardableResult func createPDF(image_url:URL)->PDFDocument! {

        let baseURL = image_url.deletingLastPathComponent()
        let baseFileName = image_url.lastPathComponent.deletingPathExtension
        //let pageCount = Int(ceil(Float(images.count)/Float(colNumber.title)!))
        let saveURL = baseURL.appendingPathComponent(baseFileName).appendingPathExtension("pdf")
        let pdfDocument = PDFDocument()

        //print([images.count,colNumber.title,pageCount])
        
        var col:String = ""
        DispatchQueue.main.sync {
            col = colNumber.title
        }

        if let col = Int(col) {
            let imagecount = images.count - 1
            var pdfPageCount:Int = 0;
            for startRangeIndex in stride(from: 0, to: images.count, by: col) {
                let endRangeIndex = startRangeIndex+(col-1) > imagecount ? imagecount : startRangeIndex+(col-1)
                self.targetImageRange = startRangeIndex...endRangeIndex
                
                DispatchQueue.main.sync {
                    let pdfview = PDFCreator(frame: NSMakeRect(0, 0, 210*mm2point, 297*mm2point), classObject: self)
                    let pdfData = pdfview.dataWithPDF(inside: NSMakeRect(0, 0, 210*mm2point, 297*mm2point))
                    if let pdf = PDFDocument(data: pdfData) {
                        if let page = pdf.page(at: 0) {
                            pdfDocument.insert(page, at: pdfPageCount)
                        }
                    }
                }
                
                pdfPageCount+=1
            }
            pdfDocument.write(to: saveURL)
            return pdfDocument
        }
        return pdfDocument
    }
}


extension AppDelegate: DragAndDropViewDelegate {
    func moge() {
      print("moge")
    }
}
