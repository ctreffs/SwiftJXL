import Foundation
import SwiftJXL

guard let filePath = CommandLine.arguments.dropFirst().first else {
    fatalError("no image file path given")
}

guard FileManager.default.fileExists(atPath: filePath) else {
    fatalError("no file at path \(filePath)")
}

let fileURL = URL(fileURLWithPath: filePath)
let filename = fileURL.lastPathComponent
let dir = fileURL.deletingLastPathComponent()

let inData = try Data(contentsOf: fileURL)
let outFile: URL
let outData: Data
switch fileURL.pathExtension.lowercased() {
case "jpg", "jpeg":
    outData = try JXL.encode(jpeg: inData)
    outFile = dir.appendingPathComponent("\(filename).jxl")
case "jxl":
    outData = try JXL.decode(jxl: inData)
    outFile = dir.appendingPathComponent("\(filename).jpg")
default:
    fatalError("unsupported file type \(filePath)")
}
try outData.write(to: outFile)
print("\(outFile.path)")
