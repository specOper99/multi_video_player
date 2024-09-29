import 'package:flutter/material.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:video_player/video_player.dart';

import 'multi_video_item.dart';
import 'multi_video_model.dart';

/// Stateful widget to display preloaded videos inside page view.
//ignore: must_be_immutable
class MultiVideoPlayer extends StatefulWidget {
  /// enum sourceType values holds the type of source Network, Assets or File
  VideoSource sourceType;

  /// videoSourceList is List or dynamic video sources
  List<dynamic> videoSourceList;

  /// scroll direction of preload page view
  Axis scrollDirection;

  /// number of videos getting initialized defined by preloadPagesCount
  int preloadPagesCount;

  VideoPlayerOptions? videoPlayerOptions;
  Future<ClosedCaptionFile>? closedCaptionFile;
  Map<String, String>? httpHeaders;
  VideoFormat? formatHint;
  String? package;

  bool showControlsOverlay;
  bool showVideoProgressIndicator;

  double height;
  double width;

  Future<dynamic> Function(dynamic videoSource)? videoSourcesParser;

  /// itemBuilder returns the video player controller to customize the video player
  Widget Function(BuildContext context, VideoPlayerController controller)?
      itemBuilder;

  /// loadingBuilder returns the loading widget to customize the loading widget
  Widget Function(BuildContext context)? loadingBuilder;

  /// controlsBuilder returns the controls widget to customize the controls widget
  Widget Function(BuildContext context)? controlsBuilder;

  /// getCurrentVideoController return the current playing video controller
  Function(VideoPlayerController? videoPlayerController)?
      getCurrentVideoController;

  /// onPageChanged calls when swiping through the pages, return
  /// current playing video controller and index
  Function(VideoPlayerController? videoPlayerController, int index)?
      onPageChanged;
  ScrollPhysics? scrollPhysics;
  bool reverse;
  bool pageSnapping;

  /// [PreloadPageView] controller
  PreloadPageController? pageController;

  @override
  State<MultiVideoPlayer> createState() => _MultiVideoPlayerState();

  /// plays videos from list of network video urls
  MultiVideoPlayer.network({
    super.key,
    required this.videoSourceList,
    required this.height,
    required this.width,
    this.videoSourcesParser,
    this.itemBuilder,
    this.loadingBuilder,
    this.controlsBuilder,
    this.scrollDirection = Axis.horizontal,
    this.preloadPagesCount = 1,
    this.videoPlayerOptions,
    this.httpHeaders,
    this.formatHint,
    this.closedCaptionFile,
    this.scrollPhysics,
    this.reverse = false,
    this.pageSnapping = true,
    this.pageController,
    this.getCurrentVideoController,
    this.onPageChanged,
    this.showControlsOverlay = true,
    this.showVideoProgressIndicator = true,
  }) : sourceType = VideoSource.network;

  /// plays videos from list of video files
  MultiVideoPlayer.file({
    super.key,
    required this.videoSourceList,
    required this.height,
    required this.width,
    this.videoSourcesParser,
    this.itemBuilder,
    this.loadingBuilder,
    this.controlsBuilder,
    this.scrollDirection = Axis.horizontal,
    this.preloadPagesCount = 1,
    this.videoPlayerOptions,
    this.httpHeaders,
    this.closedCaptionFile,
    this.scrollPhysics,
    this.reverse = false,
    this.pageSnapping = true,
    this.pageController,
    this.getCurrentVideoController,
    this.onPageChanged,
    this.showControlsOverlay = true,
    this.showVideoProgressIndicator = true,
  }) : sourceType = VideoSource.file;

  /// plays videos from list of asset videos
  MultiVideoPlayer.asset({
    super.key,
    required this.videoSourceList,
    required this.height,
    required this.width,
    this.videoSourcesParser,
    this.itemBuilder,
    this.loadingBuilder,
    this.controlsBuilder,
    this.scrollDirection = Axis.horizontal,
    this.preloadPagesCount = 1,
    this.videoPlayerOptions,
    this.package,
    this.closedCaptionFile,
    this.scrollPhysics,
    this.reverse = false,
    this.pageSnapping = true,
    this.pageController,
    this.getCurrentVideoController,
    this.onPageChanged,
    this.showControlsOverlay = true,
    this.showVideoProgressIndicator = true,
  }) : sourceType = VideoSource.asset;
}

class _MultiVideoPlayerState extends State<MultiVideoPlayer> {
  bool isLoading = true;
  List<MultiVideo> videosList = [];

  @override
  void initState() {
    super.initState();
    _generateVideoList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: widget.height,
        width: widget.width,
        child: videosList.isEmpty
            ? const Center(child: Icon(Icons.error))
            : isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _pageView(),
      ),
    );
  }

  /// [PreloadPageView] initializes more than one videos at time
  PreloadPageView _pageView() {
    return PreloadPageView.builder(
      itemCount: videosList.length,
      physics: widget.scrollPhysics,
      reverse: widget.reverse,
      controller: widget.pageController,
      pageSnapping: widget.pageSnapping,
      scrollDirection: widget.scrollDirection,
      preloadPagesCount: widget.preloadPagesCount > videosList.length
          ? 1
          : widget.preloadPagesCount,
      onPageChanged: (int index) => _onPageChange(index),
      itemBuilder: (context, index) => _child(index),
    );
  }

  /// [VideoPlayer] video player combined with [PreloadPageView]
  MultiVideoItem _child(int index) {
    return MultiVideoItem(
      videoSource: videosList[index].videoSource,
      index: index,
      sourceType: widget.sourceType,
      videoPlayerOptions: widget.videoPlayerOptions,
      closedCaptionFile: widget.closedCaptionFile,
      showControlsOverlay: widget.showControlsOverlay,
      showVideoProgressIndicator: widget.showVideoProgressIndicator,
      onInit: (VideoPlayerController videoPlayerController) {
        if (index == MultiVideo.currentIndex) {
          widget.getCurrentVideoController?.call(videoPlayerController);
        }
        videosList[index].updateVideo(
            videoPlayerController: videoPlayerController,
            index: index,
            videoSource: videosList[index].videoSource);
      },
      onDispose: (int index) {
        videosList[index].videoPlayerController = null;
      },
      itemBuilder: widget.itemBuilder,
      loadingBuilder: widget.loadingBuilder,
      controlsBuilder: widget.controlsBuilder,
    );
  }

  _onPageChange(int index) {
    MultiVideo.currentIndex = index;
    widget.getCurrentVideoController
        ?.call(videosList[index].videoPlayerController);
    widget.onPageChanged?.call(videosList[index].videoPlayerController, index);
    videosList[index].playVideo(index);
  }

  Future<void> _generateVideoList() async {
    await Future.forEach(widget.videoSourceList, (source) async {
      if (widget.videoSourcesParser != null) {
        source = await widget.videoSourcesParser!(source);
      }
      if (source == null) {
        return;
      }
      videosList.add(MultiVideo(
        videoSource: source,
      ));
    });
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}
