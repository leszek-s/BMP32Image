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

import Foundation

print("Testing BMP32Image")

let currentDirectoryUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let testFileUrl = currentDirectoryUrl.appendingPathComponent("testFile.bmp")

print("Generating 100x100 BMP file: \(testFileUrl)")

var data = [UInt8](repeating: 0, count: 100 * 100 * 4)
for y in 0 ..< 100 {
    for x in 0 ..< 100 {
        data[4 * (x + y * 100)] = 255 // B
        data[4 * (x + y * 100) + 1] = 0 // G
        data[4 * (x + y * 100) + 2] = 0 // R
        data[4 * (x + y * 100) + 3] = UInt8(255 * y / 100) // A
    }
}
let image = BMP32Image(width: 100, height: 100, pixelData: data, topDown: true)
try? image?.bmpData().write(to: testFileUrl)

print("Reading BMP file: \(testFileUrl)")

guard let fileData = try? Data(contentsOf: testFileUrl) else {
    exit(1)
}

let imageFromFile = BMP32Image(bmpData: fileData)

let testFileCopyUrl = currentDirectoryUrl.appendingPathComponent("testFileCopy.bmp")

print ("Writing BMP file: \(testFileCopyUrl)")

try? imageFromFile?.bmpData().write(to: testFileCopyUrl)
