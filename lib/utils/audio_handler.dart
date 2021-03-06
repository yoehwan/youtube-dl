import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

Future<YoutubeAudioHandler> initAudioHandler() async {
  return await AudioService.init(
    builder: () => YoutubeAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.youtube_dl.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class YoutubeAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  bool get isPlaying => _player.playing;

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        repeatMode: const {
          LoopMode.off: AudioServiceRepeatMode.none,
          LoopMode.one: AudioServiceRepeatMode.one,
          LoopMode.all: AudioServiceRepeatMode.all,
        }[_player.loopMode]!,
        shuffleMode: (_player.shuffleModeEnabled)
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      var index = _player.currentIndex;
      final newQueue = queue.value;
      if (index == null || newQueue.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices![index];
      }
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }

  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices![index];
      }
      mediaItem.add(playlist[index]);
    });
  }

  @override
  Future<void> prepare() async {
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForCurrentSongIndexChanges();
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Stream<Duration> get positionStream => _player.createPositionStream();

  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    queue.add(mediaItems);
    await _player.setAudioSource(
      ConcatenatingAudioSource(
        children:
            mediaItems.map((e) => AudioSource.uri(Uri.file(e.id))).toList(),
      ),
      initialIndex: 0,
      initialPosition: Duration.zero,
    );
    return super.addQueueItems(mediaItems);
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    await _player.setFilePath(mediaItem.id);
    return super.playMediaItem(mediaItem);
  }

  @override
  Future<void> prepareFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async{
    await _player.setFilePath(mediaId);
    return super.prepareFromMediaId(mediaId);
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    await stop();
    queue.add([mediaItem]);
  }


  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    if (!_player.playing) return;
    _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    LoopMode _mode;
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        _mode = LoopMode.off;
        break;
      case AudioServiceRepeatMode.one:
        _mode = LoopMode.one;
        break;
      case AudioServiceRepeatMode.all:
        _mode = LoopMode.all;
        break;
      case AudioServiceRepeatMode.group:
        _mode = LoopMode.off;
        break;
    }
    await _player.setLoopMode(_mode);
    return super.setRepeatMode(repeatMode);
  }
}
