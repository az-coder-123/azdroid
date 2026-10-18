import Foundation

/// H.264 Annex B helpers: scrcpy sends NAL units with `00 00 01` or
/// `00 00 00 01` start codes; VideoToolbox wants AVCC (4-byte lengths).
enum ScrcpyAnnexB {
  static let naluTypeSps: UInt8 = 7
  static let naluTypePps: UInt8 = 8
  private static let naluTypeMask: UInt8 = 0x1F

  /// NAL unit type from the first payload byte.
  static func type(of nalu: Data) -> UInt8 {
    nalu[nalu.startIndex] & naluTypeMask
  }

  static func isParameterSet(_ nalu: Data) -> Bool {
    let type = type(of: nalu)
    return type == naluTypeSps || type == naluTypePps
  }

  /// NAL unit payloads (start codes removed), in stream order.
  static func split(_ data: Data) -> [Data] {
    let bytes = [UInt8](data)
    let count = bytes.count
    guard count >= 4 else { return [] }

    var starts: [(index: Int, length: Int)] = []
    var i = 0
    while i < count - 2 {
      if bytes[i] == 0 && bytes[i + 1] == 0 {
        if bytes[i + 2] == 1 {
          starts.append((i, 3))
          i += 3
          continue
        } else if i < count - 3 && bytes[i + 2] == 0 && bytes[i + 3] == 1 {
          starts.append((i, 4))
          i += 4
          continue
        }
      }
      i += 1
    }

    var nalus: [Data] = []
    for (position, start) in starts.enumerated() {
      let begin = start.index + start.length
      let end = position + 1 < starts.count ? starts[position + 1].index : count
      if end > begin {
        nalus.append(Data(bytes[begin..<end]))
      }
    }
    return nalus
  }

  /// AVCC sample data: each NAL unit prefixed with its 4-byte big-endian
  /// length. SPS and PPS are skipped (they live in the format description).
  static func avccSample(from nalus: [Data]) -> Data {
    var sample = Data()
    for nalu in nalus where !nalu.isEmpty && !isParameterSet(nalu) {
      var length = UInt32(nalu.count).bigEndian
      withUnsafeBytes(of: &length) { sample.append(contentsOf: $0) }
      sample.append(nalu)
    }
    return sample
  }
}
