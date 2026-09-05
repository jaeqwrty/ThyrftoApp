import 'dart:async';

import 'package:flutter/material.dart';
import 'package:thryfto/core/navigation/deep_link_router.dart';
import 'package:thryfto/core/navigation/deep_link_service.dart';

class DeepLinkGate extends StatefulWidget {
  final Map<String, dynamic> user;
  final Widget child;

  const DeepLinkGate({
    super.key,
    required this.user,
    required this.child,
  });

  @override
  State<DeepLinkGate> createState() => _DeepLinkGateState();
}

class _DeepLinkGateState extends State<DeepLinkGate> {
  StreamSubscription<Uri>? _subscription;
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    _subscription = DeepLinkService.instance.links.listen(_handleUri);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePending());
  }

  @override
  void didUpdateWidget(covariant DeepLinkGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user['id'] != widget.user['id']) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handlePending());
    }
  }

  Future<void> _handlePending() async {
    final uri = DeepLinkService.instance.pendingUri;
    if (uri != null) await _handleUri(uri);
  }

  Future<void> _handleUri(Uri uri) async {
    if (!mounted || _handling) return;
    _handling = true;

    try {
      await DeepLinkRouter.open(
        context,
        uri,
        currentUser: widget.user,
      );
      DeepLinkService.instance.markHandled(uri);
    } finally {
      _handling = false;
      if (mounted) {
        final pending = DeepLinkService.instance.pendingUri;
        if (pending != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _handleUri(pending));
        }
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
