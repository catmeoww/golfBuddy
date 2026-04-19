import 'package:flutter/material.dart';

class AddAnnotationResult {
  const AddAnnotationResult({required this.text, this.timestampMs});

  final String text;
  final int? timestampMs;
}

class AddAnnotationSheet extends StatefulWidget {
  const AddAnnotationSheet({
    this.initialTimestampMs,
    super.key,
  });

  final int? initialTimestampMs;

  @override
  State<AddAnnotationSheet> createState() => _AddAnnotationSheetState();
}

class _AddAnnotationSheetState extends State<AddAnnotationSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initialTimestampMs == null
                    ? 'Add session note'
                    : 'Add note at ${_formatMs(widget.initialTimestampMs!)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'e.g. hips opening early, left shoulder drop',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;
                      Navigator.of(context).pop(
                        AddAnnotationResult(
                          text: text,
                          timestampMs: widget.initialTimestampMs,
                        ),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatMs(int ms) {
    final seconds = ms ~/ 1000;
    final millis = ms % 1000;
    return '${seconds}s ${millis.toString().padLeft(3, '0')}ms';
  }
}
