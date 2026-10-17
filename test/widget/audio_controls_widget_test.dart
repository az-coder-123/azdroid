import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/audio/domain/entities/audio_stream_entity.dart';
import 'package:desk_droid/features/audio/domain/repositories/audio_repository.dart';
import 'package:desk_droid/features/audio/presentation/cubit/audio_cubit.dart';
import 'package:desk_droid/features/audio/presentation/cubit/audio_state.dart';
import 'package:desk_droid/features/audio/presentation/widgets/audio_controls_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAudioRepository extends Mock implements AudioRepository {}

void main() {
  late MockAudioRepository mockRepository;

  const testStream = AudioStreamEntity(
    deviceId: '192.168.1.100:5555',
    isEnabled: true,
    volume: 1.0,
    isMuted: false,
  );

  setUp(() {
    mockRepository = MockAudioRepository();
    when(() => mockRepository.stopAudioStream(any())).thenAnswer((_) async {});
  });

  Widget createSubject(AudioCubit cubit) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: BlocProvider<AudioCubit>.value(
          value: cubit,
          child: const AudioControlsWidget(),
        ),
      ),
    );
  }

  testWidgets(
    'AudioControlsWidget renders active volume icon and opens popup slider',
    (WidgetTester tester) async {
      final cubit = AudioCubit(repository: mockRepository);
      cubit.emit(const AudioActive(audioStream: testStream));

      await tester.pumpWidget(createSubject(cubit));
      await tester.pumpAndSettle();

      expect(find.byType(AudioControlsWidget), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Audio Volume'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      await cubit.close();
    },
  );
}
