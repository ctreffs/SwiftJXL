import CoreGraphics
import Foundation
import jxl

public enum JXL {
    public enum Error: Swift.Error {
        case failedToSetParallelRunner
        case failedToCreateFrameSettings
        case failedToAddImageFrame
        case failedToProcessEncoderOutput
        case failedToSetFrameDistance
        case failedToSetFrameEffort
    }
}

// MARK: - Encoding

public extension JXL {
    struct EncoderConfig {
        /// Effort setting.
        /// Range: 1 .. 9.
        /// Default: 7.
        /// Higher number is more effort (slower).
        public var effort: Int

        /// Sets the distance level for lossy compression:
        /// target max butteraugli distance, lower = higher quality. Range: 0 .. 15.
        /// 0.0 = mathematically lossless (however, use JxlEncoderSetFrameLossless instead to use true lossless, as setting distance to 0 alone is not the only requirement).
        /// 1.0 = visually lossless.
        /// Recommended range: 0.5 .. 3.0.
        /// Default value: 1.0.
        public var distance: Float

        public init(
            effort: Int = 7,
            distance: Float = 1.0
        ) {
            self.effort = effort
            self.distance = distance
        }
    }

    /// - Parameters:
    ///   - data: jpeg data

    /// - Returns: jpeg xl data
    ///
    /// <https://github.com/libjxl/libjxl/blob/141c48f552851b5efb17ec4053adb8202a250372/examples/encode_oneshot.cc#L149>
    static func encode(jpeg data: Data, config: EncoderConfig = .init()) throws -> Data {
        let enc = JxlEncoderCreate(nil)
        defer { JxlEncoderDestroy(enc) }
        let runner = JxlThreadParallelRunnerCreate(nil, JxlThreadParallelRunnerDefaultNumWorkerThreads())

        guard JxlEncoderSetParallelRunner(enc, JxlThreadParallelRunner, runner) == JXL_ENC_SUCCESS else {
            throw Error.failedToSetParallelRunner
        }

        guard let frame_settings = JxlEncoderFrameSettingsCreate(enc, nil) else {
            throw Error.failedToCreateFrameSettings
        }

        guard JxlEncoderFrameSettingsSetOption(frame_settings, JXL_ENC_FRAME_SETTING_EFFORT, Int64(config.effort)) == JXL_ENC_SUCCESS else {
            throw Error.failedToSetFrameEffort
        }

        guard JxlEncoderSetFrameDistance(frame_settings, config.distance) == JXL_ENC_SUCCESS else {
            throw Error.failedToSetFrameDistance
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
