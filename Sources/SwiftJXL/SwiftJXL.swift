import CoreGraphics
import Foundation
import jxl

public enum JXL {
    public enum Error: Swift.Error {
        case failedToSetParallelRunner
        case failedToCreateFrameSettings
        case failedToAddImageFrame
        case failedToProcessEncoderOutput
    }
}

// MARK: - Encoding

public extension JXL {
    /// https://github.com/libjxl/libjxl/blob/141c48f552851b5efb17ec4053adb8202a250372/examples/encode_oneshot.cc#L149
    static func encode(jpeg data: Data) throws -> Data {
        let enc = JxlEncoderCreate(nil)
        defer { JxlEncoderDestroy(enc) }
        let runner = JxlThreadParallelRunnerCreate(nil, JxlThreadParallelRunnerDefaultNumWorkerThreads())

        guard JxlEncoderSetParallelRunner(enc, JxlThreadParallelRunner, runner) == JXL_ENC_SUCCESS else {
            throw Error.failedToSetParallelRunner
        }

        guard let frame_settings = JxlEncoderFrameSettingsCreate(enc, nil) else {
            throw Error.failedToCreateFrameSettings
        }

        let size = data.count * MemoryLayout<UInt8>.size
        return try data.withUnsafeBytes { ptr in
            guard JxlEncoderAddJPEGFrame(
                frame_settings,
                ptr.baseAddress,
                size
            ) == JXL_ENC_SUCCESS else {
                throw Error.failedToAddImageFrame
            }
            JxlEncoderCloseInput(enc)

            var process_result: JxlEncoderStatus = JXL_ENC_NEED_MORE_OUTPUT

            // bytes
            let count = 64
            var avail_out: Int = -1
            var bytes = [UInt8]()

            while process_result == JXL_ENC_NEED_MORE_OUTPUT {
                avail_out = count
                let next_out = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: count)
                next_out.initialize(repeating: 0)
                var ptr = next_out.baseAddress
                process_result = JxlEncoderProcessOutput(enc, &ptr, &avail_out)
                let written = count - avail_out
                bytes.append(contentsOf: next_out[0 ..< written])
                next_out.deallocate()
            }

            guard JXL_ENC_SUCCESS == process_result else {
                throw Error.failedToProcessEncoderOutput
            }

            return Data(bytes)
        }
    }
}

public extension JXL {
    static func decode(jxl _: Data) throws -> Data {
        fatalError("implementation missing")
    }
}
