import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../bloc/theme_bloc/theme_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../../core/extensions/color.dart';
import '../../injection_container.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _loadingProgress = progress);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _hasError = false);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loadingProgress = 100);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _hasError = true);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = sl<ThemeBloc>().state.baseTheme;
    final isLoading = _loadingProgress < 100;

    return Scaffold(
      backgroundColor: baseTheme.background,
      appBar: AppBar(
        backgroundColor: baseTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(AppConstants.radius8Px),
          child: Icon(
            Icons.arrow_back_ios,
            color: baseTheme.textColor,
            size: 22,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontFamily: AppConstants.fontFamilyLato,
                fontSize: AppConstants.font16Px,
                fontWeight: FontWeight.w700,
                color: baseTheme.textColor,
              ),
            ),
            if (isLoading)
              Text(
                'Loading...',
                style: TextStyle(
                  fontFamily: AppConstants.fontFamilyLato,
                  fontSize: AppConstants.font12Px,
                  fontWeight: FontWeight.w400,
                  color: baseTheme.textColor.fixedOpacity(0.45),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: Icon(
              Icons.refresh_rounded,
              color: baseTheme.textColor.fixedOpacity(0.6),
            ),
            tooltip: 'Reload',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: AnimatedOpacity(
            opacity: isLoading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: LinearProgressIndicator(
              value: _loadingProgress / 100,
              minHeight: 3,
              backgroundColor: baseTheme.primary.fixedOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(baseTheme.primary),
            ),
          ),
        ),
      ),
      body: _hasError ? _ErrorView(baseTheme: baseTheme, onRetry: _reload) : WebViewWidget(controller: _controller),
    );
  }

  void _reload() {
    setState(() {
      _hasError = false;
      _loadingProgress = 0;
    });
    _controller.reload();
  }
}

class _ErrorView extends StatelessWidget {
  final dynamic baseTheme;
  final VoidCallback onRetry;

  const _ErrorView({required this.baseTheme, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: baseTheme.primary.fixedOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 34,
                color: baseTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to load page',
              style: TextStyle(
                fontFamily: AppConstants.fontFamilyLato,
                fontSize: AppConstants.font18Px,
                fontWeight: FontWeight.w700,
                color: baseTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppConstants.fontFamilyLato,
                fontSize: AppConstants.font14Px,
                fontWeight: FontWeight.w400,
                color: baseTheme.textColor.fixedOpacity(0.55),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 140,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Try Again',
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: AppConstants.font14Px,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: baseTheme.primary,
                  foregroundColor: baseTheme.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radius12Px),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
