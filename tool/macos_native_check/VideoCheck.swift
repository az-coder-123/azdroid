import CoreVideo
import Foundation

/// Runs the app's ScrcpyVideoSession and H.264 decoder against the device:
/// frames must be decoded with a real size, and none may arrive after stop.
func runVideoCheck(server: DeviceServer, seconds: Int) -> Bool {
  let lock = NSLock()
  var frames = 0
  var lastFrameSize = (0, 0)
  let session = ScrcpyVideoSession(host: "127.0.0.1", port: DeviceServer.localPort) { frame in
    lock.lock()
    frames += 1
    lastFrameSize = (CVPixelBufferGetWidth(frame), CVPixelBufferGetHeight(frame))
    lock.unlock()
  }
  session.start()
  for second in 1...seconds {
    Thread.sleep(forTimeInterval: 1)
    if second == 1 { server.changeScreen() }
    let stats = session.stats.snapshot()
    let size = session.videoSize()
    print("state=\(stats["state"] ?? "?") framesDecoded=\(stats["framesDecoded"] ?? 0) size=\(size.width)x\(size.height)")
  }
  let state = session.stats.snapshot()["state"] as? String ?? "?"
  let size = session.videoSize()

  session.stop()
  lock.lock()
  let framesAtStop = frames
  let decodedSize = lastFrameSize
  lock.unlock()
  Thread.sleep(forTimeInterval: 1.5)
  lock.lock()
  let framesAfterStop = frames - framesAtStop
  lock.unlock()
  let stoppedState = session.stats.snapshot()["state"] as? String ?? "?"

  print("decoded frame size=\(decodedSize.0)x\(decodedSize.1), frames after stop=\(framesAfterStop), state after stop=\(stoppedState)")
  return state == "streaming" && framesAtStop > 0 && size.width > 0
    && decodedSize.0 == size.width && framesAfterStop == 0 && stoppedState == "idle"
}
