# Bloc Handlers Run Concurrently: Touch MOVE Could Overtake DOWN

## 1. Context & Symptoms

Live touch streams (trackpad drag, pinch) send a start, many moves, and an end through `ControlBloc`. The first version used a plain `on<ControlTouchStreamed>(handler)`. A unit test with a slow start (the frame-size lookup) showed the moves and the end finishing before the start: on the phone, a finger would lift before it touched down.

## 2. Diagnostic Traces & Evidence

With the default transformer, the call log of the repository was:

```text
start begin, move begin, move end, end begin, end end, start end
```

With a sequential transformer it is `start begin, start end, move begin, move end, end begin, end end`. The test fails without the transformer.

## 3. Root Cause Analysis

`Bloc.on` processes events **concurrently** by default: each event's handler starts as soon as the event arrives, and handlers that `await` interleave. That is fine for independent taps, but a touch stream is one ordered conversation with the device.

## 4. Architectural Solution

- `on<ControlTouchStreamed>(_onTouchStreamed, transformer: _sequential())`, where `_sequential` is `(events, mapper) => events.asyncExpand(mapper)` (the same idea as `bloc_concurrency`'s `sequential()`, without a new dependency).
- The repository reads the frame size once at the start of each stream, so moves need no native call and stay fast.
- Moves do not emit state, so 60–120 Hz streams do not rebuild the UI.

## 5. Prevention & Reusability Checklist

- [ ] Choose the transformer on purpose: sequential for ordered protocols (touch streams, uploads), droppable or restartable for searches.
- [ ] Test ordering with a deliberately slow first event; fast mocks hide concurrency.
- [ ] Cache per-gesture data at the gesture's start instead of fetching it per event.
