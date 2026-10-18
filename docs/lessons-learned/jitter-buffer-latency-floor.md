# Audio Latency Settled at 160 ms Under a 200 ms Cap

## 1. Context & Symptoms

The first jitter buffer policy primed 50 ms, filled silence on underrun, and dropped audio only above 200 ms. On an Android 16 emulator, playback was smooth, but the buffer sat at about 160 ms for the whole run: audio lagged the video by far more than the 50 ms target.

## 2. Diagnostic Traces & Evidence

`scripts/check_macos_audio.sh emulator-5590 20` (now `scripts/check_macos_native.sh emulator-5590 audio 20`) printed the buffer once per second:

```text
bufferedFrames=6628 ... 8369 ... 7910 ... 7805 ... 7499   (≈ 140–175 ms)
droppedFrames=7840 (start-up only), underruns=0
```

The level depended on how full the buffer happened to be after start-up, not on the target.

## 3. Root Cause Analysis

A cap limits the worst case but does not pull latency back down. When audio arrives in bursts, the buffer level swings, and any level between the target and the cap is stable: input and output run at the same rate, so nothing moves it. Only an underrun (which resets to the target) or an overflow (which trims to the target) changed it.

## 4. Architectural Solution

`PcmJitterBuffer` tracks the **minimum** fill level over each one-second window of reads. The minimum is the part that is always there, so it is real extra latency, not jitter. If even the minimum is more than 20 ms above the target, the excess is dropped once, and the window restarts; an underrun also restarts it. Tests cover a steady excess (trimmed back to 50 frames) and bursty arrival whose minimum stays near the target (nothing dropped). After the change, the same 20-second run stayed between 0 and 95 ms.

Resampling to correct clock drift smoothly (as scrcpy's own client does) remains a possible follow-up.

## 5. Prevention & Reusability Checklist

- [ ] A latency bound needs a force back toward the target, not only a cap.
- [ ] Decide on excess latency from the minimum level over a window, never from one sample, so jitter is not mistaken for latency.
- [ ] Measure buffer level over a long run (20 s or more); short runs show only the start-up phase.
- [ ] Count every drop and underrun in the stats, so the policy can be judged from numbers.
