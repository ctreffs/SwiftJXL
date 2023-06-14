import Foundation
import SwiftJXL
import AppKit

if #available(macOS 11.0, *) {
    //let file = URL(fileURLWithPath: "/Users/ctreffs/Desktop/Philips_PM5544.svg.png")
    let file = URL(fileURLWithPath: "/Users/ctreffs/Desktop/White.jpg")
    let image = APPLImage.init(contentsOf: file)!
    let data = try JXLCoder.encode(image: image)
    let outFile = FileManager.default.temporaryDirectory.appendingPathComponent("\(file.lastPathComponent)-\(Date().timeIntervalSince1970).jxl")
    try data.write(to: outFile)
    print(outFile.path)

} else {
    // Fallback on earlier versions
}
