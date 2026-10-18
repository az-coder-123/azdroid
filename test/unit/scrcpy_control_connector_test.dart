import 'package:desk_droid/core/models/native_stream_stats.dart';
import 'package:desk_droid/core/services/scrcpy_control_channel.dart';
import 'package:desk_droid/core/services/video_stream_native_service.dart';
import 'package:desk_droid/features/streaming/data/services/scrcpy_control_connector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNativeService extends Mock implements IVideoStreamNativeService {}

class MockControlChannel extends Mock implements ScrcpyControlChannel {}

void main() {
  late MockNativeService native;
  late MockControlChannel channel;
  late ScrcpyControlConnector connector;

  setUp(() {
    native = MockNativeService();
    channel = MockControlChannel();
    connector = ScrcpyControlConnector(
      nativeService: native,
      channel: channel,
      pollInterval: const Duration(milliseconds: 1),
      timeout: const Duration(milliseconds: 200),
    );
    when(
      () => channel.connect(
        deviceSerial: any(named: 'deviceSerial'),
        port: any(named: 'port'),
      ),
    ).thenAnswer((_) async => true);
  });

  void reportStates(List<NativeStreamState> states) {
    final queue = [...states];
    when(() => native.getStats()).thenAnswer((_) async {
      final state = queue.length > 1 ? queue.removeAt(0) : queue.first;
      return NativeStreamStats(state: state);
    });
  }

  test('connects control only once the video socket is accepted', () async {
    reportStates([
      NativeStreamState.idle,
      NativeStreamState.connecting,
      NativeStreamState.connecting,
      NativeStreamState.connected,
    ]);

    expect(await connector.connect(deviceSerial: 'd', port: 27183), isTrue);
    verify(() => native.getStats()).called(4);
    verify(() => channel.connect(deviceSerial: 'd', port: 27183)).called(1);
  });

  test('never connects while the server has not accepted video', () async {
    reportStates([NativeStreamState.connecting]);

    expect(await connector.connect(deviceSerial: 'd', port: 27183), isFalse);
    verifyNever(
      () => channel.connect(
        deviceSerial: any(named: 'deviceSerial'),
        port: any(named: 'port'),
      ),
    );
  });

  test('gives up as soon as the stream fails', () async {
    reportStates([NativeStreamState.connecting, NativeStreamState.failed]);

    expect(await connector.connect(deviceSerial: 'd', port: 27183), isFalse);
    verify(() => native.getStats()).called(2);
  });

  test('disconnect closes the channel', () async {
    when(() => channel.close()).thenAnswer((_) async {});
    await connector.disconnect();
    verify(() => channel.close()).called(1);
  });
}
