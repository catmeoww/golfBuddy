import 'dart:io';

import 'package:flutter/material.dart';

import '../../../domain/models/session.dart';
import '../../../services/video/thumbnail_generator.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({
    required this.session,
    required this.playerName,
    required this.onTap,
    this.tournamentName,
    super.key,
  });

  final SwingSession session;
  final String playerName;
  final String? tournamentName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: _Thumb(
              thumbPath: session.thumbPath,
              videoPath: session.videoPath,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  playerName,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(session.capturedAt),
                  style: theme.textTheme.bodySmall,
                ),
                if (session.club != null || tournamentName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        if (session.club != null)
                          _MetaChip(label: session.club!),
                        if (tournamentName != null)
                          _MetaChip(label: tournamentName!),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

class _Thumb extends StatefulWidget {
  const _Thumb({required this.thumbPath, required this.videoPath});

  final String thumbPath;
  final String videoPath;

  @override
  State<_Thumb> createState() => _ThumbState();
}

class _ThumbState extends State<_Thumb> {
  bool _attempted = false;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _ensureThumb();
  }

  Future<void> _ensureThumb() async {
    final thumb = File(widget.thumbPath);
    if (await thumb.exists()) return;
    final video = File(widget.videoPath);
    if (!await video.exists()) return;
    if (_attempted) return;
    _attempted = true;
    final ok = await const ThumbnailGenerator().generate(
      videoPath: widget.videoPath,
      outputPath: widget.thumbPath,
    );
    if (!mounted) return;
    if (ok) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.thumbPath);
    if (!file.existsSync()) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.videocam_off_outlined, size: 32),
      );
    }
    // ValueKey forces a fresh FileImage after generation so Flutter's
    // image cache doesn't keep serving the "missing file" state.
    return Image.file(
      file,
      key: ValueKey('${widget.thumbPath}:$_version'),
      fit: BoxFit.cover,
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
