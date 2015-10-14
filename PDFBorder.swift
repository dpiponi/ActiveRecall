//
//  PDFBorder.swift
//  MasterDetail1
//
//  Created by Dan Piponi on 10/8/15.
//  Copyright © 2015 Dan Piponi. All rights reserved.
//

import Foundation
import UIKit

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

func foldBorder<X>(bdat: UnsafeMutablePointer<UInt8>,
    iwidth: Int, iheight: Int,
    bytesPerPixel: Int,
    bytesPerRow: Int,
    x0: X,
    f : (UnsafeMutablePointer<UInt8>, X) -> X) -> X {
        var x : X = x0
        for i in 0..<iwidth {
            x = f(bdat+4*i, x)
            x = f(bdat+(iheight-1)*bytesPerRow+4*i, x)
        }
        for i in 0..<iheight {
            x = f(bdat+i*bytesPerRow, x)
            x = f(bdat+(iwidth-1)*bytesPerPixel+i*bytesPerRow, x)
        }
        return x
}

protocol Num {
    init(_ v: Int)
    func +(lhs: Self, rhs: Self) -> Self
    func -(lhs: Self, rhs: Self) -> Self
    func *(lhs: Self, rhs: Self) -> Self
}

//
// http://stackoverflow.com/questions/24073135/generic-type-constraint-for-numerical-type-only
//
extension CGFloat : Num { }

func linstep<X:Num>(lambda: X, a: X, b: X) -> X {
    return (X(1)-lambda)*a+lambda*b
}

// Pick colour for border around slide.
func PDFBorder(document: CGPDFDocument, pageNumber: Int) -> UIColor {
    let page = CGPDFDocumentGetPage(document, pageNumber)
    let pageRect = CGPDFPageGetBoxRect(page, .MediaBox)
    let width = pageRect.size.width;
    let height = pageRect.size.height;
    
    let downScale : CGFloat = max(width, height)/128.0
    let iwidth = Int(width/downScale)
    let iheight = Int(height/downScale)
    
    // Setup 1x1 pixel context to draw into
    let colorSpace : CGColorSpace = CGColorSpaceCreateDeviceRGB()!
    //        let rawData : [UInt8] = [UInt8](count: 4, repeatedValue: 0)
    let bytesPerPixel : Int = 4
    let bytesPerRow : Int = bytesPerPixel*iwidth
    let bitsPerComponent : Int = 8
    
    //
    // Use http://swiftdoc.org/v2.0/type/UnsafeMutablePointer/
    //
    let bitmapData = malloc(Int(bytesPerPixel*iwidth*iheight))
    
    //
    // https://developer.apple.com/library/ios/documentation/GraphicsImaging/Reference/CGBitmapContext/#//apple_ref/swift/tdef/c:@T@CGBitmapContextReleaseDataCallback
    //
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
    
    CGContextSetFillColorWithColor(context2, UIColor.whiteColor().CGColor)
    CGContextTranslateCTM(context2, 0.5*CGFloat(iwidth), 0.5*CGFloat(iheight))
    CGContextScaleCTM(context2, 1.0/CGFloat(downScale), -1.0/CGFloat(downScale))
    CGContextTranslateCTM(context2, -0.5*width-xoffset, -0.5*height+yoffset)
    
    let bdat = UnsafeMutablePointer<UInt8>(bitmapData)
    for i in 0..<4 {
        bdat[i] = 255
    }
    
    CGContextDrawPDFPage(context2, page)
    let borderColour = foldBorder(bdat,
        iwidth: iwidth, iheight: iheight,
        bytesPerPixel: bytesPerPixel, bytesPerRow: bytesPerRow,
        x0: (tr:CGFloat(0.0), tg:CGFloat(0.0), tb:CGFloat(0.0), count:0)) {
            (bdat, x0) in
            
            var x : (tr: CGFloat, tg: CGFloat, tb: CGFloat, count: Int)
            
            let alpha : CGFloat = CGFloat(bdat[3])/255.0
            x.tr = x0.tr+linstep(alpha, a: CGFloat(1.0), b: CGFloat(bdat[0])/CGFloat(255))
            x.tg = x0.tg+linstep(alpha, a: CGFloat(1.0), b: CGFloat(bdat[1])/CGFloat(255))
            x.tb = x0.tb+linstep(alpha, a: CGFloat(1.0), b: CGFloat(bdat[2])/CGFloat(255))
            x.count = x0.count+1
            
            return x
    }
    let tr = borderColour.tr/CGFloat(borderColour.count)
    let tg = borderColour.tg/CGFloat(borderColour.count)
    let tb = borderColour.tb/CGFloat(borderColour.count)
    
    CGContextRestoreGState(context2);
    
    // http://stackoverflow.com/questions/9444295/ios-does-cgbitmapcontextcreate-copy-data
    //    free(bitmapData)
    
    //    self.backgroundColor = UIColor(red: CGFloat(bdat[0])/255.0, green: CGFloat(bdat[1])/255.0, blue: CGFloat(bdat[2])/255.0, alpha: CGFloat(1.0))
    return UIColor(red: tr, green: tg, blue: tb, alpha: CGFloat(1.0))
}
