import 'package:desk_droid/core/constants/android_key_codes.dart';
import 'package:desk_droid/features/control/data/datasources/control_datasource.dart';
import 'package:desk_droid/features/control/data/repositories/control_repository_impl.dart';
import 'package:desk_droid/features/control/domain/entities/input_event_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockControlDatasource extends Mock implements ControlDatasource {}

void main() {
  late MockControlDatasource mockDatasource;
  late ControlRepositoryImpl repository;

  const testSerial = '192.168.1.100:5555';

  setUp(() {
    mockDatasource = MockControlDatasource();
    repository = ControlRepositoryImpl(datasource: mockDatasource);
  });

  group('ControlRepositoryImpl', () {
    test('sendTap converts normalized coordinates to pixels and delegates to datasource', () async {
      when(() => mockDatasource.injectTap(testSerial, 540, 1200))
          .thenAnswer((_) async => true);

      final result = await repository.sendTap(
        testSerial,
        normalizedX: 0.5,
        normalizedY: 0.5,
        displayWidth: 1080,
        displayHeight: 2400,
      );

      expect(result, isTrue);
      verify(() => mockDatasource.injectTap(testSerial, 540, 1200)).called(1);
    });

    test('sendSwipe converts coordinates and calls injectSwipe', () async {
      when(
        () => mockDatasource.injectSwipe(testSerial, 108, 240, 540, 1200, 150),
      ).thenAnswer((_) async => true);

      final result = await repository.sendSwipe(
        testSerial,
        startX: 0.1,
        startY: 0.1,
        endX: 0.5,
        endY: 0.5,
        durationMs: 150,
        displayWidth: 1080,
        displayHeight: 2400,
      );

      expect(result, isTrue);
      verify(
        () => mockDatasource.injectSwipe(testSerial, 108, 240, 540, 1200, 150),
      ).called(1);
    });

    test('sendScroll converts wheel delta into swipe coordinates', () async {
      when(
        () => mockDatasource.injectSwipe(
          testSerial,
          any(),
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenAnswer((_) async => true);

      final result = await repository.sendScroll(
        testSerial,
        normalizedX: 0.5,
        normalizedY: 0.5,
        deltaX: 0.0,
        deltaY: 50.0,
        displayWidth: 1080,
        displayHeight: 2400,
      );

      expect(result, isTrue);
      verify(
        () => mockDatasource.injectSwipe(
          testSerial,
          540,
          1200,
          540,
          any(),
          any(),
        ),
      ).called(1);
    });

    test(
      'sendNavigationAction maps navigation actions to Android keycodes',
      () async {
        when(
          () => mockDatasource.injectKeyevent(
            testSerial,
            AndroidKeyCodes.keycodeBack,
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockDatasource.injectKeyevent(
            testSerial,
            AndroidKeyCodes.keycodeHome,
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockDatasource.injectKeyevent(
            testSerial,
            AndroidKeyCodes.keycodeAppSwitch,
          ),
        ).thenAnswer((_) async => true);

        expect(
          await repository.sendNavigationAction(
            testSerial,
            NavigationAction.back,
          ),
          isTrue,
        );
        expect(
          await repository.sendNavigationAction(
            testSerial,
            NavigationAction.home,
          ),
          isTrue,
        );
        expect(
          await repository.sendNavigationAction(
            testSerial,
            NavigationAction.appSwitch,
          ),
          isTrue,
        );

        verify(
          () => mockDatasource.injectKeyevent(
            testSerial,
            AndroidKeyCodes.keycodeBack,
          ),
        ).called(1);
        verify(
          () => mockDatasource.injectKeyevent(
            testSerial,
            AndroidKeyCodes.keycodeHome,
          ),
        ).called(1);
        verify(
          () => mockDatasource.injectKeyevent(
            testSerial,
            AndroidKeyCodes.keycodeAppSwitch,
          ),
        ).called(1);
      },
    );

    test('sendText delegates to datasource.injectText', () async {
      when(() => mockDatasource.injectText(testSerial, 'Xin chào'))
          .thenAnswer((_) async => true);

      final result = await repository.sendText(testSerial, 'Xin chào');

      expect(result, isTrue);
      verify(() => mockDatasource.injectText(testSerial, 'Xin chào')).called(1);
    });
  });
}
