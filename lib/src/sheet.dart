import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'sheet_container.dart';
import 'specs.dart';
import 'util.dart';

part 'scrolling.dart';
part 'sheet_dialog.dart';

typedef SheetBuilder = Widget Function(BuildContext context, SheetState state);

typedef CustomSheetBuilder = Widget Function(
    BuildContext context, ScrollController controller, SheetState state);

typedef SheetListener = void Function(SheetState state);

typedef OnDismissPreventedCallback = void Function(bool backButton, bool backDrop);

/// A widget that can be dragged and scrolled in a single gesture and snapped
/// to a list of extents.
///
/// The [builder] parameter must not be null.
class SlidingSheet extends StatefulWidget {
  /// {@template perceive_slidable.builder}
  /// The builder for the main content of the sheet that will be scrolled if
  /// the content is bigger than the height that the sheet can expand to.
  /// {@endtemplate}
  final SheetBuilder? builder;

  /// {@template perceive_slidable.customBuilder}
  /// Allows you to supply your own custom sroll view. Useful for infinite lists
  /// that cannot be shrinkWrapped like long lists.
  /// {@endtemplate}
  final CustomSheetBuilder? customBuilder;

  /// {@template perceive_slidable.headerBuilder}
  /// The builder for a header that will be displayed at the top of the sheet
  /// that wont be scrolled.
  /// {@endtemplate}
  final SheetBuilder? headerBuilder;

  /// {@template perceive_slidable.footerBuilder}
  /// The builder for a footer that will be displayed at the bottom of the sheet
  /// that wont be scrolled.
  /// {@endtemplate}
  final SheetBuilder? footerBuilder;

  /// {@template perceive_slidable.snapSpec}
  /// The [SnapSpec] that defines how the sheet should snap or if it should at all.
  /// {@endtemplate}
  final SnapSpec snapSpec;

  /// {@template perceive_slidable.duration}
  /// The base animation duration for the sheet. Swipes and flings may have a different duration.
  /// {@endtemplate}
  final Duration duration;

  /// {@template perceive_slidable.color}
  /// The background color of the sheet.
  ///
  /// When not specified, the sheet will use `theme.cardColor`.
  /// {@endtemplate}
  final Color? color;

  /// {@template perceive_slidable.backdropColor}
  /// The color of the shadow that is displayed behind the sheet.
  /// {@endtemplate}
  final Color? backdropColor;

  /// {@template perceive_slidable.shadowColor}
  /// The color of the drop shadow of the sheet when [elevation] is > 0.
  /// {@endtemplate}
  final Color? shadowColor;

  /// {@template perceive_slidable.elevation}
  /// The elevation of the sheet.
  /// {@endtemplate}
  final double elevation;

  /// {@template perceive_slidable.padding}
  /// The amount to inset the children of the sheet.
  /// {@endtemplate}
  final EdgeInsets? padding;

  /// {@template perceive_slidable.avoidStatusBar}
  /// If true, adds the top padding returned by
  /// `MediaQuery.of(context).viewPadding.top` to the [padding] when taking
  /// up the full screen.
  ///
  /// This can be used to easily avoid the content of the sheet from being
  /// under the status bar, which is especially useful when having a header.
  /// {@endtemplate}
  final bool avoidStatusBar;

  /// {@template perceive_slidable.margin}
  /// The amount of empty space surrounding the sheet.
  /// {@endtemplate}
  final EdgeInsets? margin;

  /// The amount of empty space sourrounding the sheet when expanded.
  final EdgeInsets? marginWhenExpanded;

  /// {@template perceive_slidable.border}
  /// A border that will be drawn around the sheet.
  /// {@endtemplate}
  final Border? border;

  /// {@template perceive_slidable.cornerRadius}
  /// The radius of the top corners of this sheet.
  /// {@endtemplate}
  final double cornerRadius;

  /// {@template perceive_slidable.cornerRadiusOnFullscreen}
  /// The radius of the top corners of this sheet when expanded to fullscreen.
  ///
  /// This parameter can be used to easily implement the common Material
  /// behaviour of sheets to go from rounded corners to sharp corners when
  /// taking up the full screen.
  /// {@endtemplate}
  final double? cornerRadiusWhenExpanded;

  /// If true, will collapse the sheet when the sheets backdrop was tapped.
  final bool closeOnBackdropTap;

  /// {@template perceive_slidable.listener}
  /// A callback that will be invoked when the sheet gets dragged or scrolled
  /// with current state information.
  /// {@endtemplate}
  final SheetListener? listener;

  /// {@template perceive_slidable.controller}
  /// A controller to control the state of the sheet.
  /// {@endtemplate}
  final SheetController? controller;

  /// {@template perceive_slidable.scrollSpec}
  /// The [ScrollSpec] of the containing ScrollView.
  /// {@endtemplate}
  final ScrollSpec scrollSpec;

  /// {@template perceive_slidable.maxWidth}
  /// The maximum width of the sheet.
  ///
  /// Usually set for large screens. By default the [SlidingSheet]
  /// expands to the total available width.
  /// {@endtemplate}
  final double maxWidth;

  /// {@template perceive_slidable.maxWidth}
  /// The minimum height of the sheet of the child returned by the `builder`.
  ///
  /// By default, the sheet sizes itself as big as its child.
  /// {@endtemplate}
  final double? minHeight;

  /// {@template perceive_slidable.closeSheetOnBackButtonPressed}
  /// If true, closes the sheet when it is open and prevents the route
  /// from being popped.
  /// {@endtemplate}
  final bool closeSheetOnBackButtonPressed;

  /// {@template perceive_slidable.isBackDropInteractable}
  /// If true, the backDrop will also be interactable so any gesture
  /// that is applied to the backDrop will be delegated to the sheet
  /// itself.
  /// {@endtemplate}
  final bool isBackdropInteractable;

  /// A widget that is placed behind the sheet.
  ///
  /// You can apply a parallax effect to this widget by
  /// setting the [parallaxSpec] parameter.
  final Widget? body;

  /// {@template perceive_slidable.parallaxSpec}
  /// A [ParallaxSpec] to create a parallax effect.
  ///
  /// The parallax effect is an effect that appears when different layers of backgrounds
  /// are moved at different speeds and thereby create the effect of motion and depth. By moving
  /// the [SlidingSheet] faster than the [body] the depth effect is achieved.
  /// {@endtemplate}
  final ParallaxSpec? parallaxSpec;

  /// {@template perceive_slidable.axisAlignment}
  /// How to align the sheet on the horizontal axis when the available width is bigger
  /// than the `maxWidth` of the sheet.
  ///
  /// The value must be in the range from `-1.0` (far left) and `1.0` (far right).
  ///
  /// Defaults to `0.0` (center).
  /// {@endTemplate}
  final double axisAlignment;

  /// {@template perceive_slidable.extendBody}
  /// Whether to extend the scrollable body of the sheet under
  /// header and/or footer.
  /// {@endTemplate}
  final bool extendBody;

  /// {@template perceive_slidable.liftOnScrollHeaderElevation}
  /// The elevation of the header when the content scrolls under it.
  /// {@endTemplate}
  final double liftOnScrollHeaderElevation;

  /// {@template perceive_slidable.liftOnScrollFooterElevation}
  /// The elevation of the footer when there content scrolls under it.
  /// {@endTemplate}
  final double liftOnScrollFooterElevation;

  // * SlidingSheetDialog fields

  /// {@template perceive_slidable.isDismissable}
  /// If false, the `SlidingSheetDialog` will not be dismissable.
  ///
  /// That means that the user wont be able to close the sheet using gestures or back button.
  /// {@endtemplate}
  final bool isDismissable;

  /// {@template perceive_slidable.onDismissPrevented}
  /// A callback that gets invoked when a user tried to dismiss the dialog
  /// while [isDimissable] is set to `true`.
  ///
  /// The `backButton` flag indicates whether the user tried to dismiss the sheet
  /// using the backButton, while the `backDrop` flag indicates whether the user tried
  /// to dismiss the sheet by tapping the backdrop.
  /// {@endtemplate}
  final OnDismissPreventedCallback? onDismissPrevented;

  final SystemUiOverlayStyle? systemUiOverlayStyle;

  final SystemUiOverlayStyle? systemUiOverlayStyleWhenExpanded;

  final SlidingSheetStateController? slidingSheetStateController;

  /// Creates a sheet than can be dragged and scrolled in a single gesture to be
  /// placed inside you widget tree.
  SlidingSheet({
    Key? key,
    this.builder,
    this.customBuilder,
    this.headerBuilder,
    this.footerBuilder,
    this.snapSpec = const SnapSpec(),
    this.duration = const Duration(milliseconds: 1000),
    this.slidingSheetStateController,
    this.color,
    this.backdropColor,
    this.shadowColor = Colors.black54,
    this.elevation = 0.0,
    this.padding,
    this.avoidStatusBar = false,
    this.margin,
    this.marginWhenExpanded,
    this.border,
    this.cornerRadius = 0.0,
    this.cornerRadiusWhenExpanded = 0.0,
    this.closeOnBackdropTap = false,
    this.listener,
    this.controller,
    this.scrollSpec = const ScrollSpec(overscroll: false),
    this.maxWidth = double.infinity,
    this.minHeight,
    this.closeSheetOnBackButtonPressed = false,
    this.isBackdropInteractable = false,
    this.body,
    this.parallaxSpec,
    this.axisAlignment = 0.0,
    this.extendBody = false,
    this.liftOnScrollHeaderElevation = 0.0,
    this.liftOnScrollFooterElevation = 0.0,
    this.isDismissable = true,
    this.onDismissPrevented,
    this.systemUiOverlayStyle,
    this.systemUiOverlayStyleWhenExpanded,
  })  : assert(builder != null || customBuilder != null),
        assert(builder == null || customBuilder == null),
        assert(snapSpec.snappings.isNotEmpty,
            'There must be at least one extent to snap in between.'),
        assert(snapSpec.minSnap <= snapSpec.maxSnap,
            'The min and max snaps cannot be equal.'),
        assert(axisAlignment >= -1.0 && axisAlignment <= 1.0),
        assert(liftOnScrollHeaderElevation >= 0.0),
        assert(liftOnScrollFooterElevation >= 0.0),
        super(key: key);

  /// Creates a bottom sheet dialog than can be dragged and
  /// scrolled in a single gesture.
  factory SlidingSheet.dialog({
    Key? key,
    SheetListener? listener,
    SheetController? controller,
    SheetBuilder? builder,
    CustomSheetBuilder? customBuilder,
    SheetBuilder? headerBuilder,
    SheetBuilder? footerBuilder,
    SnapSpec snapSpec = const SnapSpec(),
    Duration duration = const Duration(milliseconds: 800),
    Color? color,
    Color backdropColor = Colors.black54,
    Color? shadowColor,
    double elevation = 0.0,
    EdgeInsets? padding,
    bool avoidStatusBar = false,
    EdgeInsets? margin,
    EdgeInsets? marginWhenExpanded,
    Border? border,
    double cornerRadius = 0.0,
    double? cornerRadiusWhenExpanded = 0.0,
    bool closeOnBackdropTap = true,
    ScrollSpec scrollSpec = const ScrollSpec(overscroll: false),
    double maxWidth = double.infinity,
    double? minHeight,
    bool closeSheetOnBackButtonPressed = true,
    bool isBackdropInteractable = true,
    Widget? body,
    ParallaxSpec? parallaxSpec,
    double axisAlignment = 0.0,
    bool extendBody = false,
    double liftOnScrollHeaderElevation = 0.0,
    double liftOnScrollFooterElevation = 0.0,
    bool isDismissable = true,
    OnDismissPreventedCallback? onDismissPrevented,
    SystemUiOverlayStyle? systemUiOverlayStyle,
    SystemUiOverlayStyle? systemUiOverlayStyleWhenExpanded,
  }) {
    return SlidingSheet(
      key: key,
      builder: builder,
      customBuilder: customBuilder,
      headerBuilder: headerBuilder,
      footerBuilder: footerBuilder,
      controller: controller,
      listener: listener,
      snapSpec: snapSpec,
      duration: duration,
      avoidStatusBar: avoidStatusBar,
      axisAlignment: axisAlignment,
      backdropColor: backdropColor,
      body: body,
      border: border,
      closeOnBackdropTap: closeOnBackdropTap,
      closeSheetOnBackButtonPressed: closeSheetOnBackButtonPressed,
      color: color,
      cornerRadius: cornerRadius,
      cornerRadiusWhenExpanded: cornerRadiusWhenExpanded,
      elevation: elevation,
      extendBody: extendBody,
      isBackdropInteractable: isBackdropInteractable,
      isDismissable: isDismissable,
      liftOnScrollFooterElevation: liftOnScrollFooterElevation,
      liftOnScrollHeaderElevation: liftOnScrollHeaderElevation,
      margin: margin,
      marginWhenExpanded: marginWhenExpanded,
      maxWidth: maxWidth,
      minHeight: minHeight,
      onDismissPrevented: onDismissPrevented,
      padding: padding,
      parallaxSpec: parallaxSpec,
      scrollSpec: scrollSpec,
      shadowColor: shadowColor,
      systemUiOverlayStyle: systemUiOverlayStyle,
      systemUiOverlayStyleWhenExpanded: systemUiOverlayStyleWhenExpanded,
    );
  }

  @override
  _SlidingSheetState createState() => _SlidingSheetState();
}

class _SlidingSheetState extends State<SlidingSheet> with TickerProviderStateMixin {
  final GlobalKey childKey = GlobalKey();
  final GlobalKey headerKey = GlobalKey();
  final GlobalKey footerKey = GlobalKey();

  bool get hasHeader => widget.headerBuilder != null;
  bool get hasFooter => widget.footerBuilder != null;

  late List<double> snappings;

  double childHeight = 0;
  double headerHeight = 0;
  double footerHeight = 0;
  double availableHeight = 0;

  // Whether the dialog completed its initial fly in
  bool didCompleteInitialRoute = false;
  // Whether a dismiss was already triggered by the sheet itself
  // and thus further route pops can be safely ignored
  bool dismissUnderway = false;
  // Whether the drag on a delegating widget (such as the backdrop)
  // did start, when the sheet was not fully collapsed
  bool didStartDragWhenNotCollapsed = false;

  _SheetExtent? extent;
  SheetController? sheetController;
  late final _SlidingSheetScrollController controller = _SlidingSheetScrollController(
    this,
  )..addListener(_listener);

  bool get isCustom => widget.customBuilder != null;

  // Whether the sheet has drawn its first frame.
  bool isLaidOut = false;
  // The total height of all sheet components.
  double get sheetHeight =>
      childHeight + headerHeight + footerHeight + padding.vertical + borderHeight;
  // The maxiumum height that this sheet will cover.
  double get maxHeight => math.min(sheetHeight, availableHeight);
  bool get isScrollable => sheetHeight >= availableHeight;

  double get currentExtent => (extent?.currentExtent ?? minExtent).clamp(0.0, 1.0);
  set currentExtent(double value) => extent?.currentExtent = value;
  double get headerExtent =>
      isLaidOut ? (headerHeight + (borderHeight / 2)) / availableHeight : 0.0;
  double get footerExtent =>
      isLaidOut ? (footerHeight + (borderHeight / 2)) / availableHeight : 0.0;
  double get headerFooterExtent => headerExtent + footerExtent;
  double get minExtent => snappings[isDialog ? 1 : 0].clamp(0.0, 1.0);
  double get maxExtent => snappings.last.clamp(0.0, 1.0);
  double get initialExtent =>
      snapSpec.initialSnap != null ? _normalizeSnap(snapSpec.initialSnap!) : minExtent;

  bool get isDialog => _SheetRoute.of(context) != null;
  ScrollSpec get scrollSpec => widget.scrollSpec;
  SnapSpec get snapSpec => widget.snapSpec;
  SnapPositioning get snapPositioning => snapSpec.positioning;

  double get borderHeight => (widget.border?.top.width ?? 0) * 2;
  EdgeInsets get padding {
    final begin = widget.padding ?? const EdgeInsets.all(0);

    if (!widget.avoidStatusBar || !isLaidOut) {
      return begin;
    }

    final statusBarHeight = MediaQuery.of(context).viewPadding.top;
    final end = begin.copyWith(top: begin.top + statusBarHeight);
    return EdgeInsets.lerp(begin, end, lerpFactor)!;
  }

  double get lerpFactor {
    if (maxExtent != 1.0 && isLaidOut) return 0.0;

    final snap = snappings[math.max(snappings.length - 2, 0)];
    return Interval(
      snap >= 0.7 ? snap : 0.85,
      1.0,
    ).transform(currentExtent);
  }

  // The current state of this sheet.
  SheetState get state => SheetState(
        extent,
        extent: _reverseSnap(currentExtent),
        minExtent: _reverseSnap(minExtent),
        maxExtent: _reverseSnap(maxExtent),
        isLaidOut: isLaidOut,
      );

  // A notifier that a child SheetListenableBuilder can inherit to
  final ValueNotifier<SheetState> stateNotifier = ValueNotifier(SheetState.inital());

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if(widget.slidingSheetStateController != null){
      widget.slidingSheetStateController!._bind(this);
    }

    _updateSnappingsAndExtent();

    extent = _SheetExtent(
      controller,
      isDialog: isDialog,
      snappings: snappings,
      listener: (extent) => _listener(),
    );

    _assignSheetController();
    _measure();

    if (isDialog) {
      _flyInDialog();
    } else {
      didCompleteInitialRoute = true;
      // Set the inital extent after the first frame.
      postFrame(
        () => setState(
          () => currentExtent = initialExtent,
        ),
      );
    }
  }

  void _flyInDialog() {
    postFrame(() async {
      // Snap to the initial snap with a one frame delay when the
      // extents have been correctly calculated.
      await snapToExtent(initialExtent);
      setState(() => didCompleteInitialRoute = true);
    });

    _SheetRoute.of(context)?.popped.then(
      (_) {
        if (!dismissUnderway) {
          dismissUnderway = true;
          controller.jumpTo(controller.offset);
          // When the route gets popped we animate fully out - not just
          // to the minExtent.
          controller.snapToExtent(0.0, this, clamp: false);
        }
      },
    );
  }

  @override
  void didUpdateWidget(SlidingSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _assignSheetController();

    // Animate to the next snap if the SnapSpec changed and the sheet
    // is currently not interacted with.
    if (oldWidget.snapSpec != snapSpec) {
      _updateSnappingsAndExtent();
      _nudgeToNextSnap();
    }
  }

  void _listener() {
    if (isLaidOut) {
      final state = this.state;

      stateNotifier.value = state;
      widget.listener?.call(state);
      sheetController?._state = state;
    }
  }

  // Measure the height of all sheet components.
  void _measure() {
    postFrame(() {
      final child = childKey.currentContext?.findRenderObject() as RenderBox?;
      final header = headerKey.currentContext?.findRenderObject() as RenderBox?;
      final footer = footerKey.currentContext?.findRenderObject() as RenderBox?;

      final isChildLaidOut = child?.hasSize == true;
      final prevChildHeight = childHeight;
      childHeight = isChildLaidOut ? child!.size.height : 0;

      final isHeaderLaidOut = header?.hasSize == true;
      final prevHeaderHeight = headerHeight;
      headerHeight = isHeaderLaidOut ? header!.size.height : 0;

      final isFooterLaidOut = footer?.hasSize == true;
      final prevFooterHeight = footerHeight;
      footerHeight = isFooterLaidOut ? footer!.size.height : 0;

      isLaidOut = true;

      if (mounted &&
          (childHeight != prevChildHeight ||
              headerHeight != prevHeaderHeight ||
              footerHeight != prevFooterHeight)) {
        _updateSnappingsAndExtent();
        setState(() {});
      }
    });
  }

  // A snap is defined relative to its availableHeight.
  // Here we handle all available snap positions and normalize them
  // to the availableHeight.
  double _normalizeSnap(double snap) {
    void isValidRelativeSnap([String? message]) {
      assert(
        SnapSpec.isSnap(snap) || (snap >= 0.0 && snap <= 1.0),
        message ?? 'Relative snap $snap is not in the range [0..1].',
      );
    }

    if (availableHeight > 0) {
      final num maxPossibleExtent = () {
        if (isCustom) {
          return 1.0;
        } else {
          return isLaidOut ? (sheetHeight / availableHeight).clamp(0.0, 1.0) : 1.0;
        }
      }();

      double extent = snap;
      switch (snapPositioning) {
        case SnapPositioning.relativeToAvailableSpace:
          isValidRelativeSnap();
          break;
        case SnapPositioning.relativeToSheetHeight:
          isValidRelativeSnap();
          extent = (snap * maxHeight) / availableHeight;
          break;
        case SnapPositioning.pixelOffset:
          extent = snap / availableHeight;
          break;
        default:
          return snap.clamp(0.0, 1.0);
      }

      if (snap == SnapSpec.headerSnap) {
        assert(hasHeader, 'There is no available header to snap to!');
        extent = headerExtent;
      } else if (snap == SnapSpec.footerSnap) {
        assert(hasFooter, 'There is no available footer to snap to!');
        extent = footerExtent;
      } else if (snap == SnapSpec.headerFooterSnap) {
        assert(
          hasHeader || hasFooter,
          'There is neither a header nor a footer to snap to!',
        );
        extent = headerFooterExtent;
      } else if (snap == double.infinity) {
        extent = maxPossibleExtent as double;
      }

      return math.min(extent, maxPossibleExtent).clamp(0.0, 1.0) as double;
    } else {
      return snap.clamp(0.0, 1.0);
    }
  }

  // Reverse a normalized snap.
  double _reverseSnap(double snap) {
    if (isLaidOut && childHeight > 0) {
      switch (snapPositioning) {
        case SnapPositioning.relativeToAvailableSpace:
          return snap;
        case SnapPositioning.relativeToSheetHeight:
          return snap * (availableHeight / sheetHeight);
        case SnapPositioning.pixelOffset:
          return snap * availableHeight;
        default:
          return snap.clamp(0.0, 1.0);
      }
    } else {
      return snap.clamp(0.0, 1.0);
    }
  }

  void _updateSnappingsAndExtent() {
    snappings = snapSpec.snappings.map(_normalizeSnap).toList()..sort();

    // Dialogs must have a zero snap.
    if (isDialog && snappings.first != 0.0) {
      snappings.insert(0, 0.0);
    }

    if (extent != null) {
      extent!
        ..snappings = snappings
        ..targetHeight = maxHeight
        ..childHeight = childHeight
        ..headerHeight = headerHeight
        ..footerHeight = footerHeight
        ..availableHeight = availableHeight
        ..maxExtent = maxExtent
        ..minExtent = minExtent;
    }
  }

  // Assign the controller functions to actual methods.
  void _assignSheetController() {
    if (sheetController != null) return;

    // Always assing a SheetController to be able to inherit from it
    sheetController = widget.controller ?? SheetController();

    // Assign the controller functions to the state functions.
    sheetController!._scrollTo = scrollTo;
    sheetController!._snapToExtent = (snap, {duration, clamp}) {
      return snapToExtent(_normalizeSnap(snap), duration: duration, clamp: clamp);
    };
    sheetController!._expand = () => snapToExtent(maxExtent);
    sheetController!._collapse = () => snapToExtent(minExtent);

    if (!isDialog) {
      sheetController!._rebuild = () {
        setState(() {});
        _measure();
      };

      sheetController!._show = () async {
        if (state.isHidden) return snapToExtent(minExtent, clamp: false);
      };

      sheetController!._hide = () async {
        if (state.isShown) return snapToExtent(0.0, clamp: false);
      };
    }
  }

  Future<void> snapToExtent(
    double snap, {
    Duration? duration,
    double velocity = 0,
    bool? clamp,
  }) async {
    if (!isLaidOut) return;
    duration ??= widget.duration;

    if (!state.isAtTop) {
      duration *= 0.5;
      await controller.animateTo(
        0.0,
        duration: duration,
        curve: Curves.easeInCubic,
      );
    }

    await controller.snapToExtent(
      snap,
      this,
      duration: duration,
      velocity: velocity,
      clamp: clamp ?? (!isDialog || (isDialog && snap != 0.0)),
    );
  }

  Future<void> scrollTo(double offset, {Duration? duration, Curve? curve}) async {
    if (!isLaidOut) return;
    duration ??= widget.duration;

    if (!extent!.isAtMax) {
      duration *= 0.5;
      await snapToExtent(
        maxExtent,
        duration: duration,
      );
    }

    await controller.animateTo(
      offset,
      duration: duration,
      curve: curve ?? (!extent!.isAtMax ? Curves.easeOutCirc : Curves.ease),
    );
  }

  void _nudgeToNextSnap() {
    if (!controller.inInteraction && state.isShown) {
      controller.delegateFling();
    }
  }

  void _pop(double velocity) {
    if (isDialog && !dismissUnderway && Navigator.canPop(context)) {
      dismissUnderway = true;
      Navigator.pop(context);
      snapToExtent(0.0, velocity: velocity);
    } else if (!isDialog) {
      final num fractionCovered =
          ((currentExtent - minExtent) / (maxExtent - minExtent)).clamp(0.0, 1.0);
      final timeFraction = 1.0 - (fractionCovered * 0.5);
      snapToExtent(minExtent, duration: widget.duration * timeFraction);
    }
  }

  // Ensure that the sheet sizes itself correctly when the
  // constraints change.
  void _adjustSnapForIncomingConstraints(double previousHeight) {
    if (previousHeight > 0.0 && previousHeight != availableHeight && state.isShown) {
      _updateSnappingsAndExtent();

      final num changeAdjustedExtent =
          ((currentExtent * previousHeight) / availableHeight)
              .clamp(minExtent, maxExtent);

      final isAroundFixedSnap = snappings.any(
        (snap) => (snap - changeAdjustedExtent).abs() < 0.01,
      );

      // Only update the currentExtent when its sitting at an extent that
      // is depenent on a fixed height, such as SnapSpec.headerSnap or absolute
      // snap values.
      if (isAroundFixedSnap) {
        currentExtent = changeAdjustedExtent as double;
      }
    }
  }

  void _onDismissPrevented({bool backButton = false, bool backDrop = false}) {
    widget.onDismissPrevented?.call(backButton, backDrop);
  }

  void _handleNonDismissableSnapBack() {
    // didEndScroll doesn't work reliably in ScrollPosition. There
    // should be a better solution to this problem.
    if (isDialog && !widget.isDismissable && currentExtent < minExtent) {
      snapToExtent(minExtent);
      _onDismissPrevented();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget result = LayoutBuilder(
      builder: (context, constrainst) {
        _measure();

        final previousHeight = availableHeight;
        availableHeight = constrainst.biggest.height;
        _adjustSnapForIncomingConstraints(previousHeight);

        final sheet = NotificationListener<SizeChangedLayoutNotification>(
          onNotification: (notification) {
            _measure();
            return true;
          },
          // Hide the sheet for the first frame until the extents are
          // correctly measured.
          child: Stack(
            children: <Widget>[
              _buildBackdrop(),
              _buildSheet(),
            ],
          ),
        );

        if (widget.body == null) {
          return sheet;
        } else {
          return Stack(
            children: <Widget>[
              _buildBody(),
              sheet,
            ],
          );
        }
      },
    );

    result = _InheritedSheetState(stateNotifier, result);

    if (!widget.closeSheetOnBackButtonPressed && !isDialog) {
      return result;
    }

    final sheet = WillPopScope(
      onWillPop: () async {
        if (isDialog) {
          if (!widget.isDismissable) {
            _onDismissPrevented(backButton: true);
            return false;
          } else {
            return true;
          }
        } else {
          if (!state.isCollapsed) {
            snapToExtent(minExtent);
            return false;
          } else {
            return true;
          }
        }
      },
      child: result,
    );

    if (widget.systemUiOverlayStyle == null &&
        widget.systemUiOverlayStyleWhenExpanded == null) {
      return sheet;
    }

    return ValueListenableBuilder<double?>(
      child: sheet,
      valueListenable: extent!._currentExtent,
      builder: (context, extent, child) {
        final overlayStyle = extent == 1.0
            ? widget.systemUiOverlayStyleWhenExpanded
            : widget.systemUiOverlayStyle;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle ?? const SystemUiOverlayStyle(),
          child: child!,
        );
      },
    );
  }

  Widget _buildSheet() {
    final sheet = Builder(
      builder: (context) => Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              if (!widget.extendBody) SizedBox(height: headerHeight),
              Expanded(child: _buildScrollView()),
              if (!widget.extendBody) SizedBox(height: footerHeight),
            ],
          ),
          if (hasHeader)
            Align(
              alignment: Alignment.topCenter,
              child: ElevatedContainer(
                shadowColor: widget.shadowColor,
                elevation: widget.liftOnScrollHeaderElevation,
                elevateWhen: (state) => isScrollable && !state.isAtTop,
                child: SizeChangedLayoutNotifier(
                  key: headerKey,
                  child: delegateInteractions(
                    widget.headerBuilder!(context, state),
                  ),
                ),
              ),
            ),
          if (hasFooter)
            Align(
              alignment: Alignment.bottomCenter,
              child: ElevatedContainer(
                shadowColor: widget.shadowColor,
                elevation: widget.liftOnScrollFooterElevation,
                elevateWhen: (state) => !state.isCollapsed && !state.isAtBottom,
                child: SizeChangedLayoutNotifier(
                  key: footerKey,
                  child: delegateInteractions(
                    widget.footerBuilder!(context, state),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return Align(
      alignment: Alignment(widget.axisAlignment, -1.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: SizedBox.expand(
          child: ValueListenableBuilder(
            child: sheet,
            valueListenable: extent!._currentExtent,
            builder: (context, extent, sheet) {
              final translation = () {
                if (headerFooterExtent > 0.0) {
                  return 1.0 -
                      (currentExtent.clamp(0.0, headerFooterExtent) / headerFooterExtent);
                } else {
                  return 0.0;
                }
              }();

              return Invisible(
                invisible: !isLaidOut || currentExtent == 0.0,
                child: FractionallySizedBox(
                  heightFactor:
                      isLaidOut ? currentExtent.clamp(headerFooterExtent, 1.0) : 1.0,
                  alignment: Alignment.bottomCenter,
                  child: FractionalTranslation(
                    translation: Offset(0, translation),
                    child: SheetContainer(
                      color: widget.color ?? Theme.of(context).cardColor,
                      border: widget.border,
                      margin: EdgeInsets.lerp(
                        widget.margin,
                        widget.marginWhenExpanded,
                        lerpFactor,
                      ),
                      padding: EdgeInsets.fromLTRB(
                        padding.left,
                        hasHeader ? padding.top : 0.0,
                        padding.right,
                        hasFooter ? padding.bottom : 0.0,
                      ),
                      elevation: widget.elevation,
                      shadowColor: widget.shadowColor,
                      customBorders: BorderRadius.vertical(
                        top: Radius.circular(lerpDouble(widget.cornerRadius,
                                widget.cornerRadiusWhenExpanded, lerpFactor) ??
                            0),
                      ),
                      child: sheet,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScrollView() {
    Widget scrollView = Listener(
      onPointerUp: (_) => _handleNonDismissableSnapBack(),
      child: () {
        if (widget.customBuilder != null) {
          return Container(
            key: childKey,
            child: widget.customBuilder!(context, controller, state),
          );
        }

        return SingleChildScrollView(
          controller: controller,
          physics: scrollSpec.physics,
          padding: EdgeInsets.only(
            top: !hasHeader ? padding.top : 0.0,
            bottom: !hasFooter ? padding.bottom : 0.0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: widget.minHeight ?? 0.0),
            child: SizeChangedLayoutNotifier(
              key: childKey,
              child: widget.builder!(context, state),
            ),
          ),
        );
      }(),
    );

    if (scrollSpec.showScrollbar) {
      scrollView = Scrollbar(
        child: scrollView,
      );
    }

    // Add the overscroll if required again if required
    if (scrollSpec.overscroll) {
      scrollView = GlowingOverscrollIndicator(
        axisDirection: AxisDirection.down,
        color: scrollSpec.overscrollColor ?? Theme.of(context).accentColor,
        child: scrollView,
      );
    }

    return scrollView;
  }

  Widget _buildBody() {
    final spec = widget.parallaxSpec;

    if (spec == null || !spec.enabled || spec.amount <= 0.0) {
      return widget.body ?? const SizedBox();
    }

    return ValueListenableBuilder(
      valueListenable: extent!._currentExtent,
      // ignore: sort_child_properties_last
      child: widget.body,
      builder: (context, dynamic _, body) {
        final amount = spec.amount;
        final defaultMaxExtent =
            snappings.length > 2 ? snappings[snappings.length - 2] : this.maxExtent;
        final maxExtent =
            spec.endExtent != null ? _normalizeSnap(spec.endExtent!) : defaultMaxExtent;
        assert(maxExtent > minExtent,
            'The endExtent must be greater than the min snap extent you set on the SnapSpec');
        final maxOffset = (maxExtent - minExtent) * availableHeight;
        final num fraction =
            ((currentExtent - minExtent) / (maxExtent - minExtent)).clamp(0.0, 1.0);

        return Padding(
          padding: EdgeInsets.only(bottom: (amount * maxOffset) * fraction),
          child: body,
        );
      },
    );
  }

  Widget _buildBackdrop() {
    return ValueListenableBuilder(
      valueListenable: extent!._currentExtent,
      builder: (context, dynamic value, child) {
        final opacity = () {
          if (!widget.isDismissable && !dismissUnderway && didCompleteInitialRoute) {
            return 1.0;
          } else if (currentExtent != 0.0) {
            if (isDialog) {
              return (currentExtent / minExtent).clamp(0.0, 1.0);
            } else {
              final secondarySnap = snappings.length > 2 ? snappings[1] : maxExtent;
              return ((currentExtent - minExtent) / (secondarySnap - minExtent))
                  .clamp(0.0, 1.0);
            }
          } else {
            return 0.0;
          }
        }();

        final backDrop = IgnorePointer(
          ignoring: opacity < 0.05,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: widget.backdropColor,
            ),
          ),
        );

        void onTap() =>
            widget.isDismissable ? _pop(0.0) : _onDismissPrevented(backDrop: true);

        // see: https://github.com/BendixMa/sliding-sheet/issues/30
        if (opacity >= 0.05 || didStartDragWhenNotCollapsed) {
          if (widget.isBackdropInteractable) {
            return delegateInteractions(backDrop,
                onTap: widget.closeOnBackdropTap ? onTap : null);
          } else if (widget.closeOnBackdropTap) {
            return GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.translucent,
              child: backDrop,
            );
          }
        }

        return backDrop;
      },
    );
  }

  Widget delegateInteractions(Widget child, {VoidCallback? onTap}) {
    var start = 0.0, end = 0.0;

    void onDragEnd([double velocity = 0.0]) {
      controller.delegateFling(velocity);

      // If a header was dragged, but the scroll view is not at the top
      // animate to the top when the drag has ended.
      if (!state.isAtTop && (start - end).abs() > 15.0) {
        controller.animateTo(0.0, duration: widget.duration * 0.5, curve: Curves.ease);
      }

      _handleNonDismissableSnapBack();
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: (details) {
        start = details.localPosition.dy;
        end = start;

        didStartDragWhenNotCollapsed = currentExtent > snappings.first;
      },
      onVerticalDragUpdate: (details) {
        end = details.localPosition.dy;
        final delta = details.delta.dy;

        // Do not delegate upward drag when the sheet is fully expanded
        // because headers or backdrops should not be able to scroll the
        // sheet, only to drag it between min and max extent.
        final shouldDelegate = !delta.isNegative || currentExtent < maxExtent;
        if (shouldDelegate) {
          controller.delegateDrag(delta);
        }
      },
      onVerticalDragEnd: (details) {
        final deltaY = details.velocity.pixelsPerSecond.dy;
        final velocity = swapSign(deltaY);

        final shouldDelegate = !deltaY.isNegative || currentExtent < maxExtent;
        if (shouldDelegate) {
          onDragEnd(velocity);
        }

        setState(() => didStartDragWhenNotCollapsed = false);
      },
      onVerticalDragCancel: onDragEnd,
      child: child,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// A data class containing state information about the [SlidingSheet]
/// such as the extent and scroll offset.
class SheetState {
  /// The current extent the sheet covers.
  final double extent;

  /// The minimum extent that the sheet will cover.
  final double minExtent;

  /// The maximum extent that the sheet will cover
  /// until it begins scrolling.
  final double maxExtent;

  /// Whether the sheet has finished measuring its children and computed
  /// the correct extents. This takes until the first frame was drawn.
  final bool isLaidOut;

  /// The progress between [minExtent] and [maxExtent] of the current [extent].
  /// A progress of 1 means the sheet is fully expanded, while
  /// a progress of 0 means the sheet is fully collapsed.
  final double progress;

  /// Whether the [SlidingSheet] has reached its maximum extent.
  final bool isExpanded;

  /// Whether the [SlidingSheet] has reached its minimum extent.
  final bool isCollapsed;

  /// Whether the [SlidingSheet] has a [scrollOffset] of zero.
  final bool isAtTop;

  /// Whether the [SlidingSheet] has reached its maximum scroll extent.
  final bool isAtBottom;

  /// Whether the sheet is hidden to the user.
  final bool isHidden;

  /// Whether the sheet is visible to the user.
  final bool isShown;

  /// The scroll offset of the Scrollable inside the sheet
  /// at the time this [SheetState] was emitted.
  final double scrollOffset;

  final _SheetExtent? _extent;

  /// A data class containing state information about the [SlidingSheet]
  /// at the time this state was emitted.
  SheetState(
    this._extent, {
    required this.extent,
    required this.isLaidOut,
    required this.maxExtent,
    required double minExtent,
    // On Bottomsheets it is possible for min and maxExtents to be the same (when you only set one snap).
    // Thus we have to account for this and set the minExtent to be zero.
  })  : minExtent = minExtent != maxExtent ? minExtent : 0.0,
        progress = isLaidOut
            ? ((extent - minExtent) / (maxExtent - minExtent)).clamp(0.0, 1.0)
            : 0.0,
        isExpanded = toPrecision(extent) >= toPrecision(maxExtent),
        isCollapsed = toPrecision(extent) <= toPrecision(minExtent),
        isAtTop = _extent?.isAtTop ?? true,
        isAtBottom = _extent?.isAtBottom ?? false,
        isHidden = extent <= 0.0,
        isShown = extent > 0.0,
        scrollOffset = _extent?.scrollOffset ?? 0.0;

  /// A default constructor which can be used to initial `ValueNotifers` for instance.
  SheetState.inital()
      : this(null, extent: 0.0, minExtent: 0.0, maxExtent: 1.0, isLaidOut: false);

  /// The current scroll offset of the [Scrollable] inside the sheet.
  double get currentScrollOffset => _extent?.scrollOffset ?? 0.0;

  /// The maximum amount the Scrollable inside the sheet can scroll.
  double get maxScrollExtent => _extent?.maxScrollExtent ?? 0.0;

  /// private
  static ValueNotifier<SheetState> notifier(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_InheritedSheetState>()!.state;
  }

  @override
  String toString() {
    return 'SheetState(extent: $extent, minExtent: $minExtent, maxExtent: $maxExtent, isLaidOut: $isLaidOut, progress: $progress, scrollOffset: $scrollOffset, maxScrollExtent: $maxScrollExtent, isExpanded: $isExpanded, isCollapsed: $isCollapsed, isAtTop: $isAtTop, isAtBottom: $isAtBottom, isHidden: $isHidden, isShown: $isShown)';
  }
}

class _InheritedSheetState extends InheritedWidget {
  final ValueNotifier<SheetState> state;
  const _InheritedSheetState(
    this.state,
    Widget child,
  ) : super(child: child);

  @override
  bool updateShouldNotify(_InheritedSheetState oldWidget) => state != oldWidget.state;
}

/// A controller for a [SlidingSheet].
class SheetController {
  /// Inherit the [SheetController] from the closest [SlidingSheet].
  ///
  /// Every [SlidingSheet] has a [SheetController], even if you didn't assign
  /// one explicitly. This allows you to call functions on the controller from child
  /// widgets without having to pass a [SheetController] around.
  static SheetController? of(BuildContext context) {
    return context.findAncestorStateOfType<_SlidingSheetState>()?.sheetController;
  }

  /// Animates the sheet to the [extent].
  ///
  /// The [extent] will be clamped to the minimum and maximum extent.
  /// If the scrolling child is not at the top, it will scroll to the top
  /// first and then animate to the specified extent.
  Future<void>? snapToExtent(double extent, {Duration? duration, bool clamp = true}) =>
      _snapToExtent?.call(extent, duration: duration, clamp: clamp);
  Future<void> Function(double extent, {Duration? duration, bool? clamp})? _snapToExtent;

  /// Animates the scrolling child to a specified offset.
  ///
  /// If the sheet is not fully expanded it will expand first and then
  /// animate to the given [offset].
  Future<void>? scrollTo(double offset, {Duration? duration, Curve? curve}) =>
      _scrollTo?.call(offset, duration: duration, curve: curve);
  Future<void> Function(double offset, {Duration? duration, Curve? curve})? _scrollTo;

  /// Calls every builder function of the sheet to rebuild the widgets with
  /// the current [SheetState].
  ///
  /// This function can be used to reflect changes on the [SlidingSheet]
  /// without calling `setState(() {})` on the parent widget if that would be
  /// too expensive.
  void rebuild() => _rebuild?.call();
  VoidCallback? _rebuild;

  /// Fully collapses the sheet.
  ///
  /// Short-hand for calling `snapToExtent(minExtent)`.
  Future<void>? collapse() => _collapse?.call();
  Future<void> Function()? _collapse;

  /// Fully expands the sheet.
  ///
  /// Short-hand for calling `snapToExtent(maxExtent)`.
  Future<void>? expand() => _expand?.call();
  Future<void> Function()? _expand;

  /// Reveals the [SlidingSheet] if it is currently hidden.
  Future<void>? show() => _show?.call();
  Future<void> Function()? _show;

  /// Slides the sheet off to the bottom and hides it.
  Future<void>? hide() => _hide?.call();
  Future<void> Function()? _hide;

  /// The current [SheetState] of this [SlidingSheet].
  SheetState? get state => _state;
  SheetState? _state;
}

/// Notifies [SwipePollCard] when the frames have been loaded in
/// Is used to set the duration and frame count for the [GifAnimationController]
class SlidingSheetStateController extends ChangeNotifier{
  
  late _SlidingSheetState? _state;

  SlidingSheetStateController();

  ///Binds the controller to the state
  void _bind(_SlidingSheetState bind) => _state = bind;

  Widget? delegateInteractions(Widget child) => _state != null ? _state!.delegateInteractions(child) : null;

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}
