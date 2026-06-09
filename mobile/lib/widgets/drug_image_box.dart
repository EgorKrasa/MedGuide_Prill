import 'package:flutter/material.dart';

import '../utils/drug_image_urls.dart';

/// Фото препарата только с сервера (Render API), с перебором рабочих URL.
class DrugImageBox extends StatefulWidget {
  const DrugImageBox({
    super.key,
    required this.drugId,
    this.imageIndex,
    this.imageUrl,
  });

  final String drugId;
  final int? imageIndex;
  final String? imageUrl;

  @override
  State<DrugImageBox> createState() => _DrugImageBoxState();
}

class _DrugImageBoxState extends State<DrugImageBox> {
  late int _urlIndex;
  late List<String> _urls;

  @override
  void initState() {
    super.initState();
    _urls = _buildUrls();
    _urlIndex = 0;
  }

  @override
  void didUpdateWidget(covariant DrugImageBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drugId != widget.drugId ||
        oldWidget.imageIndex != widget.imageIndex ||
        oldWidget.imageUrl != widget.imageUrl) {
      _urls = _buildUrls();
      _urlIndex = 0;
    }
  }

  List<String> _buildUrls() {
    return DrugImageUrls.serverCandidates(
      drugId: widget.drugId,
      imageIndex: widget.imageIndex,
      imageUrl: widget.imageUrl,
    );
  }

  void _tryNextUrl() {
    if (_urlIndex + 1 >= _urls.length) return;
    setState(() => _urlIndex++);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: _urls.isEmpty ? _placeholder(context) : _buildImage(context),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final url = _urls[_urlIndex];
    return Image.network(
      url,
      key: ValueKey(url),
      fit: BoxFit.contain,
      width: double.infinity,
      alignment: Alignment.center,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          height: 180,
          child: Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        if (_urlIndex + 1 < _urls.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _tryNextUrl();
          });
          return SizedBox(
            height: 180,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }
        return _placeholder(context);
      },
    );
  }

  Widget _placeholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 180,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 8),
          Text('Фото недоступно', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Проверьте интернет и API',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
