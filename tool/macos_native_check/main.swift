// Command-line check of the macOS native players against a real device or
// emulator. It compiles the app's own classes from macos/Runner (sessions,
// decoder, audio output) with scrcpy_core. Build and run:
//   scripts/check_macos_native.sh <serial> <video|audio> [seconds]
import Foundation

let args = CommandLine.arguments
guard args.count >= 5, ["video", "audio"].contains(args[4]) else {
  print("usage: macos_native_check <adb> <serial> <jar> <video|audio> [seconds]")
  exit(64)
}
let mode = args[4]
let seconds = args.count > 5 ? Int(args[5]) ?? 6 : 6
let server = DeviceServer(adb: args[1], serial: args[2])
do {
  try server.start(jar: args[3], audio: mode == "audio")
} catch {
  print("RESULT: FAILED (server did not start: \(error))")
  exit(1)
}
defer { server.stop() }

let result: Bool?
if mode == "video" {
  result = runVideoCheck(server: server, seconds: seconds)
} else {
  result = runAudioCheck(seconds: seconds)
}
switch result {
case nil:
  print("RESULT: DISABLED (device cannot capture audio: Android 10 or older)")
case true?:
  print("RESULT: OK")
case false?:
  print("RESULT: FAILED")
}
server.stop()
exit(result == false ? 1 : 0)
