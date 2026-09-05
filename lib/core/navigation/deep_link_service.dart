import 'dart:async';

import 'package:app_links/app_links.dart';

enum DeepLinkKind { listing, chat, transaction }

class DeepLinkTarget {
  final DeepLinkKind kind;
  final String id;

  const DeepLinkTarget({required this.kind, required this.id});

  static DeepLinkTarget? parse(Uri uri) {
    String? kindValue;
    String? id;

    if (uri.scheme.toLowerCase() == DeepLinkService.appScheme) {
      kindValue = uri.host.toLowerCase();
      if (uri.pathSegments.isNotEmpty) id = uri.pathSegments.first;
    } else if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.toLowerCase() == DeepLinkService.webHost &&
        uri.pathSegments.length >= 2) {
      kindValue = uri.pathSegments[0].toLowerCase();
      id = uri.pathSegments[1];
    }

    if (id == null || id.trim().isEmpty) return null;

    switch (kindValue) {
      case 'listing':
        return DeepLinkTarget(kind: DeepLinkKind.listing, id: id);
      case 'chat':
        return DeepLinkTarget(kind: DeepLinkKind.chat, id: id);
      case 'transaction':
        return DeepLinkTarget(kind: DeepLinkKind.transaction, id: id);
      default:
        return null;
    }
  }
}

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  static const String appScheme = 'thryfto';
  static const String webHost = 'thryfto.app';

  final AppLinks _appLinks = AppLinks();
  final StreamController<Uri> _controller = StreamController<Uri>.broadcast();
  StreamSubscription<Uri>? _subscription;
  Uri? _pendingUri;
  bool _initialized = false;

  Stream<Uri> get links => _controller.stream;
  Uri? get pendingUri => _pendingUri;

  static Uri listingUri(String listingId) =>
      Uri(scheme: appScheme, host: 'listing', path: '/$listingId');

  static Uri listingWebUri(String listingId) =>
      Uri.https(webHost, '/listing/$listingId');

  static Uri chatUri(String chatId) =>
      Uri(scheme: appScheme, host: 'chat', path: '/$chatId');

  static Uri transactionUri(String transactionId) =>
      Uri(scheme: appScheme, host: 'transaction', path: '/$transactionId');

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // app_links emits both the cold-start link and later warm links here.
      _subscription = _appLinks.uriLinkStream.listen(
        _accept,
        onError: (_) {},
      );
    } catch (_) {
      // Unsupported platforms should not prevent the app from starting.
    }
  }

  void _accept(Uri uri) {
    if (DeepLinkTarget.parse(uri) == null) return;
    _pendingUri = uri;
    _controller.add(uri);
  }

  void markHandled(Uri uri) {
    if (_pendingUri?.toString() == uri.toString()) {
      _pendingUri = null;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
