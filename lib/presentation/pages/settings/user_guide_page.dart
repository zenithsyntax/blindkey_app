import 'package:blindkey_app/presentation/constants/guide_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class UserGuidePage extends StatefulWidget {
  final bool autoPlay;
  const UserGuidePage({super.key, this.autoPlay = false});

  @override
  State<UserGuidePage> createState() => _UserGuidePageState();
}

class _UserGuidePageState extends State<UserGuidePage> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(youtubeVideoUrl) ?? '';
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: widget.autoPlay,
        mute: false,
        forceHD: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        progressColors: const ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
        ),
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          appBar: AppBar(
            title: Text(
              'User Guide',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // Background
               Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF141414),
                        const Color(0xFF0F0F0F),
                        const Color(0xFF0F0505),
                      ],
                    ),
                  ),
                ),
              ),
              
              SafeArea(
                child: Column(
                  children: [
                    // Video Player
                    if (_controller.initialVideoId.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: player,
                        ),
                      ),

                    // Text Content
                    Expanded(
                      child: Markdown(
                        data: userGuideData,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        styleSheet: MarkdownStyleSheet(
                          h1: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          h2: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 2),
                          h3: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          p: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.5),
                          listBullet: GoogleFonts.inter(color: Colors.white70),
                          strong: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
