import 'package:bam_bam_user/app/theme/colors_value.dart';
import 'package:flutter/material.dart';

/// Standard physics so pull-to-refresh works even when content is short.
const AlwaysScrollableScrollPhysics kPullToRefreshScrollPhysics =
    AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());

/// Wraps scrollable content with pull-to-refresh and prevents duplicate refresh calls.
class PullToRefreshWrapper extends StatefulWidget {
  const PullToRefreshWrapper({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;
  final Color? backgroundColor;

  @override
  State<PullToRefreshWrapper> createState() => _PullToRefreshWrapperState();
}

class _PullToRefreshWrapperState extends State<PullToRefreshWrapper> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: widget.color ?? ColorsValue.appColor,
      backgroundColor: widget.backgroundColor ?? ColorsValue.whiteColor,
      strokeWidth: 2.5,
      onRefresh: _handleRefresh,
      child: widget.child,
    );
  }
}
