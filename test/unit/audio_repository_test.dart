import 'package:desk_droid/core/constants/audio_constants.dart';
import 'package:desk_droid/core/constants/socket_config.dart';
import 'package:desk_droid/core/services/adb_port_forwarder.dart';
import 'package:desk_droid/features/audio/data/datasources/audio_socket_datasource.dart';
import 'package:desk_droid/features/audio/data/repositories/audio_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdbPortForwarder extends Mock implements AdbPortForwarder {}

class MockAudioSocketDatasource extends Mock implements AudioSocketDatasource {}

void main() {
  late MockAdbPortForwarder mockPortForwarder;
  late MockAudioSocketDatasource mockSocketDatasource;
  late AudioRepositoryImpl repository;

  const testSerial = '192.168.1.100:5555';

  setUp(() {
    mockPortForwarder = MockAdbPortForwarder();
    mockSocketDatasource = MockAudioSocketDatasource();
    repository = AudioRepositoryImpl(
      portForwarder: mockPortForwarder,
      socketDatasource: mockSocketDatasource,
    );
  });

  group('AudioRepositoryImpl', () {
    test('startAudioStream sets up port forward, connects socket, and returns active entity', () async {
      when(
        () => mockPortForwarder.setupPortForward(
          deviceSerial: testSerial,
          localPort: SocketConfig.defaultAudioStreamPort,
        ),
      ).thenAnswer((_) async => true);

      when(
        () => mockSocketDatasource.connect(
          port: SocketConfig.defaultAudioStreamPort,
        ),
      ).thenAnswer((_) async => true);

      final session = await repository.startAudioStream(testSerial);

      expect(session.deviceId, equals(testSerial));
      expect(session.isEnabled, isTrue);
      expect(session.sampleRate, equals(AudioConstants.defaultSampleRate));
      expect(session.channels, equals(AudioConstants.defaultChannels));

      verify(
        () => mockPortForwarder.setupPortForward(
          deviceSerial: testSerial,
          localPort: SocketConfig.defaultAudioStreamPort,
        ),
      ).called(1);
      verify(
        () => mockSocketDatasource.connect(
          port: SocketConfig.defaultAudioStreamPort,
        ),
      ).called(1);
    });

    test(
      'stopAudioStream disconnects socket and removes port forward',
      () async {
        when(() => mockSocketDatasource.disconnect()).thenAnswer((_) async {});
        when(
          () => mockPortForwarder.removePortForward(
            deviceSerial: testSerial,
            localPort: SocketConfig.defaultAudioStreamPort,
          ),
        ).thenAnswer((_) async => true);

        await repository.stopAudioStream(testSerial);

        verify(() => mockSocketDatasource.disconnect()).called(1);
        verify(
          () => mockPortForwarder.removePortForward(
            deviceSerial: testSerial,
            localPort: SocketConfig.defaultAudioStreamPort,
          ),
        ).called(1);
      },
    );

    test('toggleMute and setVolume update state correctly', () async {
      final isMuted = await repository.toggleMute();
      expect(isMuted, isTrue);

      final unmuted = await repository.toggleMute();
      expect(unmuted, isFalse);

      await repository.setVolume(0.75);
    });
  });
}
