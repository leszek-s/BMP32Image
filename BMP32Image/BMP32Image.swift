// BMP32Image
//
// Copyright (c) 2021 Leszek S
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// BMP32Image v1.0.0
// This single file cross platform pure swift library is an implementation
// of reading and writing 32 bit BMP image files with alpha channel support.

import Foundation

/// Represents a 32 bit BMP image.
public class BMP32Image {
    /// Width of the image (value > 0).
    public private(set) var width: Int
    /// Height of the image (value > 0).
    public private(set) var height: Int
    /// Pixel data. Each pixel is always a 32 bit ARGB value saved in little endian order (therefore bytes order is: BGRA BGRA BGRA... and array size is width * height * 4).
    public private(set) var pixelData: [UInt8]
    /// If pixel data is in top-down format (starts from upper left corner) then this is true. Otherwise is in bottom up format (starts from bottom left corner).
    public private(set) var topDown: Bool
    
    /// Init with BMP file data.
    /// - Parameter bmpData: BMP file data.
    public init?(bmpData: Data) {
        guard let fileHeader = BitmapFileHeader(bmpData: bmpData),
            let infoHeader = BitmapInfoHeader(bmpData: bmpData),
            bmpData.count > fileHeader.bfOffBits
        else {
            // Invalid or unsupported BMP file
            return nil
        }
        let pixelData = bmpData.subdata(in: Int(fileHeader.bfOffBits) ..< bmpData.count)
        self.width = Int(infoHeader.biWidth)
        self.height = Int(abs(infoHeader.biHeight))
        self.pixelData = [UInt8](pixelData)
        self.topDown = infoHeader.biHeight < 0
    }
    
    /// Returns BMP image file data.
    /// - Returns: BMP file data.
    public func bmpData() -> Data {
        let fileHeader = BitmapFileHeader(pixelDataSize: UInt32(pixelData.count))
        let infoHeader = BitmapInfoHeader(width: Int32(width), height: Int32(topDown ? -height : height))
        var data = Data()
        data.append(fileHeader.headerData())
        data.append(infoHeader.headerData())
        data.append(contentsOf: pixelData)
        return data
    }
    
    /// Init with given width, height, pixel data and top-down/bottom-up pixel order information.
    /// - Parameters:
    ///   - width: Image width.
    ///   - height: Image height.
    ///   - pixelData: Pixel data. Size of this data must be equal to width * height * 4.
    ///   - topDown: Information about pixels order (top-down or bottom-up).
    public init?(width: Int, height: Int, pixelData: [UInt8], topDown: Bool = false) {
        if width <= 0 || height <= 0 || width * height * 4 != pixelData.count {
            return nil
        }
        self.width = width
        self.height = height
        self.pixelData = pixelData
        self.topDown = topDown
    }
}

fileprivate struct BC {
    static let BITMAPFILEHEADER_SIZE: UInt32 = 14
    static let BITMAPINFOHEADER_SIZE: UInt32 = 40
    static let BITMAPV3INFOHEADER_SIZE: UInt32 = 56
    static let BITMAPTYPE_BM: UInt16 = 0x4D42
    static let BI_RGB: UInt32 = 0
    static let BI_BITFIELDS: UInt32 = 3
}

fileprivate struct BitmapFileHeader {
    var bfType: UInt16
    var bfSize: UInt32
    var bfReserved1: UInt16
    var bfReserved2: UInt16
    var bfOffBits: UInt32
    
    init(pixelDataSize: UInt32) {
        bfType = BC.BITMAPTYPE_BM
        bfSize = BC.BITMAPFILEHEADER_SIZE + BC.BITMAPV3INFOHEADER_SIZE + pixelDataSize
        bfReserved1 = 0
        bfReserved2 = 0
        bfOffBits = BC.BITMAPFILEHEADER_SIZE + BC.BITMAPV3INFOHEADER_SIZE
    }
    
    init?(bmpData: Data) {
        guard bmpData.count >= BC.BITMAPFILEHEADER_SIZE,
            let bfType = UInt16(littleEndianData: bmpData.subdata(in: 0 ..< 2)),
            let bfSize = UInt32(littleEndianData: bmpData.subdata(in: 2 ..< 6)),
            let bfReserved1 = UInt16(littleEndianData: bmpData.subdata(in: 6 ..< 8)),
            let bfReserved2 = UInt16(littleEndianData: bmpData.subdata(in: 8 ..< 10)),
            let bfOffBits = UInt32(littleEndianData: bmpData.subdata(in: 10 ..< 14)),
            bfType == BC.BITMAPTYPE_BM,
            bfOffBits >= BC.BITMAPFILEHEADER_SIZE + BC.BITMAPINFOHEADER_SIZE
        else {
            // Invalid or unsupported BMP file
            return nil
        }
        self.bfType = bfType
        self.bfSize = bfSize
        self.bfReserved1 = bfReserved1
        self.bfReserved2 = bfReserved2
        self.bfOffBits = bfOffBits
    }
    
    func headerData() -> Data {
        var data = Data()
        data.append(bfType.littleEndianData())
        data.append(bfSize.littleEndianData())
        data.append(bfReserved1.littleEndianData())
        data.append(bfReserved2.littleEndianData())
        data.append(bfOffBits.littleEndianData())
        return data
    }
}

fileprivate struct BitmapInfoHeader {
    var biSize: UInt32
    var biWidth: Int32
    var biHeight: Int32
    var biPlanes: UInt16
    var biBitCount: UInt16
    var biCompression: UInt32
    var biSizeImage: UInt32
    var biXPelsPerMeter: Int32
    var biYPelsPerMeter: Int32
    var biClrUsed: UInt32
    var biClrImportant: UInt32
    
    var biRedMask: UInt32
    var biGreenMask: UInt32
    var biBlueMask: UInt32
    var biAlphaMask: UInt32
    
    init(width: Int32, height: Int32) {
        biSize = BC.BITMAPV3INFOHEADER_SIZE
        biWidth = width
        biHeight = height
        biPlanes = 1
        biBitCount = 32
        biCompression = BC.BI_BITFIELDS
        biSizeImage = UInt32(abs(width * height * 4))
        biXPelsPerMeter = 0
        biYPelsPerMeter = 0
        biClrUsed = 0
        biClrImportant = 0
        biRedMask = 0x00FF0000
        biGreenMask = 0x0000FF00
        biBlueMask = 0x000000FF
        biAlphaMask = 0xFF000000
    }
    
    init?(bmpData: Data) {
        guard bmpData.count >= BC.BITMAPFILEHEADER_SIZE + BC.BITMAPINFOHEADER_SIZE,
            let biSize = UInt32(littleEndianData: bmpData.subdata(in: 14 ..< 18)),
            let biWidth = Int32(littleEndianData: bmpData.subdata(in: 18 ..< 22)),
            let biHeight = Int32(littleEndianData: bmpData.subdata(in: 22 ..< 26)),
            let biPlanes = UInt16(littleEndianData: bmpData.subdata(in: 26 ..< 28)),
            let biBitCount = UInt16(littleEndianData: bmpData.subdata(in: 28 ..< 30)),
            let biCompression = UInt32(littleEndianData: bmpData.subdata(in: 30 ..< 34)),
            let biSizeImage = UInt32(littleEndianData: bmpData.subdata(in: 34 ..< 38)),
            let biXPelsPerMeter = Int32(littleEndianData: bmpData.subdata(in: 38 ..< 42)),
            let biYPelsPerMeter = Int32(littleEndianData: bmpData.subdata(in: 42 ..< 46)),
            let biClrUsed = UInt32(littleEndianData: bmpData.subdata(in: 46 ..< 50)),
            let biClrImportant = UInt32(littleEndianData: bmpData.subdata(in: 50 ..< 54)),
            biSize >= BC.BITMAPINFOHEADER_SIZE,
            biWidth > 0,
            biHeight != 0,
            biBitCount == 32,
            biCompression == BC.BI_RGB || (biCompression == BC.BI_BITFIELDS && biSize >= BC.BITMAPV3INFOHEADER_SIZE && bmpData.count >= BC.BITMAPFILEHEADER_SIZE + BC.BITMAPV3INFOHEADER_SIZE)
        else {
            // Invalid or unsupported BMP file
            return nil
        }
        
        self.biSize = biSize
        self.biWidth = biWidth
        self.biHeight = biHeight
        self.biPlanes = biPlanes
        self.biBitCount = biBitCount
        self.biCompression = biCompression
        self.biSizeImage = biSizeImage
        self.biXPelsPerMeter = biXPelsPerMeter
        self.biYPelsPerMeter = biYPelsPerMeter
        self.biClrUsed = biClrUsed
        self.biClrImportant = biClrImportant
        self.biRedMask = 0
        self.biGreenMask = 0
        self.biBlueMask = 0
        self.biAlphaMask = 0
        
        if biCompression == BC.BI_BITFIELDS && biSize >= BC.BITMAPV3INFOHEADER_SIZE && bmpData.count >= BC.BITMAPFILEHEADER_SIZE + BC.BITMAPV3INFOHEADER_SIZE {
            guard let biRedMask = UInt32(littleEndianData: bmpData.subdata(in: 54 ..< 58)),
                let biGreenMask = UInt32(littleEndianData: bmpData.subdata(in: 58 ..< 62)),
                let biBlueMask = UInt32(littleEndianData: bmpData.subdata(in: 62 ..< 66)),
                let biAlphaMask = UInt32(littleEndianData: bmpData.subdata(in: 66 ..< 70)),
                biRedMask == 0x00FF0000,
                biGreenMask == 0x0000FF00,
                biBlueMask == 0x000000FF,
                biAlphaMask == 0xFF000000
            else {
                // Invalid or unsupported BMP file
                return nil
            }
            self.biRedMask = biRedMask
            self.biGreenMask = biGreenMask
            self.biBlueMask = biBlueMask
            self.biAlphaMask = biAlphaMask
        }
    }
    
    func headerData() -> Data {
        var data = Data()
        data.append(biSize.littleEndianData())
        data.append(biWidth.littleEndianData())
        data.append(biHeight.littleEndianData())
        data.append(biPlanes.littleEndianData())
        data.append(biBitCount.littleEndianData())
        data.append(biCompression.littleEndianData())
        data.append(biSizeImage.littleEndianData())
        data.append(biXPelsPerMeter.littleEndianData())
        data.append(biYPelsPerMeter.littleEndianData())
        data.append(biClrUsed.littleEndianData())
        data.append(biClrImportant.littleEndianData())
        data.append(biRedMask.littleEndianData())
        data.append(biGreenMask.littleEndianData())
        data.append(biBlueMask.littleEndianData())
        data.append(biAlphaMask.littleEndianData())
        return data
    }
}

fileprivate extension UInt32 {
    func littleEndianData() -> Data {
        return Data([UInt8(self & 0xFF), UInt8((self >> 8) & 0xFF), UInt8((self >> 16) & 0xFF), UInt8((self >> 24) & 0xFF)])
    }
    init?(littleEndianData data: Data) {
        guard data.count == 4 else {
            return nil
        }
        self = (UInt32(data[3]) << 24) | (UInt32(data[2]) << 16) | (UInt32(data[1]) << 8) | UInt32(data[0])
    }
}

fileprivate extension UInt16 {
    func littleEndianData() -> Data {
        return Data([UInt8(self & 0xFF), UInt8((self >> 8) & 0xFF)])
    }
    init?(littleEndianData data: Data) {
        guard data.count == 2 else {
            return nil
        }
        self = (UInt16(data[1]) << 8) | UInt16(data[0])
    }
}

fileprivate extension Int32 {
    func littleEndianData() -> Data {
        let bits = UInt32(bitPattern: self)
        return Data([UInt8(bits & 0xFF), UInt8((bits >> 8) & 0xFF), UInt8((bits >> 16) & 0xFF), UInt8((bits >> 24) & 0xFF)])
    }
    init?(littleEndianData data: Data) {
        guard data.count == 4 else {
            return nil
        }
        let bits = (UInt32(data[3]) << 24) | (UInt32(data[2]) << 16) | (UInt32(data[1]) << 8) | UInt32(data[0])
        self = Int32(bitPattern: bits)
    }
}

#if canImport(CoreGraphics)
import CoreGraphics

extension BMP32Image {
    /// Init from CGImage.
    /// - Parameter cgImage: CGImage to convert.
    public convenience init?(cgImage: CGImage) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var data = [UInt8](repeating: 0, count: cgImage.width * cgImage.height * 4)
        guard let context = CGContext(data: &data, width: cgImage.width, height: cgImage.height, bitsPerComponent: 8, bytesPerRow: 4 * cgImage.width, space: colorSpace, bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) else {
            return nil
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        self.init(width: cgImage.width, height: cgImage.height, pixelData: data, topDown: true)
    }
    
    /// Converts to CGImage.
    /// - Returns: Converted CGImage.
    public func cgImage() -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 4 * width, space: colorSpace, bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        return context?.makeImage()
    }
}
#endif
