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
        case failedToSetFrameBrotliEffort
        case failedToSetFrameLossless
    }
}

// MARK: - Encoding

public extension JXL {
    struct EncoderConfig {
        /// Effort setting.
        /// Range: 1 .. 9.
        /// Default: 7.
        /// Higher number is more effort (slower).
        /// Sets encoder effort/speed level without affecting decoding speed. Valid
        /// values are, from faster to slower speed: 1:lightning 2:thunder 3:falcon
        /// 4:cheetah 5:hare 6:wombat 7:squirrel 8:kitten 9:tortoise.
        /// Default: squirrel (7).
        ///
        public var effort: Int

        /// Brotli effort setting.
        /// Range: 0 .. 11.
        /// Default: 9.
        /// Higher number is more effort (slower).
        /// Sets brotli encode effort for use in JPEG recompression and compressed.
        /// metadata boxes (brob). Can be -1 (default) or 0 (fastest) to 11 (slowest).
        /// Default is based on the general encode effort in case of JPEG
        /// recompression, and 4 for brob boxes.
        public var brotli_effort: Int

        /// Sets the distance level for lossy compression:
        /// target max butteraugli distance, lower = higher quality. Range: 0 .. 15.
        /// 0.0 = mathematically lossless (however, use JxlEncoderSetFrameLossless instead to use true lossless, as setting distance to 0 alone is not the only requirement).
        /// 1.0 = visually lossless.
        /// Recommended range: 0.5 .. 3.0.
        /// Default value: 1.0.
        public var distance: Float

        public var lossless: Bool

        // public var keelInvisible: Bool

        public init(
            effort: Int = 7,
            brotli_effort: Int = 9,
            distance: Float = 1.0,
            lossless: Bool = true
        ) {
            self.effort = effort
            self.brotli_effort = brotli_effort
            self.distance = distance
            self.lossless = lossless
        }
    }

    /// - Parameters:
    ///   - data: jpeg data
    /// - Returns: jpeg xl data
    ///
    /// <https://libjxl.readthedocs.io/en/latest/api_encoder.html>
    /// <https://github.com/libjxl/libjxl/blob/141c48f552851b5efb17ec4053adb8202a250372/examples/encode_oneshot.cc#L149>
    /// <https://github.com/libjxl/libjxl/blob/141c48f552851b5efb17ec4053adb8202a250372/lib/extras/enc/jxl.cc#L38>
    static func encode(jpeg data: Data, config: EncoderConfig = .init()) throws -> Data {
        let enc = JxlEncoderCreate(nil)
        defer { JxlEncoderDestroy(enc) }
        let runner = JxlThreadParallelRunnerCreate(nil, JxlThreadParallelRunnerDefaultNumWorkerThreads())
        defer { JxlThreadParallelRunnerDestroy(runner) }
        guard JxlEncoderSetParallelRunner(enc, JxlThreadParallelRunner, runner) == JXL_ENC_SUCCESS else {
            throw Error.failedToSetParallelRunner
        }

        guard let frame_settings = JxlEncoderFrameSettingsCreate(enc, nil) else {
            throw Error.failedToCreateFrameSettings
        }

        guard JxlEncoderFrameSettingsSetOption(frame_settings, JXL_ENC_FRAME_SETTING_EFFORT, Int64(config.effort)) == JXL_ENC_SUCCESS else {
            throw Error.failedToSetFrameEffort
        }

        guard JxlEncoderFrameSettingsSetOption(frame_settings, JXL_ENC_FRAME_SETTING_BROTLI_EFFORT, Int64(config.brotli_effort)) == JXL_ENC_SUCCESS else {
            throw Error.failedToSetFrameBrotliEffort
        }

        guard JxlEncoderSetFrameDistance(frame_settings, config.distance) == JXL_ENC_SUCCESS else {
            throw Error.failedToSetFrameDistance
        }

        guard JxlEncoderSetFrameLossless(frame_settings, config.lossless ? 1 : 0) == JXL_ENC_SUCCESS else {
            throw Error.failedToSetFrameLossless
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
