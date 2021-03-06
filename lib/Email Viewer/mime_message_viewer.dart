import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:enough_mail/enough_mail.dart';
import 'package:enough_mail_html/enough_mail_html.dart';
import 'package:enough_media/enough_media.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:webview_flutter/webview_flutter.dart';
import 'mime_media_provider.dart';

/// Viewer for mime message contents
class MimeMessageViewer extends StatelessWidget {
  /// Creates a new mime message viewer
  const MimeMessageViewer({
    Key? key,
    required this.mimeMessage,
    this.adjustHeight = true,
    this.blockExternalImages = false,
    this.preferPlainText = false,
    this.enableDarkMode = false,
    this.emptyMessageText,
    this.mailtoDelegate,
    this.showMediaDelegate,
    this.urlLauncherDelegate,
    this.maxImageWidth,
    this.onWebViewCreated,
    this.onZoomed,
    this.onError,
    this.builder,
  }) : super(key: key);

  /// The mime message that should be shown
  final MimeMessage mimeMessage;

  /// The optional maximum width for inline images
  final int? maxImageWidth;

  /// Sets if the height of this view should be set automatically.
  ///
  /// This is required to be `true` when using the MimeMessageViewer
  /// in a scrollable view.
  final bool adjustHeight;

  /// Defines if external images should be removed
  final bool blockExternalImages;

  /// Should the plain text be used instead of the HTML text?
  final bool preferPlainText;

  /// Defines if dark mode should be enabled.
  ///
  /// This might be required on devices with older browser implementations.
  final bool enableDarkMode;

  /// The default text that should be shown for empty messages.
  final String? emptyMessageText;

  /// Handler for mailto: links.
  ///
  /// Typically you will want to open a new compose view prepulated with
  /// a `MessageBuilder.prepareMailtoBasedMessage(uri,from)` instance.
  final Future Function(Uri mailto, MimeMessage mimeMessage)? mailtoDelegate;

  /// Handler for showing the given media widget, typically in its own screen
  final Future Function(InteractiveMediaWidget mediaViewer)? showMediaDelegate;

  /// Handler for any non-media URLs that the user taps on the website.
  ///
  /// Returns `true` when the given `url` was handled.
  final Future<bool> Function(String url)? urlLauncherDelegate;

  /// Register this callback if you want a reference to the [WebViewController].
  final void Function(WebViewController controller)? onWebViewCreated;

  /// This callback will be called when the webview zooms out after loading.
  ///
  /// Usually this is a sign that the user might want to zoom in again.
  final void Function(WebViewController controller, double zoomFactor)?
      onZoomed;

  /// Is notified about any errors that might occur
  final void Function(Object? exception, StackTrace? stackTrace)? onError;

  /// With a builder you can take over the rendering
  /// for certain messages or mime types.
  final Widget? Function(BuildContext context, MimeMessage mimeMessage)?
      builder;

  @override
  Widget build(BuildContext context) {
    final callback = builder;
    if (callback != null) {
      final builtWidget = callback(context, mimeMessage);
      if (builtWidget != null) {
        return builtWidget;
      }
    }
    if (mimeMessage.mediaType.isImage) {
      return _ImageMimeMessageViewer(config: this);
    } else {
      return _HtmlMimeMessageViewer(config: this);
    }
  }
}

class _HtmlGenerationArguments {
  const _HtmlGenerationArguments(
    this.mimeMessage,
    this.emptyMessageText,
    this.maxImageWidth, {
    required this.enableDarkMode,
    required this.preferPlainText,
    required this.blockExternalImages,
  });

  final MimeMessage mimeMessage;
  final bool blockExternalImages;
  final bool preferPlainText;
  final bool enableDarkMode;
  final String? emptyMessageText;
  final int? maxImageWidth;
}

class _HtmlGenerationResult {
  const _HtmlGenerationResult.success(this.base64Html, this.html)
      : errorDetails = null;

  const _HtmlGenerationResult.error(this.errorDetails)
      : base64Html = null,
        html = null;

  final String? base64Html;
  final String? html;
  final String? errorDetails;
}

class _HtmlMimeMessageViewer extends StatefulWidget {
  const _HtmlMimeMessageViewer({Key? key, required this.config})
      : super(key: key);
  final MimeMessageViewer config;

  @override
  State<StatefulWidget> createState() => _HtmlViewerState();
}

class _HtmlViewerState extends State<_HtmlMimeMessageViewer> {
  String? _base64HtmlData;
  String? _htmlData;
  bool? _wereExternalImagesBlocked;
  bool _isGenerating = false;
  Widget? _mediaView;

  double? _webViewHeight;
  double? _webViewWidth;
  bool _isHtmlMessage = true;
  bool _isLoading = true;

  late WebViewController _controller;

  @override
  void initState() {
    _generateHtml(widget.config.blockExternalImages,
        widget.config.preferPlainText, widget.config.enableDarkMode);
    super.initState();
  }

  Future<void> _generateHtml(bool blockExternalImages, bool preferPlainText,
      bool enableDarkMode) async {
    _wereExternalImagesBlocked = blockExternalImages;
    _isGenerating = true;
    final mimeMessage = widget.config.mimeMessage;
    _isHtmlMessage = mimeMessage.hasPart(MediaSubtype.textHtml);
    final args = _HtmlGenerationArguments(
      mimeMessage,
      widget.config.emptyMessageText,
      widget.config.maxImageWidth,
      preferPlainText: preferPlainText,
      enableDarkMode: enableDarkMode,
      blockExternalImages: blockExternalImages,
    );
    final result = await compute(_generateHtmlImpl, args);
    _base64HtmlData = result.base64Html;
    _htmlData = result.html;
    if (_base64HtmlData == null) {
      final onError = widget.config.onError;
      if (onError != null) {
        onError(result.errorDetails, null);
      }
    }
    if (mounted) {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  static _HtmlGenerationResult _generateHtmlImpl(
      _HtmlGenerationArguments args) {
    try {
      final html = args.mimeMessage.transformToHtml(
        blockExternalImages: args.blockExternalImages,
        preferPlainText: args.preferPlainText,
        enableDarkMode: args.enableDarkMode,
        emptyMessageText: args.emptyMessageText,
        maxImageWidth: args.maxImageWidth,
      );
      final base64Html = Uri.dataFromString(
        html,
        mimeType: 'text/html',
        encoding: utf8,
        base64: true,
      ).toString();

      return _HtmlGenerationResult.success(base64Html, html);
    } catch (e, s) {
      print('ERROR: unable to transform mime message to HTML: $e $s');
      final errorDetails = '$e\n\n$s';
      return _HtmlGenerationResult.error(errorDetails);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mediaView != null) {
      return WillPopScope(
        child: _mediaView!,
        onWillPop: () {
          setState(() {
            _mediaView = null;
          });
          return Future.value(false);
        },
      );
    }
    if (_isGenerating) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Platform.isAndroid
              ? const CircularProgressIndicator()
              : const CupertinoActivityIndicator(),
        ),
      );
    }
    if (widget.config.blockExternalImages != _wereExternalImagesBlocked) {
      _generateHtml(widget.config.blockExternalImages,
          widget.config.preferPlainText, widget.config.enableDarkMode);
    }

    if (widget.config.adjustHeight) {
      final size = MediaQuery.of(context).size;
      final width = _webViewWidth;
      final height = _webViewHeight ?? size.height;
      if (width != null) {
        return FittedBox(
          child: SizedBox(
            width: width,
            height: height,
            child: _buildWebView(),
          ),
        );
      } else {
        return SizedBox(
          width: width,
          height: height,
          child: _buildWebViewWithLoadingIndicator(),
        );
      }
    } else {
      return _buildWebViewWithLoadingIndicator();
    }
  }

  Widget _buildWebViewWithLoadingIndicator() => Stack(
        children: [
          _buildWebView(),
          if (_isLoading)
            const Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(),
              ),
            ),
        ],
      );

  Widget _buildWebView() {
    final htmlData = _htmlData;
    if (htmlData == null) {
      return Container();
    }
    return WebView(
      key: ValueKey(htmlData),
      javascriptMode: JavascriptMode.unrestricted,
      onWebViewCreated: (controller) async {
        _controller = controller;
        if (kDebugMode) {
          print('loading html $htmlData');
        }
        await controller.loadHtmlString(htmlData, baseUrl: null);
        widget.config.onWebViewCreated?.call(controller);
      },
      onPageFinished: (url) async {
        if (kDebugMode) {
          print('onPageFinished $url');
        }
        if (widget.config.adjustHeight) {
          final scrollHeightText = await _controller
              .runJavascriptReturningResult('document.body.scrollHeight');
          final scrollHeight = double.tryParse(scrollHeightText);
          // print('scrollHeight: $scrollHeightText');
          final scrollWidthText = await _controller
              .runJavascriptReturningResult('document.body.scrollWidth');
          // print('scrollWidth: $scrollWidthText');
          var scrollWidth = double.tryParse(scrollWidthText);
          if (scrollHeight != null && mounted) {
            final size = MediaQuery.of(context).size;
            // print('size: ${size.height}x${size.width}');
            if (_isHtmlMessage &&
                scrollWidth != null &&
                scrollWidth > size.width + 10.0) {
              var scale = size.width / scrollWidth;
              const minScale = 0.5;
              if (scale < minScale) {
                scale = minScale;
                scrollWidth = size.width / minScale;
              }
              _webViewWidth = scrollWidth;
              final callback = widget.config.onZoomed;
              if (callback != null) {
                callback(_controller, scale);
              }
            } else {
              _webViewWidth = null;
            }
            final scrollHeightWithBuffer = scrollHeight + 10.0;
            if (mounted && _webViewHeight != scrollHeightWithBuffer) {
              setState(() {
                _webViewHeight = scrollHeightWithBuffer;
                _isLoading = false;
                // print('webViewHeight set to $_webViewHeight');
                // print('webViewWidth set to $_webViewWidth');
              });
            }
          }
        }
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      },
      navigationDelegate: _onNavigation,
      gestureRecognizers: widget.config.adjustHeight
          ? {
              Factory<LongPressGestureRecognizer>(
                  () => LongPressGestureRecognizer()),
              // The scale gesture recognizer interferes with
              // scrolling on Flutter 2.2
              // Factory<ScaleGestureRecognizer>(() =>
              // ScaleGestureRecognizer()),
            }
          : null,
    );
  }

  FutureOr<NavigationDecision> _onNavigation(
      NavigationRequest navigation) async {
    if (kDebugMode) {
      print('onNavigation $navigation');
    }
    // for iOS / WKWebView necessary:
    if (navigation.isForMainFrame && navigation.url == 'about:blank') {
      return NavigationDecision.navigate;
    }
    final requestUri = Uri.parse(navigation.url);
    final mimeMessage = widget.config.mimeMessage;
    final mailtoHandler = widget.config.mailtoDelegate;
    if (mailtoHandler != null && requestUri.isScheme('mailto')) {
      await mailtoHandler(requestUri, mimeMessage);
      return NavigationDecision.prevent;
    }
    if (requestUri.isScheme('cid') || requestUri.isScheme('fetch')) {
      // show inline part:
      final cid = Uri.decodeComponent(requestUri.host);
      final part = requestUri.isScheme('cid')
          ? mimeMessage.getPartWithContentId(cid)
          : mimeMessage.getPart(cid);
      if (part != null) {
        final mediaProvider =
            MimeMediaProviderFactory.fromMime(mimeMessage, part);
        final mediaWidget = InteractiveMediaWidget(
          mediaProvider: mediaProvider,
        );
        final showMediaCallback = widget.config.showMediaDelegate;
        if (showMediaCallback != null) {
          await showMediaCallback(mediaWidget);
        } else {
          setState(() {
            _mediaView = mediaWidget;
          });
        }
      }
      return NavigationDecision.prevent;
    }
    final url = navigation.url;
    final urlDelegate = widget.config.urlLauncherDelegate;
    if (urlDelegate != null) {
      final handled = await urlDelegate(url);
      if (handled) {
        return NavigationDecision.prevent;
      }
    }
    //if (await launcher.canLaunch(url)) {
    // not checking due to
    // https://github.com/flutter/flutter/issues/93765#issuecomment-1018994962
    await launcher.launch(url);
    return NavigationDecision.prevent;
    // } else {
    //   return NavigationDecision.navigate;
    // }
  }
}

class _ImageMimeMessageViewer extends StatefulWidget {
  const _ImageMimeMessageViewer({Key? key, required this.config})
      : super(key: key);

  final MimeMessageViewer config;

  @override
  State<StatefulWidget> createState() => _ImageViewerState();
}

/// State for a message with  `Content-Type: image/XXX`
class _ImageViewerState extends State<_ImageMimeMessageViewer> {
  bool _showFullScreen = false;
  Uint8List? _imageData;

  @override
  void initState() {
    _imageData = widget.config.mimeMessage.decodeContentBinary();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_showFullScreen) {
      final screenHeight = MediaQuery.of(context).size.height;
      return WillPopScope(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!constraints.hasBoundedHeight) {
              constraints = constraints.copyWith(maxHeight: screenHeight);
            }
            return ConstrainedBox(
              constraints: constraints,
              child: ImageInteractiveMedia(
                mediaProvider: MimeMediaProviderFactory.fromMime(
                    widget.config.mimeMessage, widget.config.mimeMessage),
              ),
            );
          },
        ),
        onWillPop: () {
          setState(() => _showFullScreen = false);
          return Future.value(false);
        },
      );
    } else {
      return TextButton(
        onPressed: () {
          final callback = widget.config.showMediaDelegate;
          if (callback != null) {
            final mediaProvider = MimeMediaProviderFactory.fromMime(
                widget.config.mimeMessage, widget.config.mimeMessage);
            final mediaWidget =
                InteractiveMediaWidget(mediaProvider: mediaProvider);
            callback(mediaWidget);
          } else {
            setState(() => _showFullScreen = true);
          }
        },
        child: _imageData != null
            ? Image.memory(_imageData!)
            : const Text('no image data'),
      );
    }
  }
}
