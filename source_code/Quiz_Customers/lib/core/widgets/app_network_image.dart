import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Robust cross-platform network image loader with automatic Web CORS fallback
/// and high-performance mobile caching.
class AppNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final String? fallbackTitle;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.fallbackTitle,
  });

  /// Builds a high-speed CDN proxy URL for Web environments to bypass any CORS restrictions
  static String buildProxiedUrl(String rawUrl) {
    final clean = rawUrl.trim();
    if (clean.isEmpty) return clean;
    if (clean.startsWith('https://wsrv.nl/') || clean.startsWith('http://localhost')) {
      return clean;
    }
    return 'https://wsrv.nl/?url=${Uri.encodeComponent(clean)}&output=webp&q=85';
  }

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  bool _useProxyFallback = false;
  bool _hasFailed = false;

  @override
  void didUpdateWidget(AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _useProxyFallback = false;
      _hasFailed = false;
    }
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) return widget.placeholder!;
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppColors.surfaceContainer,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackWidget() {
    if (widget.errorWidget != null) return widget.errorWidget!;
    final title = widget.fallbackTitle?.trim() ?? 'Quiz Book';
    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryContainer.withValues(alpha: 0.8),
            AppColors.surfaceContainerHigh,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book_rounded, color: Colors.white, size: 28),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSm.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = widget.imageUrl.trim();
    if (cleanUrl.isEmpty || _hasFailed) {
      return _buildFallbackWidget();
    }

    // Determine target URL: primary or proxied fallback
    final activeUrl = _useProxyFallback
        ? AppNetworkImage.buildProxiedUrl(cleanUrl)
        : cleanUrl;

    Widget imageContent;

    if (kIsWeb) {
      // Flutter Web: Image.network with progressive fallback
      imageContent = Image.network(
        activeUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          // If primary URL failed on Web, try the Cloudflare CDN proxy
          if (!_useProxyFallback) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _useProxyFallback = true;
                });
              }
            });
            return _buildPlaceholder();
          }

          // Both primary and proxy failed, render fallback widget
          return _buildFallbackWidget();
        },
      );
    } else {
      // Mobile / Desktop native: CachedNetworkImage with local disk cache
      imageContent = CachedNetworkImage(
        imageUrl: activeUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (_, __) => _buildPlaceholder(),
        errorWidget: (_, __, ___) {
          if (!_useProxyFallback) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _useProxyFallback = true;
                });
              }
            });
            return _buildPlaceholder();
          }
          return _buildFallbackWidget();
        },
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageContent,
      );
    }

    return imageContent;
  }
}
