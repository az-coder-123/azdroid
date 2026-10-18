import Foundation

/// Plays the device audio with the app's ScrcpyAudioSession, opened the way
/// the app does: after the video session reports "connected".
/// Returns nil when the device cannot capture audio (Android 10 or older).
func runAudioCheck(seconds: Int) -> Bool? {
  let video = ScrcpyVideoSession(host: "127.0.0.1", port: DeviceServer.localPort) { _ in }
  video.start()
  defer { video.stop() }
  let deadline = Date().addingTimeInterval(15)
  while video.stats.snapshot()["state"] as? String != "connected" {
    guard Date() < deadline else {
      print("video socket not accepted")
      return false
    }
    Thread.sleep(forTimeInterval: 0.05)
  }
  guard let audioSocket = ScrcpySocket.connect(host: "127.0.0.1", port: DeviceServer.localPort)
  else {
    print("audio socket did not connect")
    return false
  }
  let buffer = sc_audio_buffer_create()!
  defer { sc_audio_buffer_destroy(buffer) }
  let session = ScrcpyAudioSession(socket: audioSocket, buffer: buffer)
  session.start()

  let started = Date()
  var last: [String: Any] = [:]
  for _ in 0..<seconds {
    Thread.sleep(forTimeInterval: 1)
    last = session.stats.snapshot(buffer: sc_audio_buffer_stats(buffer))
    print(last.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: " "))
  }
  let elapsed = Date().timeIntervalSince(started)
  session.stop()

  let state = last["state"] as? String ?? "?"
  if state == "disabled" { return nil }
  let played = last["playedFrames"] as? Int ?? 0
  let bufferedMs = (last["bufferedFrames"] as? Int ?? 0) * 1000 / 48000
  // After ~1 s of start-up, playback should keep up with real time.
  let expected = Int((elapsed - 1.5) * 48000) * 8 / 10
  print("played=\(played) (expected >= \(expected)) buffered=\(bufferedMs) ms")
  return state == "playing" && played >= expected && bufferedMs <= 200
}
