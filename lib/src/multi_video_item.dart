import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'multi_video_model.dart';

/// Stateful widget to fetch and then display video content.
/// ignore: must_be_immutable
class MultiVideoItem extends StatefulWidget {
  dynamic videoSource;
  int index;
  Function(VideoPlayerController controller) onInit;
  Function(int index) onDispose;
  VideoPlayerOptions? videoPlayerOptions;
  VideoSource sourceType;
  Future<ClosedCaptionFile>? closedCaptionFile;
  Map<String, String>? httpHeaders;
  VideoFormat? formatHint;
  String? package;
  Widget Function(
          BuildContext context, VideoPlayerController controller, int index)?
      itemBuilder;
  Widget Function(BuildContext context)? loadingBuilder;
  Widget Function(BuildContext context)? controlsBuilder;
  bool showControlsOverlay;
  bool showVideoProgressIndicator;
  bool show = true;

  MultiVideoItem({
    super.key,
    required this.videoSource,
    required this.index,
    required this.onInit,
    required this.onDispose,
    this.itemBuilder,
    this.loadingBuilder,
    this.controlsBuilder,
    this.videoPlayerOptions,
    this.closedCaptionFile,
    this.httpHeaders,
    this.formatHint,
    this.package,
    this.showControlsOverlay = true,
    this.showVideoProgressIndicator = true,
    required this.sourceType,
  });

  @override
  State<MultiVideoItem> createState() => _MultiVideoItemState();
}

class _MultiVideoItemState extends State<MultiVideoItem> {
  late VideoPlayerController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  /// initializes videos
  void _initializeVideo() {
    if (widget.sourceType == VideoSource.network) {
      _controller = VideoPlayerController.networkUrl(
        widget.videoSource,
        videoPlayerOptions: widget.videoPlayerOptions,
        closedCaptionFile: widget.closedCaptionFile,
        httpHeaders: widget.httpHeaders ?? {},
        formatHint: widget.formatHint,
      );
    } else if (widget.sourceType == VideoSource.asset) {
      _controller = VideoPlayerController.asset(
        widget.videoSource,
        videoPlayerOptions: widget.videoPlayerOptions,
        closedCaptionFile: widget.closedCaptionFile,
        package: widget.package,
      );
    } else if (widget.sourceType == VideoSource.file) {
      _controller = VideoPlayerController.file(
        widget.videoSource,
        videoPlayerOptions: widget.videoPlayerOptions,
        closedCaptionFile: widget.closedCaptionFile,
        httpHeaders: widget.httpHeaders ?? {},
      );
    }
    _controller.initialize().then((_) {
      widget.onInit.call(_controller);
      if (widget.index == MultiVideo.currentIndex) {
        _controller.play();
      }
      _controller.addListener(() => _videoListener());
      setState(() => isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? widget.loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator())
          : _controller.value.isInitialized
              ? widget.itemBuilder?.call(context, _controller, widget.index) ??
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: <Widget>[
                          VideoPlayer(_controller),
                          widget.showControlsOverlay
                              ? widget.controlsBuilder?.call(context) ??
                                  _ControlsOverlay(controller: _controller)
                              : const SizedBox.shrink(),
                          widget.showVideoProgressIndicator
                              ? VideoProgressIndicator(_controller,
                                  allowScrubbing: true)
                              : const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  )
              : const SizedBox.shrink(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    widget.onDispose.call(widget.index);
  }

  _videoListener() {
    if (widget.index != MultiVideo.currentIndex) {
      if (_controller.value.isInitialized) {
        if (_controller.value.isPlaying) {
          _controller.pause();
        }
      }
    }
    setState(() {});
  }
}

class _ControlsOverlay extends StatefulWidget {
  const _ControlsOverlay({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_ControlsOverlay> createState() => _ControlsOverlayState();
}

class _ControlsOverlayState extends State<_ControlsOverlay> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: widget.controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                      semanticLabel: 'Play',
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              widget.controller.value.isPlaying
                  ? widget.controller.pause()
                  : widget.controller.play();
            });
          },
        ),
      ],
    );
  }
}
