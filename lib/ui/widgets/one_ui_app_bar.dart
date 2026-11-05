import 'package:flutter/material.dart';

/// A clean, lightweight One UI-style collapsing app bar:
/// a tall header with a large centered title, with the back button
/// positioned below the title when expanded, smoothly gliding into
/// the toolbar row as the user scrolls.
class OneUiSliverAppBar extends StatelessWidget {
  const OneUiSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton,
    this.expandedHeight,
  });

  final String title;
  final List<Widget>? actions;
  final bool? showBackButton;
  final double? expandedHeight;

  static const double _expandedFontSize = 34;
  static const double _collapsedFontSize = 20;
  static const double _toolbarHeight = kToolbarHeight;
  static const double _sidePadding = 56;
  static const double _buttonSize = 48;
  static const double _backGap = 8;

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final expHeight =
        expandedHeight ?? (screenHeight * 0.24).clamp(170.0, 240.0);
    final canPop = Navigator.of(context).canPop();
    final showBack = showBackButton ?? canPop;

    final baseStyle = theme.textTheme.headlineMedium ??
        const TextStyle(fontWeight: FontWeight.w800);

    return SliverAppBar(
      pinned: true,
      expandedHeight: expHeight,
      toolbarHeight: _toolbarHeight,
      automaticallyImplyLeading: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      actions: actions,
      leading: null, // Back button is positioned in the flexibleSpace Stack
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = MediaQuery.paddingOf(context).top;
          final range = expHeight - _toolbarHeight;
          // 1 = fully expanded, 0 = fully collapsed.
          final t = range <= 0
              ? 0.0
              : ((constraints.maxHeight - top - _toolbarHeight) / range).clamp(
                  0.0,
                  1.0,
                );

          final fontSize = _lerp(_collapsedFontSize, _expandedFontSize, t);

          // Back button: bottom-left of the expanded header (below the title),
          // glides up into the toolbar row when collapsed.
          final backExpandedTop = top + expHeight - _buttonSize - _backGap;
          final backCollapsedTop = top + (_toolbarHeight - _buttonSize) / 2;
          final backTop = _lerp(backCollapsedTop, backExpandedTop, t);

          // Title: centered in the space above the back button when expanded;
          // in the toolbar row when collapsed.
          final titleExpandedY = (top + backExpandedTop + 35) / 2;
          final titleCollapsedY = top + _toolbarHeight / 2;
          final titleY = _lerp(titleCollapsedY, titleExpandedY, t);

          return Stack(
            children: [
              Positioned(
                top: titleY - 24,
                left: _sidePadding,
                right: _sidePadding,
                height: 48,
                child: Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: baseStyle.copyWith(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              if (showBack)
                Positioned(
                  top: backTop,
                  left: 8,
                  child: const BackButton(),
                ),
            ],
          );
        },
      ),
    );
  }
}
