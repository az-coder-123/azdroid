import CoreMedia
import Foundation
import VideoToolbox

/// Hardware H.264 decoding with VideoToolbox for one video session.
///
/// Called from the session's reader thread only; frames arrive on
/// VideoToolbox's thread through [onFrame]. Contract:
/// docs/native-video-contract.md. Free of Flutter.
final class ScrcpyH264Decoder {
  /// A decoded BGRA frame and the time its packet was fully received.
  typealias FrameHandler = (CVPixelBuffer, UInt64) -> Void
  /// The presentation size from a new SPS (for example after rotation).
  typealias SizeHandler = (Int, Int) -> Void

  private static let nalLengthSize: Int32 = 4
  private static let frameLogCount = 3
  private static let frameLogInterval = 60

  private let onFrame: FrameHandler
  private let onSizeChange: SizeHandler
  private var session: VTDecompressionSession?
  private var formatDescription: CMVideoFormatDescription?
  private var sps: Data?
  private var pps: Data?
  private var activeSps: Data?
  private var activePps: Data?
  private var decodedFrames = 0

  init(onFrame: @escaping FrameHandler, onSizeChange: @escaping SizeHandler) {
    self.onFrame = onFrame
    self.onSizeChange = onSizeChange
  }

  /// Applies an SPS/PPS config packet.
  func applyConfig(_ data: Data) {
    remember(parameterSetsIn: ScrcpyAnnexB.split(data))
    if let sps, let pps { createSession(sps: sps, pps: pps) }
  }

  /// Decodes one media packet asynchronously.
  func decode(_ data: Data, receivedAt: UInt64) {
    let nalus = ScrcpyAnnexB.split(data)
    guard !nalus.isEmpty else { return }
    remember(parameterSetsIn: nalus)
    if session == nil, let sps, let pps { createSession(sps: sps, pps: pps) }
    guard let session, let sample = makeSampleBuffer(ScrcpyAnnexB.avccSample(from: nalus))
    else { return }

    var flagsOut: VTDecodeInfoFlags = []
    VTDecompressionSessionDecodeFrame(
      session,
      sampleBuffer: sample,
      flags: [._EnableAsynchronousDecompression],
      // Returned unchanged to the output callback to measure processing time.
      frameRefcon: UnsafeMutableRawPointer(bitPattern: UInt(receivedAt)),
      infoFlagsOut: &flagsOut
    )
  }

  /// Ends decoding; no frame is delivered after this returns.
  func invalidate() {
    if let session {
      VTDecompressionSessionWaitForAsynchronousFrames(session)
      VTDecompressionSessionInvalidate(session)
    }
    session = nil
    formatDescription = nil
  }

  private func remember(parameterSetsIn nalus: [Data]) {
    for nalu in nalus where !nalu.isEmpty {
      switch ScrcpyAnnexB.type(of: nalu) {
      case ScrcpyAnnexB.naluTypeSps: sps = nalu
      case ScrcpyAnnexB.naluTypePps: pps = nalu
      default: break
      }
    }
  }

  private func createSession(sps: Data, pps: Data) {
    if session != nil && activeSps == sps && activePps == pps { return }
    activeSps = sps
    activePps = pps
    ScrcpyLog.write(
      "Initializing VideoToolbox decompression session (SPS: \(sps.count), PPS: \(pps.count))...")
    guard let format = makeFormatDescription(sps: sps, pps: pps) else { return }
    formatDescription = format

    // A new SPS follows every rotation; keep the reported size in sync.
    // Clean-aperture dimensions apply the SPS cropping (1088 -> 1080).
    let presented = CMVideoFormatDescriptionGetPresentationDimensions(
      format, usePixelAspectRatio: false, useCleanAperture: true)
    onSizeChange(Int(presented.width.rounded()), Int(presented.height.rounded()))

    if let old = session {
      VTDecompressionSessionInvalidate(old)
      session = nil
    }
    var callback = VTDecompressionOutputCallbackRecord(
      decompressionOutputCallback: { refCon, frameRefCon, status, _, imageBuffer, _, _ in
        guard status == noErr, let imageBuffer, let refCon else { return }
        let decoder = Unmanaged<ScrcpyH264Decoder>.fromOpaque(refCon).takeUnretainedValue()
        // The frame refcon carries the packet receive time (see decode).
        decoder.deliver(imageBuffer, receivedAt: UInt64(UInt(bitPattern: frameRefCon)))
      },
      decompressionOutputRefCon: Unmanaged.passUnretained(self).toOpaque()
    )
    // Metal-compatible, IOSurface-backed BGRA for the Flutter texture.
    let attributes: [String: Any] = [
      kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
      kCVPixelBufferMetalCompatibilityKey as String: true,
      kCVPixelBufferIOSurfacePropertiesKey as String: [:] as [String: Any],
    ]
    var newSession: VTDecompressionSession?
    let status = VTDecompressionSessionCreate(
      allocator: kCFAllocatorDefault, formatDescription: format, decoderSpecification: nil,
      imageBufferAttributes: attributes as CFDictionary, outputCallback: &callback,
      decompressionSessionOut: &newSession)
    if status == noErr {
      session = newSession
      ScrcpyLog.write("VTDecompressionSession hardware decoder initialized successfully!")
    } else {
      ScrcpyLog.write("VTDecompressionSessionCreate failed: \(status)")
    }
  }

  private func makeFormatDescription(sps: Data, pps: Data) -> CMVideoFormatDescription? {
    let spsBytes = [UInt8](sps)
    let ppsBytes = [UInt8](pps)
    var format: CMFormatDescription?
    let status = spsBytes.withUnsafeBufferPointer { spsBuffer in
      ppsBytes.withUnsafeBufferPointer { ppsBuffer -> OSStatus in
        guard let spsBase = spsBuffer.baseAddress, let ppsBase = ppsBuffer.baseAddress
        else { return kCMFormatDescriptionError_InvalidParameter }
        return CMVideoFormatDescriptionCreateFromH264ParameterSets(
          allocator: kCFAllocatorDefault, parameterSetCount: 2,
          parameterSetPointers: [spsBase, ppsBase],
          parameterSetSizes: [sps.count, pps.count],
          nalUnitHeaderLength: Self.nalLengthSize, formatDescriptionOut: &format)
      }
    }
    guard status == noErr, let format else {
      ScrcpyLog.write("CMVideoFormatDescriptionCreate failed: \(status)")
      return nil
    }
    return format
  }

  private func makeSampleBuffer(_ avcc: Data) -> CMSampleBuffer? {
    guard !avcc.isEmpty, let formatDescription else { return nil }
    var block: CMBlockBuffer?
    guard
      CMBlockBufferCreateWithMemoryBlock(
        allocator: kCFAllocatorDefault, memoryBlock: nil, blockLength: avcc.count,
        blockAllocator: kCFAllocatorDefault, customBlockSource: nil, offsetToData: 0,
        dataLength: avcc.count, flags: 0, blockBufferOut: &block) == noErr,
      let block
    else { return nil }
    avcc.withUnsafeBytes { bytes in
      if let base = bytes.baseAddress {
        CMBlockBufferReplaceDataBytes(
          with: base, blockBuffer: block, offsetIntoDestination: 0, dataLength: avcc.count)
      }
    }
    var timing = CMSampleTimingInfo(
      duration: .invalid, presentationTimeStamp: .invalid, decodeTimeStamp: .invalid)
    var sample: CMSampleBuffer?
    let status = CMSampleBufferCreate(
      allocator: kCFAllocatorDefault, dataBuffer: block, dataReady: true,
      makeDataReadyCallback: nil, refcon: nil, formatDescription: formatDescription,
      sampleCount: 1, sampleTimingEntryCount: 1, sampleTimingArray: &timing,
      sampleSizeEntryCount: 1, sampleSizeArray: [avcc.count], sampleBufferOut: &sample)
    return status == noErr ? sample : nil
  }

  private func deliver(_ pixelBuffer: CVPixelBuffer, receivedAt: UInt64) {
    let format = CVPixelBufferGetPixelFormatType(pixelBuffer)
    if format == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
      || format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    {
      CVBufferSetAttachment(
        pixelBuffer, kCVImageBufferYCbCrMatrixKey, kCVImageBufferYCbCrMatrix_ITU_R_709_2,
        .shouldPropagate)
      CVBufferSetAttachment(
        pixelBuffer, kCVImageBufferColorPrimariesKey, kCVImageBufferColorPrimaries_ITU_R_709_2,
        .shouldPropagate)
      CVBufferSetAttachment(
        pixelBuffer, kCVImageBufferTransferFunctionKey,
        kCVImageBufferTransferFunction_ITU_R_709_2, .shouldPropagate)
    }
    decodedFrames += 1
    if decodedFrames <= Self.frameLogCount || decodedFrames % Self.frameLogInterval == 0 {
      ScrcpyLog.write("Decoded frame #\(decodedFrames): format=0x\(String(format, radix: 16))")
    }
    onFrame(pixelBuffer, receivedAt)
  }
}
