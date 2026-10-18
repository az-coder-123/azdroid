// Command-line check of the macOS audio player against a real device: runs
// the app's own ScrcpySocket, ScrcpyAudioSession, and ScrcpyAudioOutput
// (compiled from macos/Runner) with scrcpy_core, and plays the device audio
// on this Mac. Build and run: scripts/check_macos_audio.sh <serial>
//
// The server runs with control=false, so only two sockets connect
// (video, then audio). Video is drained so the shared adb transport flows.
import Foundation

let args = CommandLine.arguments
guard args.count >= 4 else {
  print("usage: macos_audio_check <adb> <serial> <jar> [seconds]")
  exit(64)
}
let adb = args[1], serial = args[2], jar = args[3]
let seconds = args.count > 4 ? Int(args[4]) ?? 6 : 6
let scid = "7a5e000b", localPort = 27195
let remoteJar = "/data/local/tmp/deskdroid-audio-check.jar"

@discardableResult
func run(_ arguments: [String]) -> String {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: adb)
  process.arguments = ["-s", serial] + arguments
  let pipe = Pipe()
  process.standardOutput = pipe
  process.standardError = pipe
  try? process.run()
  process.waitUntilExit()
  return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
}

run(["push", jar, remoteJar])
let server = Process()
server.executableURL = URL(fileURLWithPath: adb)
server.arguments = [
  "-s", serial, "shell", "CLASSPATH=\(remoteJar)", "app_process", "/",
  "com.genymobile.scrcpy.Server", "3.3.4", "scid=\(scid)", "tunnel_forward=true",
  "control=false", "audio=true", "audio_codec=raw", "cleanup=true",
  "video_bit_rate=2000000",
]
server.standardOutput = FileHandle.nullDevice
server.standardError = FileHandle.nullDevice
try server.run()
defer {
  server.terminate()
  run(["forward", "--remove", "tcp:\(localPort)"])
  run(["shell", "rm -f \(remoteJar)"])
}
Thread.sleep(forTimeInterval: 2.5)
run(["forward", "tcp:\(localPort)", "localabstract:scrcpy_\(scid)"])

// 1. Video socket: the server sends one dummy byte once it accepted it.
var video: ScrcpySocket?
for _ in 0..<30 {
  if let s = ScrcpySocket.connect(host: "127.0.0.1", port: localPort),
    s.readExact(1, isRunning: { true }) != nil
  {
    video = s
    break
  }
  Thread.sleep(forTimeInterval: 0.3)
}
guard let video else {
  print("RESULT: FAILED (video socket not accepted)")
  exit(1)
}
var draining = true
Thread {
  while draining, video.readExact(65536 / 64, isRunning: { draining }) != nil {}
}.start()

// 2. Audio socket, played by the app's own session code.
guard let audioSocket = ScrcpySocket.connect(host: "127.0.0.1", port: localPort) else {
  print("RESULT: FAILED (audio socket did not connect)")
  exit(1)
}
let buffer = sc_audio_buffer_create()!
let session = ScrcpyAudioSession(socket: audioSocket, buffer: buffer)
session.start()

let started = Date()
var samples: [[String: Any]] = []
for _ in 0..<seconds {
  Thread.sleep(forTimeInterval: 1)
  let snapshot = session.stats.snapshot(buffer: sc_audio_buffer_stats(buffer))
  samples.append(snapshot)
  print(snapshot.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: " "))
}
let elapsed = Date().timeIntervalSince(started)
session.stop()
draining = false
sc_audio_buffer_destroy(buffer)

let last = samples.last ?? [:]
let state = last["state"] as? String ?? "?"
let played = last["playedFrames"] as? Int ?? 0
let underruns = last["underruns"] as? Int ?? 0
let bufferedMs = (last["bufferedFrames"] as? Int ?? 0) * 1000 / 48000
// After ~1 s of start-up, playback should keep up with real time.
let expected = Int((elapsed - 1.5) * 48000)
let keepsUp = played >= expected * 8 / 10
print("state=\(state) played=\(played) (expected >= \(expected * 8 / 10)) underruns=\(underruns) buffered=\(bufferedMs) ms")
if state == "disabled" {
  print("RESULT: DISABLED (device cannot capture audio: Android 10 or older)")
  exit(0)
}
let ok = state == "playing" && keepsUp && bufferedMs <= 200
print(ok ? "RESULT: OK" : "RESULT: FAILED")
exit(ok ? 0 : 1)
