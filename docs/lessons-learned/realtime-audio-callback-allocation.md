# Heap Allocation Inside the Real-Time Audio Callback

## 1. Context & Symptoms

The first `AVAudioSourceNode` render block in `ScrcpyAudioOutput.swift` built its channel pointer list with `buffers.compactMap { … }` on every call. It compiled and would have played, but it was caught in review before any device run.

## 2. Diagnostic Traces & Evidence

- The render block runs on Core Audio's real-time thread about every 10 ms (512 frames at 48 kHz).
- `compactMap` returns a new `Array`, which allocates on the heap. Heap allocation can take a lock inside the allocator and wait for another thread: the classic cause of audio dropouts that appear only under load.

## 3. Root Cause Analysis

Convenient Swift collection code hides allocations. The block's job (pass two channel pointers to C) needs no dynamic memory, but the idiomatic way to write it allocates.

## 4. Architectural Solution

- The block uses `withUnsafeTemporaryAllocation(of:capacity:)`, which uses stack memory for small sizes, fills the pointers in place, and calls `sc_audio_buffer_read_planar`.
- The only lock on that path is the jitter buffer's short copy; it allocates nothing after creation (scratch space is sized in the constructor).
- A comment at the top of the block states the rule. On Windows, the WASAPI render loop writes straight into the device buffer (`GetBuffer` / `ReleaseBuffer`) without allocating.

## 5. Prevention & Reusability Checklist

- [ ] No heap allocation, no I/O, no logging, and no waiting on locks held by slow code in an audio render callback.
- [ ] Watch for hidden allocations: `map`, `compactMap`, string interpolation, array literals, closures that capture new objects.
- [ ] Size every buffer the callback uses before playback starts.
- [ ] Review the render path separately from the rest of an audio change.
