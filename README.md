# ⚡️ WifiDesk

<p align="center">
  <b>Silky-smooth, zero-latency Android screen mirroring and remote control for macOS over local Wi-Fi.</b>
</p>

<p align="center">
  <a href="https://github.com/az-coder-123/wifi-desk/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/built%20with-Flutter-02569B.svg?logo=flutter" alt="Built with Flutter"></a>
  <a href="https://github.com/az-coder-123/wifi-desk/releases"><img src="https://img.shields.io/badge/platform-macOS%20%7C%20Android-black.svg?logo=apple" alt="Platforms"></a>
  <a href="https://github.com/az-coder-123/wifi-desk/pulls"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs Welcome"></a>
</p>

---

## 📖 Giới thiệu (Overview)

**WifiDesk** là một ứng dụng máy tính mã nguồn mở (Open Source) được xây dựng bằng **Flutter Desktop** dành cho hệ điều hành **macOS**. 

Ứng dụng cho phép người dùng **trình chiếu màn hình điện thoại Android lên máy Mac và tương tác điều khiển bằng chuột, bàn phím hoàn toàn không dây qua mạng Wi-Fi nội bộ** với độ trễ cực thấp (< 30ms) và chất lượng hình ảnh lên tới 60–120 FPS.

WifiDesk kết hợp giữa:
1. **Sức mạnh và độ mượt** của engine `scrcpy-server` (chuẩn mực nén H.264/H.265 bằng phần cứng).
2. **Giao diện hiện đại, thanh lịch** theo chuẩn phong cách macOS (Apple-native aesthetic) được tạo bởi Flutter.

---

## ✨ Điểm nổi bật (Key Highlights)

- 🚀 **Độ trễ siêu thấp (< 30ms):** Sử dụng nén phần cứng GPU trực tiếp từ thiết bị Android, stream qua socket nội mạng không giật lag.
- 📶 **Kết nối không dây 1 chạm (Zero-Config Wi-Fi):** Tự động dò tìm IP thiết bị qua mDNS, ghép nối nhanh qua mã PIN hoặc mã QR của Android 11+ Wireless Debugging.
- 🖱️ **Điều khiển toàn diện:** Dùng chuột Mac để chạm, vuốt, cuộn; dùng bàn phím Mac để gõ văn bản tiếng Việt/Anh trực tiếp.
- 🍎 **Trải nghiệm Mac-First:**
  - **Shared Clipboard:** Copy trên Mac (`Cmd + C`), dán ngay trên điện thoại (`Paste`) và ngược lại.
  - **Drag & Drop:** Kéo thả file ảnh, video hoặc file APK từ Finder vào cửa sổ để chuyển file hoặc cài app.
  - **Screen-Off Streaming:** Tự động tắt màn hình điện thoại trong lúc chiếu để tiết kiệm pin và tránh nóng máy.
  - **Menu Bar Companion:** Thu nhỏ vào thanh Menu Bar để mở nhanh chỉ với 1 click.
- 🔒 **100% Riêng tư & Bảo mật:** Dữ liệu truyền trực tiếp Peer-to-Peer qua Wi-Fi nội bộ, không phụ thuộc vào Internet hay bất kỳ máy chủ đám mây nào.
- 💸 **Miễn phí & Mã nguồn mở:** Không có quảng cáo, không thu phí thuê bao định kỳ.

👉 *Xem chi tiết toàn bộ tính năng và đặc tả kỹ thuật tại [docs/features.md](docs/features.md).*

---

## 🏗️ Kiến trúc hệ thống (Architecture)

```mermaid
flowchart LR
    subgraph AndroidDevice ["📱 Thiết bị Android"]
        A1["SurfaceControl / Camera API"] --> A2["MediaCodec (H.264 / H.265 GPU)"]
        A2 --> A3["scrcpy-server (Quyền Shell ngầm)"]
        A4["InputManager (Touch / Key Injection)"] <--- A3
    end

    subgraph LocalNetwork ["📶 Mạng Wi-Fi nội bộ (LAN)"]
        V_STREAM["TCP Video Stream (NAL Units)"]
        C_SOCKET["TCP / UDP Control Events (Input Packets)"]
    end

    subgraph MacApp ["💻 macOS (WifiDesk App - Flutter)"]
        M1["Flutter UI & Menu Bar"] --> M2["Mouse / Keyboard Event Listener"]
        M3["Hardware Video Decoder (Texture Registry)"] --> M1
    end

    A3 === V_STREAM ===> M3
    M2 === C_SOCKET ===> A3
```

---

## 🛠️ Công nghệ sử dụng (Tech Stack)

- **Giao diện (Frontend):** [Flutter Desktop](https://flutter.dev) (Dart) cho macOS.
- **Engine Stream & Input:** `scrcpy-server` (Java/C++ qua ADB Shell).
- **Giao thức mạng:** TCP/UDP Socket nội mạng, mDNS / Bonjour (Device Discovery).
- **Giải mã Video:** Hardware Acceleration via macOS VideoToolbox / Texture Widget.

---

## 🚀 Bắt đầu phát triển (Getting Started)

### 1. Yêu cầu hệ thống (Prerequisites)
- **macOS:** macOS 12 Monterey trở lên.
- **Flutter SDK:** Flutter 3.x+ (hỗ trợ macOS desktop).
- **Android Device:** Android 5.0+ (khuyên dùng Android 11+ để có tính năng Wireless Debugging không cần cắm cáp lần đầu).
- **Android Platform Tools (ADB):** Cài đặt qua Homebrew:
  ```bash
  brew install android-platform-tools
  ```

### 2. Cài đặt & Chạy ứng dụng

```bash
# 1. Clone repository
git clone https://github.com/az-coder-123/wifi-desk.git
cd wifi-desk

# 2. Cài đặt các gói phụ thuộc Flutter
flutter pub get

# 3. Chạy ứng dụng trên macOS
flutter run -d macos
```

---

## 🗺️ Lộ trình phát triển (Roadmap)

- [x] Khởi tạo cấu trúc dự án Flutter Desktop (macOS)
- [x] Đặc tả kiến trúc và tài liệu chức năng dự án
- [ ] Xây dựng mô-đun kết nối ADB Wireless & Dò tìm thiết bị qua mDNS
- [ ] Tích hợp stream video 60 FPS qua `scrcpy-server` và Flutter Texture
- [ ] Hoàn thiện bộ bắt sự kiện chuột & bàn phím
- [ ] Đồng bộ Clipboard hai chiều và Kéo thả tập tin
- [ ] Tích hợp Menu Bar macOS và Audio Forwarding

---

## 🤝 Đóng góp (Contributing)

Mọi đóng góp từ cộng đồng đều được hoan nghênh! Vui lòng thực hiện theo các bước:

1. Fork dự án này.
2. Tạo nhánh tính năng của bạn: `git checkout -b feature/AmazingFeature`.
3. Cam kết thay đổi: `git commit -m 'Add some AmazingFeature'`.
4. Đẩy lên nhánh của bạn: `git push origin feature/AmazingFeature`.
5. Tạo một **Pull Request**.

---

## 📄 Giấy phép (License)

Dự án được phân phối dưới giấy phép **MIT License**. Xem chi tiết tại [LICENSE](LICENSE).

<p align="center">
  Phát triển với ❤️ bởi <b><a href="https://github.com/az-coder-123">az-coder-123</a></b>
</p>
