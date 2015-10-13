//
//  MyHorizLine.swift
//  EmptyWindow
//
//  Created by Dan Piponi on 9/30/15.
//  Copyright (c) 2015 Dan Piponi. All rights reserved.
//

import UIKit
import CoreGraphics

class PDFView : UIView {
    
    var url : NSURL! = nil
    var backColor : CGColor!
    var zoomed : Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    override func layoutSubviews() {
        setNeedsDisplay()
    }
    
    var pageNumber:Int = 0 {
        didSet {        
            let document = CGPDFDocumentCreateWithURL(url)
            
            self.backColor = (self.backgroundColor?.CGColor)!
            self.backgroundColor = PDFBorder(document!, pageNumber: pageNumber)
            setNeedsDisplay()
        }
    }
    
    func setPDF(pdfUrl: NSURL) {
        url = pdfUrl
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        self.backgroundColor = UIColor.clearColor()
        self.backColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).CGColor
    }
    
    override func drawRect(rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()
        let document = CGPDFDocumentCreateWithURL(url)
        let page = CGPDFDocumentGetPage(document, pageNumber)
        let pageRect = CGPDFPageGetBoxRect(page, .MediaBox)
        let scalew = frame.size.width/pageRect.size.width
        let scaleh = frame.size.height/pageRect.size.height
        let scale = zoomed ? max(scalew, scaleh) : min(scalew, scaleh)
        
        CGContextSetFillColorWithColor(context, UIColor.clearColor().CGColor)
        CGContextFillRect(context,pageRect)
        
        CGContextTranslateCTM(context, frame.size.width/2, frame.size.height/2)
        CGContextScaleCTM(context, scale, scale)
        CGContextScaleCTM(context, 1.0, -1.0)
        CGContextTranslateCTM(context, -pageRect.size.width/2, -pageRect.size.height/2)
        CGContextDrawPDFPage(context, page)
        
    }
}
