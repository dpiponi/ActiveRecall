//
//  PDFBorder.swift
//  MasterDetail1
//
//  Created by Dan Piponi on 10/8/15.
//  Copyright © 2015 Dan Piponi. All rights reserved.
//

import Foundation
import UIKit

//func getNumPages(pdfFile: NSURL) -> Int {
//    let pdf : CGPDFDocument = CGPDFDocumentCreateWithURL(pdfFile)!
//    
//}

func makeThumbnail(pdfFile: NSURL) -> UIImage {
    let pdf : CGPDFDocument = CGPDFDocumentCreateWithURL(pdfFile)!
    let border : UIColor = PDFBorder(pdf, pageNumber: 1)
    
    let aRect : CGRect = CGRectMake(0, 0, 100, 70); // thumbnail size
    UIGraphicsBeginImageContext(aRect.size);    let context : CGContextRef = UIGraphicsGetCurrentContext()!
    var thumbnailImage : UIImage
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0.0, aRect.size.height)
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextSetGrayFillColor(context, 1.0, 1.0)
    CGContextSetFillColorWithColor(context, border.CGColor)
    CGContextFillRect(context, aRect);
    
    
    // Grab the first PDF page
    let page : CGPDFPage = CGPDFDocumentGetPage(pdf, 1)!
    let pdfTransform : CGAffineTransform = CGPDFPageGetDrawingTransform(page, .MediaBox, aRect, 0, true)
    // And apply the transform.
    CGContextConcatCTM(context, pdfTransform);
    
    CGContextDrawPDFPage(context, page);
    
    // Create the new UIImage from the context
    thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
    
    //Use thumbnailImage (e.g. drawing, saving it to a file, etc)
    
    CGContextRestoreGState(context);
    
    UIGraphicsEndImageContext();
    
    return thumbnailImage
}

// Pick colour for border around slide.
func PDFBorder(document: CGPDFDocument, pageNumber: Int) -> UIColor {
    let downScale : Int = 4
    let page = CGPDFDocumentGetPage(document, pageNumber)
    //        let t : CGPDFBox = .MediaBox
    let pageRect = CGPDFPageGetBoxRect(page, .MediaBox)
    print("pageNumber=", pageNumber)
    print("pageRect=",pageRect)
    let width = pageRect.size.width;
    let height = pageRect.size.height;
    let iwidth = Int(width)/downScale
    let iheight = Int(height)/downScale

    // Setup 1x1 pixel context to draw into
    let colorSpace : CGColorSpace = CGColorSpaceCreateDeviceRGB()!
    //        let rawData : [UInt8] = [UInt8](count: 4, repeatedValue: 0)
    let bytesPerPixel : Int = 4
    let bytesPerRow : Int = bytesPerPixel*iwidth
    let bitsPerComponent : Int = 8
    let bitmapData = malloc(Int(bytesPerPixel*iwidth*iheight))
    print("bitmapData =", bitmapData)
    print("size=", iwidth, iheight)
    //            let bitmapData = UnsafePointer<UInt8>.alloc(Int(4))
    // https://developer.apple.com/library/ios/documentation/GraphicsImaging/Reference/CGBitmapContext/#//apple_ref/swift/tdef/c:@T@CGBitmapContextReleaseDataCallback
    let maybeContext2 : CGContextRef? = CGBitmapContextCreateWithData(bitmapData,
        iwidth,
        iheight,
        bitsPerComponent,
        bytesPerRow,
        colorSpace,
        CGImageAlphaInfo.PremultipliedLast.rawValue | CGBitmapInfo.ByteOrder32Big.rawValue,
        {(releaseInfo, data) -> Void in free(data)},
        nil)
    let context2 = maybeContext2!
    CGContextSaveGState(context2);
    CGContextSetBlendMode(context2, .Copy);

    let xoffset : CGFloat = 0.0
    let yoffset : CGFloat = 0.0

    // Draw the image (fill irrelevant???)
    CGContextSetFillColorWithColor(context2, UIColor.whiteColor().CGColor)

    CGContextTranslateCTM(context2, 0.5*CGFloat(iwidth), 0.5*CGFloat(iheight))
    //            CGContextScaleCTM(context, scale, scale)
    CGContextScaleCTM(context2, 1.0/CGFloat(downScale), -1.0/CGFloat(downScale))
    print("width=",width)
    CGContextTranslateCTM(context2, -0.5*width-xoffset, -0.5*height+yoffset)

    let bdat = UnsafeMutablePointer<UInt8>(bitmapData)
    bdat[0] = 255
    bdat[1] = 255
    bdat[2] = 255
    bdat[3] = 255
    print("1.",bdat[0], bdat[1], bdat[2], bdat[3])

    CGContextDrawPDFPage(context2, page)
    var tr : CGFloat = 0.0
    var tg : CGFloat = 0.0
    var tb : CGFloat = 0.0
    var count : Int = 0
    for i in 0..<iwidth {
        let index : Int = 4*i
        let alpha : CGFloat = CGFloat(bdat[index+3])/255.0
        tr += alpha*CGFloat(bdat[index])/CGFloat(255)+(1-alpha)
        tg += alpha*CGFloat(bdat[index+1])/CGFloat(255)+(1-alpha)
        tb += alpha*CGFloat(bdat[index+2])/CGFloat(255)+(1-alpha)
        count += 1
    }
    for i in 0..<iwidth {
        let index : Int = (iheight-1)*bytesPerRow+4*i
        let alpha : CGFloat = CGFloat(bdat[index+3])/255.0
        tr += alpha*CGFloat(bdat[index])/CGFloat(255)+(1-alpha)
        tg += alpha*CGFloat(bdat[index+1])/CGFloat(255)+(1-alpha)
        tb += alpha*CGFloat(bdat[index+2])/CGFloat(255)+(1-alpha)
        count += 1
    }
    for i in 0..<iheight {
        let index : Int = i*bytesPerRow
        let alpha : CGFloat = CGFloat(bdat[index+3])/255.0
        tr += alpha*CGFloat(bdat[index])/CGFloat(255)+(1-alpha)
        tg += alpha*CGFloat(bdat[index+1])/CGFloat(255)+(1-alpha)
        tb += alpha*CGFloat(bdat[index+2])/CGFloat(255)+(1-alpha)
        count += 1
    }
    for i in 0..<iheight {
        let index : Int = (iwidth-1)*bytesPerPixel+i*bytesPerRow
        let alpha : CGFloat = CGFloat(bdat[index+3])/255.0
        tr += alpha*CGFloat(bdat[index])/CGFloat(255)+(1-alpha)
        tg += alpha*CGFloat(bdat[index+1])/CGFloat(255)+(1-alpha)
        tb += alpha*CGFloat(bdat[index+2])/CGFloat(255)+(1-alpha)
        count += 1
    }
    tr /= CGFloat(count)
    tg /= CGFloat(count)
    tb /= CGFloat(count)
    print("t", tr, tg, tb)
    for i in 0..<(iwidth*iheight*bytesPerPixel) {
        bdat[i] = 255
        if i & 3 == 3 {
            bdat[i] = 0
        }
    }
    print("2.",bdat[0], bdat[1], bdat[2], bdat[3])
    //        CGContextDrawImage(context,
    //            CGRectMake(-offsetx, offsety-height, width, height),
    //            image);

    // Done
    //        CGContextRelease(context);

    // Get the pixel information
    //        unsigned char red   = rawData[0]
    //        unsigned char green = rawData[1]
    //        unsigned char blue  = rawData[2]
    //        unsigned char alpha = rawData[3]
    print("3.",bdat[0], bdat[1], bdat[2], bdat[3])
    
    CGContextRestoreGState(context2);
//    CGContextRelease(context2)
    
    // http://stackoverflow.com/questions/9444295/ios-does-cgbitmapcontextcreate-copy-data
//    free(bitmapData)

//    self.backgroundColor = UIColor(red: CGFloat(bdat[0])/255.0, green: CGFloat(bdat[1])/255.0, blue: CGFloat(bdat[2])/255.0, alpha: CGFloat(1.0))
    return UIColor(red: tr, green: tg, blue: tb, alpha: CGFloat(1.0))
}
