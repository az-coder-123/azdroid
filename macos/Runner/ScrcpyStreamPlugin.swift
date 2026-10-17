import Cocoa
import CoreMedia
import Darwin
import FlutterMacOS
import VideoToolbox

/// Native macOS hardware-accelerated H.264 video decoder and FlutterTexture bridge
/// streaming live display frames from an active scrcpy-server daemon over local TCP socket.
public class ScrcpyStreamPlugin: NSObject, FlutterPlugin, FlutterTexture {
  private static var shared: ScrcpyStreamPlugin?
  private static var channel: FlutterMethodChannel?

  private weak var textureRegistry: FlutterTextureRegistry?
  private var textureId: Int64?
  private var currentPixelBuffer: CVPixelBuffer?
  private let pixelBufferLock = NSLock()

  private var isStreaming = false
  private var streamThread: Thread?
  private var streamSocket: Int32 = -1
  private var decompressionSession: VTDecompressionSession?
  private var formatDescription: CMVideoFormatDescription?

  private var spsData: Data?
  private var ppsData: Data?
  private var activeSps: Data?
  private var activePps: Data?
  private var decodedFrameCount = 0
  private let stats = ScrcpyStreamStats()

  public var videoWidth: Int = 0
  public var videoHeight: Int = 0

  static func streamLog(_ message: String) {
    NSLog("[ScrcpyStream] %@", message)
    let logLine = "[\(Date())] \(message)\n"
    if let data = logLine.data(using: .utf8) {
      let path = "/tmp/scrcpy_stream.log"
      if let fileHandle = FileHandle(forWritingAtPath: path) {
        fileHandle.seekToEndOfFile()
        fileHandle.write(data)
        fileHandle.closeFile()
      } else {
        try? data.write(to: URL(fileURLWithPath: path))
      }
    }
  }

  public init(textures: FlutterTextureRegistry) {
    self.textureRegistry = textures
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.deskdroid/video_stream",
      binaryMessenger: registrar.messenger
    )
    let instance = ScrcpyStreamPlugin(textures: registrar.textures)
    self.shared = instance
    self.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
    streamLog("Registered via FlutterPluginRegistrar")
  }

  @objc public static func register(with controller: FlutterViewController) {
    streamLog("Registering via FlutterViewController...")
    let channel = FlutterMethodChannel(
      name: "com.deskdroid/video_stream",
      binaryMessenger: controller.engine.binaryMessenger
    )
    let instance = ScrcpyStreamPlugin(textures: controller.engine)
    self.shared = instance
    self.channel = channel
    channel.setMethodCallHandler({ call, result in
      ScrcpyStreamPlugin.shared?.handle(call, result: result)
    })
    streamLog("Registered successfully with controller.engine")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    ScrcpyStreamPlugin.streamLog("MethodChannel handle called: \(call.method)")
    switch call.method {
    case "startStream":
      let args = call.arguments as? [String: Any] ?? [:]
      let host = args["host"] as? String ?? "127.0.0.1"
      let port = args["port"] as? Int ?? 27183
      startStream(host: host, port: port, result: result)

    case "stopStream":
      stopStream()
      result(true)

    case "getDimensions":
      result(["width": videoWidth, "height": videoHeight])

    case "getStats":
      result(stats.snapshot())

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    pixelBufferLock.lock()
    defer { pixelBufferLock.unlock() }
    guard let buffer = currentPixelBuffer else { return nil }
    return Unmanaged.passRetained(buffer)
  }

  private func startStream(
    host: String, port: Int, result: @escaping FlutterResult
  ) {
    ScrcpyStreamPlugin.streamLog("startStream invoked for \(host):\(port)")
    stopStream()

    guard let registry = textureRegistry else {
      ScrcpyStreamPlugin.streamLog("ERROR: textureRegistry is nil")
      result(
        FlutterError(
          code: "NO_REGISTRY", message: "Texture registry unavailable",
          details: nil))
      return
    }

    let id = registry.register(self)
    ScrcpyStreamPlugin.streamLog("Texture registered with ID: \(id)")
    self.textureId = id
    self.isStreaming = true
    stats.reset(to: .connecting)

    let thread = Thread { [weak self] in
      self?.runStreamLoop(host: host, port: port)
    }
    self.streamThread = thread
    thread.name = "com.deskdroid.scrcpy_stream"
    thread.start()

    result(id)
  }

  private func stopStream() {
    isStreaming = false
    stats.reset(to: .idle)

    if streamSocket >= 0 {
      Darwin.shutdown(streamSocket, SHUT_RDWR)
      Darwin.close(streamSocket)
      streamSocket = -1
    }

    if let oldSession = decompressionSession {
      VTDecompressionSessionInvalidate(oldSession)
      decompressionSession = nil
    }
    formatDescription = nil
    spsData = nil
    ppsData = nil
    activeSps = nil
    activePps = nil
    decodedFrameCount = 0

    if let id = textureId {
      textureRegistry?.unregisterTexture(id)
      textureId = nil
    }

    pixelBufferLock.lock()
    currentPixelBuffer = nil
    pixelBufferLock.unlock()
  }

  private func runStreamLoop(host: String, port: Int) {
    ScrcpyStreamPlugin.streamLog("runStreamLoop: connecting to \(host):\(port)...")
    var headerReceived = false
    var sock: Int32 = -1

    for attempt in 1...30 {
      guard isStreaming else { return }
      sock = Darwin.socket(AF_INET, SOCK_STREAM, 0)
      guard sock >= 0 else {
        usleep(300_000)
        continue
      }

      var serverAddr = sockaddr_in()
      serverAddr.sin_family = sa_family_t(AF_INET)
      serverAddr.sin_port = in_port_t(UInt16(port).bigEndian)
      inet_pton(AF_INET, host, &serverAddr.sin_addr)

      let res = withUnsafePointer(to: &serverAddr) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
          Darwin.connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
        }
      }

      guard res == 0 else {
        Darwin.close(sock)
        sock = -1
        usleep(300_000)
        continue
      }

      self.streamSocket = sock

      var tv = timeval(tv_sec: 1, tv_usec: 0)
      setsockopt(
        sock, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))

      // 1. Read scrcpy header: 1 dummy byte (0x00), 64 bytes device name, 4 bytes codec, 4 bytes width, 4 bytes height
      guard let dummy = readExact(socket: sock, count: 1),
        let devNameData = readExact(socket: sock, count: 64),
        let codecData = readExact(socket: sock, count: 4),
        let widthData = readExact(socket: sock, count: 4),
        let heightData = readExact(socket: sock, count: 4)
      else {
        ScrcpyStreamPlugin.streamLog("Attempt \(attempt): Connected but header not ready yet, retrying...")
        Darwin.close(sock)
        self.streamSocket = -1
        sock = -1
        usleep(400_000)
        continue
      }

      let devName = String(data: devNameData, encoding: .utf8)?.replacingOccurrences(of: "\0", with: "") ?? "Android"
      let codecStr = String(data: codecData, encoding: .ascii) ?? "unknown"
      let w = widthData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
      let h = heightData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
      self.videoWidth = Int(w)
      self.videoHeight = Int(h)

      ScrcpyStreamPlugin.streamLog(
        "Attempt \(attempt): Header OK! dev=\(devName), codec=\(codecStr), resolution=\(videoWidth)x\(videoHeight), dummy=\(dummy[0])"
      )
      headerReceived = true
      break
    }

    guard headerReceived && sock >= 0 else {
      ScrcpyStreamPlugin.streamLog("Failed to establish video stream and read header after retries")
      if isStreaming { stats.setState(.failed) }
      return
    }
    stats.setState(.streaming)

    // 2. Read Packets Loop (8 bytes PTS, 4 bytes packet size, <size> bytes NALUs)
    var packetIndex = 0
    while isStreaming {
      guard let ptsData = readExact(socket: sock, count: 8) else { break }
      let pts = ptsData.withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
      let isConfig = (pts & 0x8000_0000_0000_0000) != 0
      let isKeyFrame = (pts & 0x4000_0000_0000_0000) != 0

      guard let sizeData = readExact(socket: sock, count: 4) else { break }
      let packetSize = Int(
        sizeData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian })

      guard packetSize > 0, let packetData = readExact(socket: sock, count: packetSize) else {
        break
      }
      let receivedAt = DispatchTime.now().uptimeNanoseconds
      stats.addBytes(ptsData.count + sizeData.count + packetSize)

      packetIndex += 1
      if packetIndex <= 5 || packetIndex % 60 == 0 {
        ScrcpyStreamPlugin.streamLog(
          "Packet #\(packetIndex): size=\(packetSize), isConfig=\(isConfig), isKey=\(isKeyFrame)"
        )
      }

      if isConfig {
        parseConfigPacket(packetData)
      } else {
        processVideoFrame(packetData, receivedAt: receivedAt)
      }
    }

    ScrcpyStreamPlugin.streamLog("Stream loop terminated.")
    // The loop only exits on its own when the device closes the stream.
    if isStreaming { stats.setState(.ended) }
    if streamSocket >= 0 {
      Darwin.close(streamSocket)
      streamSocket = -1
    }
  }

  private func readExact(socket: Int32, count: Int) -> Data? {
    var data = Data(count: count)
    var totalRead = 0
    while totalRead < count && isStreaming {
      let bytesToRead = count - totalRead
      let bytesRead = data.withUnsafeMutableBytes { ptr -> Int in
        guard let base = ptr.baseAddress else { return -1 }
        return Darwin.recv(
          socket, base.advanced(by: totalRead), bytesToRead, 0)
      }
      if bytesRead < 0 {
        let err = errno
        if err == EAGAIN || err == EWOULDBLOCK || err == EINTR {
          continue
        }
        ScrcpyStreamPlugin.streamLog("readExact error: errno=\(err)")
        return nil
      } else if bytesRead == 0 {
        ScrcpyStreamPlugin.streamLog("readExact EOF: socket closed by peer")
        return nil
      }
      totalRead += bytesRead
    }
    return totalRead == count ? data : nil
  }

  private func parseConfigPacket(_ data: Data) {
    let nalus = splitAnnexBNalus(data)
    for nalu in nalus {
      guard !nalu.isEmpty else { continue }
      let naluType = nalu[0] & 0x1F
      if naluType == 7 {
        self.spsData = nalu
      } else if naluType == 8 {
        self.ppsData = nalu
      }
    }

    if let sps = spsData, let pps = ppsData {
      initDecompressionSession(sps: sps, pps: pps)
    }
  }

  private func initDecompressionSession(sps: Data, pps: Data) {
    if decompressionSession != nil && activeSps == sps && activePps == pps {
      return
    }
    self.activeSps = sps
    self.activePps = pps

    ScrcpyStreamPlugin.streamLog("Initializing VideoToolbox decompression session (SPS: \(sps.count), PPS: \(pps.count))...")
    let spsBytes = [UInt8](sps)
    let ppsBytes = [UInt8](pps)
    spsBytes.withUnsafeBufferPointer { spsBuf in
      ppsBytes.withUnsafeBufferPointer { ppsBuf in
        guard
          let spsBase = spsBuf.baseAddress,
          let ppsBase = ppsBuf.baseAddress
        else { return }

        let parameterSetPointers = [spsBase, ppsBase]
        let parameterSetSizes = [sps.count, pps.count]

        var formatDesc: CMFormatDescription?
        let status = CMVideoFormatDescriptionCreateFromH264ParameterSets(
          allocator: kCFAllocatorDefault,
          parameterSetCount: 2,
          parameterSetPointers: parameterSetPointers,
          parameterSetSizes: parameterSetSizes,
          nalUnitHeaderLength: 4,
          formatDescriptionOut: &formatDesc
        )

        guard status == noErr, let format = formatDesc else {
          ScrcpyStreamPlugin.streamLog("CMVideoFormatDescriptionCreate failed: \(status)")
          return
        }

        self.formatDescription = format

        if let oldSession = self.decompressionSession {
          VTDecompressionSessionInvalidate(oldSession)
          self.decompressionSession = nil
        }

        var callbackRecord = VTDecompressionOutputCallbackRecord(
          decompressionOutputCallback: {
            outputRefCon, sourceFrameRefCon, status, infoFlags, imageBuffer,
            presentationTimeStamp, duration in
            guard status == noErr, let imageBuffer = imageBuffer else { return }
            let plugin = Unmanaged<ScrcpyStreamPlugin>.fromOpaque(outputRefCon!)
              .takeUnretainedValue()
            // The frame refcon carries the packet receive time (see processVideoFrame).
            let receivedAt = UInt64(UInt(bitPattern: sourceFrameRefCon))
            plugin.onPixelBufferAvailable(imageBuffer, receivedAt: receivedAt)
          },
          decompressionOutputRefCon: Unmanaged.passUnretained(self).toOpaque()
        )

        // Metal-compatible IOSurface backed attributes
        let destinationImageBufferAttributes: [String: Any] = [
          kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
          kCVPixelBufferMetalCompatibilityKey as String: true,
          kCVPixelBufferIOSurfacePropertiesKey as String: [:] as [String: Any]
        ]

        var newSession: VTDecompressionSession?
        let createStatus = VTDecompressionSessionCreate(
          allocator: kCFAllocatorDefault,
          formatDescription: format,
          decoderSpecification: nil,
          imageBufferAttributes: destinationImageBufferAttributes as CFDictionary,
          outputCallback: &callbackRecord,
          decompressionSessionOut: &newSession
        )

        if createStatus == noErr {
          self.decompressionSession = newSession
          ScrcpyStreamPlugin.streamLog("VTDecompressionSession hardware decoder initialized successfully!")
        } else {
          ScrcpyStreamPlugin.streamLog("VTDecompressionSessionCreate failed: \(createStatus)")
        }
      }
    }
  }

  private func processVideoFrame(_ data: Data, receivedAt: UInt64) {
    let nalus = splitAnnexBNalus(data)
    guard !nalus.isEmpty else { return }

    for nalu in nalus {
      guard !nalu.isEmpty else { continue }
      let type = nalu[0] & 0x1F
      if type == 7 {
        self.spsData = nalu
      } else if type == 8 {
        self.ppsData = nalu
      }
    }

    if decompressionSession == nil, let sps = spsData, let pps = ppsData {
      initDecompressionSession(sps: sps, pps: pps)
    }

    guard let session = decompressionSession else { return }

    // Convert Annex B (00 00 00 01) to AVCC length-prefixed format
    var avccData = Data()
    for nalu in nalus {
      guard !nalu.isEmpty else { continue }
      let type = nalu[0] & 0x1F
      if type == 7 || type == 8 {
        // Skip SPS and PPS from the sample buffer payload (already in CMFormatDescription)
        continue
      }
      var lenBE = UInt32(nalu.count).bigEndian
      avccData.append(
        contentsOf: withUnsafeBytes(of: &lenBE) { Array($0) })
      avccData.append(nalu)
    }

    guard !avccData.isEmpty else { return }

    var blockBuffer: CMBlockBuffer?
    let bbStatus = CMBlockBufferCreateWithMemoryBlock(
      allocator: kCFAllocatorDefault,
      memoryBlock: nil,
      blockLength: avccData.count,
      blockAllocator: kCFAllocatorDefault,
      customBlockSource: nil,
      offsetToData: 0,
      dataLength: avccData.count,
      flags: 0,
      blockBufferOut: &blockBuffer
    )

    guard bbStatus == noErr, let bb = blockBuffer else { return }

    avccData.withUnsafeBytes { ptr in
      if let base = ptr.baseAddress {
        CMBlockBufferReplaceDataBytes(
          with: base,
          blockBuffer: bb,
          offsetIntoDestination: 0,
          dataLength: avccData.count
        )
      }
    }

    var sampleBuffer: CMSampleBuffer?
    var sampleTiming = CMSampleTimingInfo(
      duration: CMTime.invalid,
      presentationTimeStamp: CMTime.invalid,
      decodeTimeStamp: CMTime.invalid
    )

    let sbStatus = CMSampleBufferCreate(
      allocator: kCFAllocatorDefault,
      dataBuffer: bb,
      dataReady: true,
      makeDataReadyCallback: nil,
      refcon: nil,
      formatDescription: formatDescription,
      sampleCount: 1,
      sampleTimingEntryCount: 1,
      sampleTimingArray: &sampleTiming,
      sampleSizeEntryCount: 1,
      sampleSizeArray: [avccData.count],
      sampleBufferOut: &sampleBuffer
    )

    guard sbStatus == noErr, let sb = sampleBuffer else { return }

    var flagsOut: VTDecodeInfoFlags = []
    VTDecompressionSessionDecodeFrame(
      session,
      sampleBuffer: sb,
      flags: [._EnableAsynchronousDecompression],
      // Returned unchanged to the output callback to measure processing time.
      frameRefcon: UnsafeMutableRawPointer(bitPattern: UInt(receivedAt)),
      infoFlagsOut: &flagsOut
    )
  }

  fileprivate func onPixelBufferAvailable(_ pixelBuffer: CVImageBuffer, receivedAt: UInt64) {
    let format = CVPixelBufferGetPixelFormatType(pixelBuffer)
    if format == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange ||
       format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
      CVBufferSetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, kCVImageBufferYCbCrMatrix_ITU_R_709_2, .shouldPropagate)
      CVBufferSetAttachment(pixelBuffer, kCVImageBufferColorPrimariesKey, kCVImageBufferColorPrimaries_ITU_R_709_2, .shouldPropagate)
      CVBufferSetAttachment(pixelBuffer, kCVImageBufferTransferFunctionKey, kCVImageBufferTransferFunction_ITU_R_709_2, .shouldPropagate)
    }

    decodedFrameCount += 1
    if decodedFrameCount <= 3 || decodedFrameCount % 60 == 0 {
      let fStr = String(format: "%c%c%c%c", (format >> 24) & 0xff, (format >> 16) & 0xff, (format >> 8) & 0xff, format & 0xff)
      ScrcpyStreamPlugin.streamLog("Decoded frame #\(decodedFrameCount): format=\(fStr) (0x\(String(format, radix: 16)))")
    }

    pixelBufferLock.lock()
    currentPixelBuffer = pixelBuffer
    pixelBufferLock.unlock()
    stats.recordFrame(receivedAtNs: receivedAt)

    if let id = self.textureId {
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.textureRegistry?.textureFrameAvailable(id)
      }
    }
  }

  private func splitAnnexBNalus(_ data: Data) -> [Data] {
    var nalus: [Data] = []
    let bytes = [UInt8](data)
    let len = bytes.count
    if len < 4 { return nalus }

    var startIndices: [(index: Int, headerLen: Int)] = []
    var i = 0
    while i < len - 2 {
      if bytes[i] == 0 && bytes[i + 1] == 0 {
        if bytes[i + 2] == 1 {
          startIndices.append((index: i, headerLen: 3))
          i += 3
          continue
        } else if i < len - 3 && bytes[i + 2] == 0 && bytes[i + 3] == 1 {
          startIndices.append((index: i, headerLen: 4))
          i += 4
          continue
        }
      }
      i += 1
    }

    for idx in 0..<startIndices.count {
      let current = startIndices[idx]
      let naluStart = current.index + current.headerLen
      let naluEnd =
        (idx + 1 < startIndices.count) ? startIndices[idx + 1].index : len
      if naluEnd > naluStart {
        nalus.append(data.subdata(in: naluStart..<naluEnd))
      }
    }
    return nalus
  }
}
