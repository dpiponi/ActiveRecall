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
        print("Hello", bounds)
        setNeedsDisplay()
    }
    
    var pageNumber:Int = 0 {
        didSet {
        
            let document = CGPDFDocumentCreateWithURL(url)
            
            self.backColor = (self.backgroundColor?.CGColor)!
//            self.backColor = UIColor.whiteColor().CGColor
//            self.backgroundColor = UIColor.whiteColor()
            self.backgroundColor = PDFBorder(document!, pageNumber: pageNumber)
            setNeedsDisplay()
        }
    }
    
    func setPDF(pdfUrl: NSURL) {
        url = pdfUrl
    }
    
    required init?(coder aDecoder: NSCoder) {
        print("CONSTRUCTING PDFVIEW!!!")
        super.init(coder:aDecoder)
        self.backgroundColor = UIColor.clearColor()
        self.backColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).CGColor
    }
    
    override func drawRect(rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()
        //        CGContextScaleCTM(context, 0.6, 0.6)
        
        //        CGContextMoveToPoint(context, 0, 0)
        //        CGContextAddLineToPoint(context, self.bounds.size.width, 0)
        //        CGContextStrokePath(context)
        let document = CGPDFDocumentCreateWithURL(url)
        print("document=",document,"pageNum=",pageNumber,"out ot", CGPDFDocumentGetNumberOfPages(document))
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
        
        
///////////////////
        
//        CGImageRef image = uiimage.CGImage;
        
        ///////////////////
        
        
//        let retval : UIImage? = UIGraphicsGetImageFromCurrentImageContext()
//        print("retval=",retval)
        
    }
}
