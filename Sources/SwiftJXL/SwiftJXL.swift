// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import jxl
import CoreGraphics
import AppKit



func a() {

}

public struct JXLCoder {

    public enum Error: Swift.Error {
        case failedToSetParallelRunner
        case failedToSetBasicInfo
        case failedToSetColorEncoding
        case failedToCreateCGImage
        case failedToGetDataProvider
        case failedToGetPixelData
        case failedToAddImageFrame
        case failedToProcessEncoderOutput
    }

    public static func encode(image: APPLImage, numWorkerThreads: Int = JxlThreadParallelRunnerDefaultNumWorkerThreads()) throws -> Data {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: NSGraphicsContext.current, hints: nil) else {
            throw Error.failedToCreateCGImage
        }
        return try encode(cgImage: cgImage, numWorkerThreads: numWorkerThreads)
    }

    /// https://github.com/libjxl/libjxl/blob/141c48f552851b5efb17ec4053adb8202a250372/examples/encode_oneshot.cc#L149
    public static func encode(cgImage: CGImage, numWorkerThreads: Int = JxlThreadParallelRunnerDefaultNumWorkerThreads()) throws -> Data {
        let enc = JxlEncoderCreate(nil)
        let runner = JxlThreadParallelRunnerCreate(nil, numWorkerThreads)

        guard JxlEncoderSetParallelRunner(enc, JxlThreadParallelRunner, runner) == JXL_ENC_SUCCESS else {
            throw Error.failedToSetParallelRunner
        }

        let xsize = Int(cgImage.width)
        let ysize = Int(cgImage.height)

        var basic_info = JxlBasicInfo()
        JxlEncoderInitBasicInfo(&basic_info)
        basic_info.xsize = UInt32(xsize)
        basic_info.ysize = UInt32(ysize)
        basic_info.bits_per_sample = 32 //cgImage.bitsPerPixel
        basic_info.exponent_bits_per_sample = 8 // cgImage.bitsPerComponent
        basic_info.uses_original_profile = JXL_FALSE


        guard JxlEncoderSetBasicInfo(enc, &basic_info) == JXL_ENC_SUCCESS else {
            throw Error.failedToSetBasicInfo
        }

        var pixelFormat = JxlPixelFormat(
            num_channels: 3,
            data_type: JXL_TYPE_FLOAT,
            endianness: JXL_BIG_ENDIAN,
            align: 0
        )

        var color_encoding = JxlColorEncoding()
        let is_gray: Int32 = pixelFormat.num_channels < 3 ? 1 : 0
        JxlColorEncodingSetToSRGB(&color_encoding, is_gray)

        guard JxlEncoderSetColorEncoding(enc, &color_encoding) == JXL_ENC_SUCCESS else {
            throw Error.failedToSetColorEncoding
        }

        guard let dataProvider = cgImage.dataProvider else {
            throw Error.failedToGetDataProvider
        }

        guard let pixelData = dataProvider.data else {
            throw Error.failedToGetPixelData
        }

        let frame_settings = JxlEncoderFrameSettingsCreate(enc, nil)!

        let pixelBufferPtr = UnsafeRawPointer(CFDataGetBytePtr(pixelData)!)
        let pixelBufferSize: Int = CFDataGetLength(pixelData) * Int(pixelFormat.num_channels) // MemoryLayout<Float>.size * xsize * ysize

        guard JxlEncoderAddImageFrame(
            frame_settings,
            &pixelFormat,
            pixelBufferPtr,
            pixelBufferSize
        ) == JXL_ENC_SUCCESS else {
            throw Error.failedToAddImageFrame
        }
        JxlEncoderCloseInput(enc)

        var process_result: JxlEncoderStatus = JXL_ENC_NEED_MORE_OUTPUT

        // bytes
        let count: Int = 64
        var avail_out: Int = -1
        var bytes = [UInt8]()

        while process_result == JXL_ENC_NEED_MORE_OUTPUT {
            avail_out = count
            let next_out = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: count)
            next_out.initialize(repeating: 0)
            var ptr = next_out.baseAddress
            process_result = JxlEncoderProcessOutput(enc, &ptr, &avail_out)
            let written = count - avail_out
            bytes.append(contentsOf: next_out[0..<written])
            next_out.deallocate()
        }

        guard JXL_ENC_SUCCESS == process_result else {
            throw Error.failedToProcessEncoderOutput
        }

        print(bytes.count)

        return Data(bytes)
    }

    public static func decode(from data: Data) throws -> APPLImage {
        fatalError()
    }


}
