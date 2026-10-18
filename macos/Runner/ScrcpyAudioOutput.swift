import AVFoundation

/// Plays the scrcpy jitter buffer on the default output device.
///
/// `AVAudioSourceNode` pulls planar float frames from scrcpy_core on the
/// audio render thread; the main mixer converts to the device rate. When the
/// output device changes (for example AirPods connect), the engine stops
/// itself, so it is restarted.
final class ScrcpyAudioOutput {
  private let engine = AVAudioEngine()
  private let buffer: OpaquePointer
  private var sourceNode: AVAudioSourceNode?
  private var configurationObserver: NSObjectProtocol?

  init(buffer: OpaquePointer) {
    self.buffer = buffer
  }

  /// Starts playback; returns `false` when the output cannot start.
  func start() -> Bool {
    guard
      let format = AVAudioFormat(
        standardFormatWithSampleRate: Double(sc_audio_sample_rate()),
        channels: AVAudioChannelCount(sc_audio_channels()))
    else { return false }

    let buffer = self.buffer
    let channelCount = Int(sc_audio_channels())
    // Runs on the real-time render thread: no heap allocation, no locks
    // other than the jitter buffer's short copy.
    let node = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList in
      let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
      let count = min(buffers.count, channelCount)
      withUnsafeTemporaryAllocation(
        of: UnsafeMutablePointer<Float>?.self, capacity: channelCount
      ) { planar in
        for index in 0..<channelCount {
          planar[index] =
            index < count ? buffers[index].mData?.assumingMemoryBound(to: Float.self) : nil
        }
        sc_audio_buffer_read_planar(
          buffer, UnsafePointer(planar.baseAddress), count, Int(frameCount))
      }
      return noErr
    }
    engine.attach(node)
    engine.connect(node, to: engine.mainMixerNode, format: format)
    sourceNode = node

    configurationObserver = NotificationCenter.default.addObserver(
      forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
    ) { [weak self] _ in
      self?.restartAfterDeviceChange()
    }
    return startEngine()
  }

  func stop() {
    if let observer = configurationObserver {
      NotificationCenter.default.removeObserver(observer)
      configurationObserver = nil
    }
    engine.stop()
    if let node = sourceNode {
      engine.detach(node)
      sourceNode = nil
    }
  }

  private func startEngine() -> Bool {
    engine.prepare()
    do {
      try engine.start()
      return true
    } catch {
      ScrcpyLog.write("[audio] Output failed to start: \(error)")
      return false
    }
  }

  private func restartAfterDeviceChange() {
    guard sourceNode != nil, !engine.isRunning else { return }
    ScrcpyLog.write("[audio] Output device changed; restarting")
    _ = startEngine()
  }
}
