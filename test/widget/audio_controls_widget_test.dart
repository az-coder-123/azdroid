import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/audio/domain/entities/audio_playback.dart';
import 'package:desk_droid/features/audio/domain/repositories/audio_repository.dart';
import 'package:desk_droid/features/audio/presentation/cubit/audio_cubit.dart';
import 'package:desk_droid/features/audio/presentation/cubit/audio_state.dart';
import 'package:desk_droid/features/audio/presentation/widgets/audio_controls_widget.dart';
import 'package:desk_droid/features/audio/presentation/widgets/audio_status_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAudioRepository extends Mock implements AudioRepository {}

void main() {
  late _MockAudioRepository repository;

  setUp(() {
    repository = _MockAudioRepository();
    when(() => repository.volume).thenReturn(1);
    when(() => repository.isMuted).thenReturn(false);
    when(() => repository.setMuted(any())).thenAnswer((_) async {});
  });

  Future<AudioCubit> pump(WidgetTester tester, AudioState state) async {
    final cubit = AudioCubit(repository: repository)..emit(state);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: BlocProvider<AudioCubit>.value(
            value: cubit,
            child: const AudioControlsWidget(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('playing audio opens the volume popup', (tester) async {
    await pump(
      tester,
      const AudioActive(
        playback: AudioPlayback(status: AudioPlaybackStatus.playing),
      ),
    );

    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Audio Volume'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('mute from the popup reaches the repository', (tester) async {
    await pump(
      tester,
      const AudioActive(
        playback: AudioPlayback(status: AudioPlaybackStatus.playing),
      ),
    );
    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mute Audio'));
    await tester.pumpAndSettle();

    verify(() => repository.setMuted(true)).called(1);
  });

  for (final status in AudioPlaybackStatus.values.where(
    (s) => s != AudioPlaybackStatus.playing,
  )) {
    testWidgets('$status shows a disabled button that explains why', (
      tester,
    ) async {
      await pump(tester, AudioActive(playback: AudioPlayback(status: status)));

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.onPressed, isNull);
      expect(button.tooltip, status.label);
    });
  }

  testWidgets('before the first sample, audio is shown as starting', (
    tester,
  ) async {
    await pump(tester, const AudioInitial());

    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.tooltip, AudioPlaybackStatus.starting.label);
  });
}
