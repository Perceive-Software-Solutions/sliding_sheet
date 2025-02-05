import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fort/fort.dart';
import 'package:perceive_slidable/sliding_sheet.dart';
import 'package:perceive_slidable/src/util/functions.dart';

part 'state.dart';

/// Sliding sheet with a built in page view and page navigation
class PerceiveSlidable extends StatefulWidget {

  //Static variables
  static const double EXPANDED_BORDER_RADIUS = 0;
  static const double INITIAL_BORDER_RADIUS = 32;

  ///Controller for the sheet
  final PerceiveSlidableController? controller;

  ///The custom delegate used to build the sheet
  final PerceiveSlidableDelegate? delegate;

  ///If the sheet should be static or not
  final bool staticSheet;

  // Colors
  /// The background color for the sliding sheet
  final Color? backgroundColor;
  /// The color behind the sliding sheet
  final Color? minBackdropColor;

  // Sheet Extents
  /// Starting extent, does not have a snapping
  final double initialExtent;
  /// The max extent of the sliding sheet
  final double expandedExtent;
  /// The middle resting extent of the sliding sheet
  final double mediumExtent;
  /// The lowest possible extent for the sliding sheet
  final double minExtent;
  /// Any additional snapping
  final List<double>? additionalSnappings;

  // Builders
  /// Optional builder for the initial delegate
  final Widget Function(BuildContext context, dynamic pageObj, Widget spacer, double borderRadius)? header;
  /// The optional builder for the body of the sheet
  final Widget Function(BuildContext context, SheetState?, double)? customBodyBuilder;
  /// The persistent footer on the sliding sheet
  final Widget Function(BuildContext context, SheetState, dynamic pageObject)? footerBuilder;

  /// A persistent header over the navigator, when defined, disables any delegates from building headers
  final Widget Function(BuildContext context, Widget spacer, double borderRadius)? persistentHeader;
  

  /// Listeners
  final Function(double extent)? extentListener;

  // Editors
  final bool isBackgroundIntractable;
  final bool closeOnBackdropTap;
  final bool doesPop;

  const PerceiveSlidable({ 
    Key? key,  
    this.controller,
    this.backgroundColor,
    this.minBackdropColor,
    this.initialExtent = 0.4,
    this.minExtent = 0.0,
    this.mediumExtent = 0.4,
    this.expandedExtent = 1.0,
    this.additionalSnappings,
    this.header,
    this.persistentHeader,
    this.customBodyBuilder,
    this.footerBuilder,
    this.extentListener,
    this.delegate,
    this.staticSheet = false,
    this.isBackgroundIntractable = false,
    this.closeOnBackdropTap = true,
    this.doesPop = true
  }) : super(key: key);

  @override
  _PerceiveSlidableState createState() => _PerceiveSlidableState();

  //Static function
  static double getIntervalFromExtent(double extent, double extentMatcher){
    return Interval(
      extentMatcher > 0.7 ? extentMatcher : 0.85,
      1.0,
    ).transform(extent);
  }
}

class _PerceiveSlidableState extends State<PerceiveSlidable> {

  bool get disableHeader => widget.persistentHeader != null;
  double get statusBarHeight => tower.state.statusBarHeight;

  ///The controller for the state
  late PerceiveSlidableController stateController;

  ///The navigator key
  GlobalKey<NavigatorState> navkey = GlobalKey<NavigatorState>();

  /// SlidingShert Controller
  late SheetController sheetController = SheetController();
  
  ///Used for maintaing the header
  late SlidingSheetStateController slidingSheetStateController = SlidingSheetStateController();

  /// The state for the sliding sheet
  late final Tower<PerceiveSlidableState> tower = PerceiveSlidableState.tower(
    statusBarHeight: MediaQueryData.fromWindow(window).padding.top, 
    initialDelegate: widget.delegate ?? _PerceiveSlidableBaseDelegate(
      extentListener: widget.extentListener, 
      body: widget.customBodyBuilder, 
      header: widget.header
    ),
    initialExtent: widget.initialExtent
  );

  List<PerceiveSlidableDelegate> get delegates => tower.state.delegates ;

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();

    stateController = widget.controller ?? PerceiveSlidableController();
    stateController._bind(this);
  }

  Future<void> snapTo(double extent, {Duration? duration}) async => await (sheetController.snapToExtent(extent, duration: duration) ?? null);

  Future<dynamic> pushPage(PerceiveSlidableDelegate delegate, [Route Function(Widget child)? routeBuilder]) async {
    tower.dispatch(_AddDelegateEvent(delegate));

    Widget delegateBuilder = _PerceiveSlidableDelegateBuilder(
      backgroundColor: widget.backgroundColor,
      controller: stateController,
      sheetStateController: slidingSheetStateController,
      delegate: delegate,
      expandedExtent: widget.expandedExtent,
      initialExtent: sheetController.state!.extent,
      mediumExtent: widget.mediumExtent,
      minExtent: widget.minExtent,
      staticSheet: widget.staticSheet,
      disableHeader: disableHeader,
    );

    final obj = await navkey.currentState?.push(
      routeBuilder?.call(delegateBuilder) ??
      MaterialPageRoute(builder: (context) {
        return delegateBuilder;
      })
    );
    tower.dispatch(_RemoveLastDelegateEvent());
    return obj;
  }

  void sheetListener(SheetState state){
    // debugPrint('Sheet Extent: ${state.extent}');
    final extent = state.extent;
    tower.dispatch(_SetExtentEvent(extent));
    if(widget.extentListener != null){
      widget.extentListener!(extent);
    }
    if(extent == 0.0 && widget.doesPop){
      if(Navigator.canPop(context)){
        Navigator.pop(context);
      }
    }
    for (var delegate in delegates) {
      delegate._delegateSheetStateListener(context, state);
    }
  }


  @override
  Widget build(BuildContext context) {
    double pageHeight = MediaQuery.of(context).size.height;
    double pageWidth = MediaQuery.of(context).size.width;
    
    return SlidingSheet(
      // color: widget.backgroundColor,
      controller: sheetController,
      isBackdropInteractable: widget.isBackgroundIntractable,
      closeOnBackdropTap: widget.closeOnBackdropTap,
      duration: Duration(milliseconds: 300),
      cornerRadius: PerceiveSlidable.INITIAL_BORDER_RADIUS,
      cornerRadiusWhenExpanded: PerceiveSlidable.EXPANDED_BORDER_RADIUS,
      extendBody: true,
      slidingSheetStateController: slidingSheetStateController,
      backdropColor: widget.minBackdropColor,
      listener: sheetListener,
      snapSpec: SnapSpec(
        initialSnap: sheetController.state?.extent ?? widget.initialExtent,
        snappings: [widget.minExtent, widget.mediumExtent, widget.expandedExtent, ...(widget.additionalSnappings ?? [])],
      ),
      customBuilder: (context, controller, state) {

        return SingleChildScrollView(
          controller: controller,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: widget.staticSheet ? ClampingScrollPhysics() : NeverScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: pageHeight,
              minHeight: pageHeight,
              minWidth: pageWidth,
              maxWidth: pageWidth,
            ),
            child: StoreProvider(
              store: tower,
              child: Column(
                children: [
                if(disableHeader)
                  StoreConnector<PerceiveSlidableState, double>(
                    converter: (store) => store.state.extent,
                    builder: (context, extent) {
                      //The animation value for the topExtent animation
                      double topExtentValue = Functions.animateOver(extent, percent: 0.9);
                      return widget.persistentHeader!(
                        context, 
                        Container(height: lerpDouble(0, statusBarHeight, topExtentValue)),
                        lerpDouble(PerceiveSlidable.INITIAL_BORDER_RADIUS, PerceiveSlidable.EXPANDED_BORDER_RADIUS, PerceiveSlidable.getIntervalFromExtent(extent, max(widget.initialExtent, widget.mediumExtent)))!
                      );
                    }
                  ),
                  Expanded(
                    child: Navigator(
                      key: navkey,
                      onGenerateRoute: (settings) => MaterialPageRoute(
                        settings: settings,
                        builder: (context) {
                          return _PerceiveSlidableDelegateBuilder(
                            backgroundColor: widget.backgroundColor,
                            controller: stateController,
                            sheetStateController: slidingSheetStateController,
                            delegate: delegates[0],
                            expandedExtent: widget.expandedExtent,
                            initialExtent: widget.initialExtent,
                            mediumExtent: widget.mediumExtent,
                            minExtent: widget.minExtent,
                            staticSheet: widget.staticSheet,
                            disableHeader: disableHeader,
                          );
                        },
                      )
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      footerBuilder: (context, state){
        return widget.footerBuilder != null ? StoreProvider(
          store: tower,
          child: StoreConnector<PerceiveSlidableState, dynamic>(
            distinct: true,
            converter: (store) => store.state.delegates.last.delegateObject,
            builder: (context, object) {
              return widget.footerBuilder!(context, state, object);
            }
          )
        ) : SizedBox.shrink();
      },
    );
  }
}


///Controller for the sheet
class PerceiveSlidableController extends ChangeNotifier {
  late _PerceiveSlidableState? _state;

  ///Binds the feed state
  void _bind(_PerceiveSlidableState bind) => _state = bind;

  //Called to notify all listners
  void _update() => notifyListeners();

  ///Pushes a new page on the sheet navigator
  Future<dynamic> push(PerceiveSlidableDelegate delegate, [Route Function(Widget child)? routeBuilder]) => _state!.pushPage(delegate, routeBuilder);

  ///Pushes a new page on the sheet navigator
  void pop() => _state!.navkey.currentState?.pop();

  ///Snaps the sheet to a state
  Future<void> snapTo(double extent, {Duration? duration}) => _state!.snapTo(extent, duration: duration);

  SheetController get controller => _state!.sheetController;

  ///Retreives the current extent
  double get extent => _state!.sheetController.state?.extent ?? 0;

  ///Retreives the current sheet state
  SheetState? get sheetState => _state!.sheetController.state;

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}

class _PerceiveSlidableDelegateBuilder extends StatefulWidget {

  final PerceiveSlidableDelegate delegate;
  final PerceiveSlidableController controller;
  final SlidingSheetStateController sheetStateController;
  
  ///If the sheet should be static or not
  final bool staticSheet;
  
  /// Sheet Extents
  final double initialExtent;
  final double expandedExtent;
  final double mediumExtent;
  final double minExtent;

  final bool disableHeader;

  final Color? backgroundColor;

  const _PerceiveSlidableDelegateBuilder({ 
    Key? key,
    required this.delegate,
    required this.controller,
    required this.sheetStateController,
    required this.initialExtent,
    required this.expandedExtent,
    required this.mediumExtent,
    required this.minExtent,
    required this.staticSheet,
    required this.disableHeader,
    required this.backgroundColor
  }) : super(key: key);

  @override
  State<_PerceiveSlidableDelegateBuilder> createState() => _PerceiveSlidableDelegateBuilderState();
}

class _PerceiveSlidableDelegateBuilderState extends State<_PerceiveSlidableDelegateBuilder> with SingleTickerProviderStateMixin {
  
  /// If the sheet is currently snapping
  bool snapping = false;

  Store<PerceiveSlidableState> get tower => StoreProvider.of<PerceiveSlidableState>(context);

  double get statusBarHeight => tower.state.statusBarHeight;

  @override
  void initState(){
    super.initState();

    widget.delegate._bind(this);

    Future.delayed(Duration(milliseconds: 100)).then((value) => rebuild((){}));
  }

  @override
  void dispose() {
    super.dispose();

    widget.delegate._dispose();
  }

  late double lastExtent = widget.controller.extent;

  late Completer<bool> completer = Completer<bool>()..complete(true);

  void rebuild(void Function() fn){
    setState(fn);
  }

  void sheetListener(double extent) async {
    // When the sheet is switching from expanded to unexpanded
    // and the scroll controllers are scrolled, scroll to the top
    if(extent > widget.mediumExtent && extent < widget.expandedExtent){
      if(lastExtent > extent && extent <= (widget.expandedExtent - widget.mediumExtent)/2 + widget.mediumExtent){
        //Closing sheet
        if(widget.delegate.isScrolled){
          scrollUp();
        }
      }
      lastExtent = extent;
    }
  }

  void scrollUp() async {

    if(!completer.isCompleted)
      return;

    // Ensures the scrolling only occurs once
    completer = Completer<bool>();
    List<Future> futures = [];
    widget.delegate.scrollControllers.forEach((e) {futures.add(scrollControllerUp(e));});
    await Future.wait(futures);
    completer.complete(true);
  }

  Future<void> scrollControllerUp(ScrollController controller) async {
    if(controller.hasClients){
      await controller.animateTo(0, duration: Duration(milliseconds: 300), curve: Curves.easeInOutCirc);
    }
  }

  void initiateListener(ScrollController controller){
    controller.addListener(() {
      if(controller.offset <= -50 && widget.controller.extent != widget.minExtent && !snapping){ 
        if(widget.controller.extent == 1.0){
          snapping = true;
          Future.delayed(Duration.zero, () {
            widget.controller.snapTo(widget.mediumExtent, duration: Duration(milliseconds: 300));
            Future.delayed(Duration(milliseconds: 300)).then((value) => {
              snapping = false
            });
          });
        }
        else if(widget.controller.extent == widget.mediumExtent){
          snapping = true;
          Future.delayed(Duration.zero, () {
            widget.controller.snapTo(widget.minExtent, duration: Duration(milliseconds: 300));
          });
          Future.delayed(Duration(milliseconds: 300)).then((value) => {
            snapping = false
          });
        }
      }
    });
  }

  Widget _buildHeader(BuildContext context){



    Widget header = StoreConnector<PerceiveSlidableState, double>(
      converter: (store) => store.state.extent,
      builder: (context, extent) {
        //The animation value for the topExtent animation
        double topExtentValue = Functions.animateOver(extent, percent: 0.9);

        //Border radius interval
        

        return Stack(
          children: [
            widget.delegate.headerBuilder(
              context, 
              widget.delegate.delegateObject, 
              Container(height: lerpDouble(0, statusBarHeight, topExtentValue)),
              lerpDouble(PerceiveSlidable.INITIAL_BORDER_RADIUS, PerceiveSlidable.EXPANDED_BORDER_RADIUS, PerceiveSlidable.getIntervalFromExtent(extent, max(widget.initialExtent, widget.mediumExtent)))!
            ),

            Align(
              alignment: Alignment.topCenter,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: (){
                  if(widget.delegate.isScrolled){
                    scrollUp();
                  }
                },
                child: Container(height: lerpDouble(0, statusBarHeight * 1.3, topExtentValue)),
              ),
            )
          ],
        );
      }
    );

    return widget.sheetStateController.delegateInteractions(header) ?? header;
  }

  Widget _buildBody(BuildContext context){
    double pageHeight = MediaQuery.of(context).size.height;
    double pageWidth = MediaQuery.of(context).size.width;

    return StoreConnector<PerceiveSlidableState, double>(
      distinct: true,
      converter: (store) => store.state.extent,
      builder: (context, extent) {

        Widget _buildPage(int index){

          bool scrollLocked = extent + widget.delegate.staticScrollModifier <= widget.mediumExtent && widget.staticSheet;

          /// Has a different build mode when the delegate is a [ScrollablePerceiveSlidableDelegate]
          if(widget.delegate is ScrollablePerceiveSlidableDelegate){
            return Container(
              constraints: BoxConstraints(
                minHeight: pageHeight,
                minWidth: pageWidth,
                maxWidth: pageWidth,
              ),
              child: (widget.delegate as ScrollablePerceiveSlidableDelegate).scrollingBodyBuilder(context, widget.controller.sheetState, widget.delegate.scrollControllers[index], index, scrollLocked, pageHeight * (1.0 - extent)),
            );
          }

          return SingleChildScrollView(
            controller: widget.delegate.scrollControllers[index],
            physics: scrollLocked ? NeverScrollableScrollPhysics() : AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: Column(
              children: [

                Container(
                  constraints: BoxConstraints(
                    minHeight: pageHeight,
                    minWidth: pageWidth,
                    maxWidth: pageWidth,
                  ),
                  child: widget.delegate.customBodyBuilder(context, widget.controller.sheetState, extent, index)
                ),

                Container(
                  height: pageHeight * (1.0 - extent),
                )

              ],
            ),
          );
        }

        if(widget.delegate.pageCount == 1){
          return _buildPage(0);
        }

        return TabBarView(
          controller: widget.delegate.tabController,
          children: List.generate(widget.delegate.pageCount, (index) => _buildPage(index)),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.delegate.wrapperBuilder(context, Column(
      children: [
        if(!widget.disableHeader)
          _buildHeader(context),
        Expanded(child: Container(
          color: widget.backgroundColor,
          child: _buildBody(context)
        )),
      ],
    ));
  }
}

abstract class PerceiveSlidableDelegate{

  final int pageCount;
  final int initialPage;
  final double staticScrollModifier;
  final List<ScrollController> scrollControllers;
  late TabController tabController;

  final dynamic delegateObject;

  PerceiveSlidableController get sheetController => delegateState!.widget.controller;

  Store<PerceiveSlidableState> get stateTower => delegateState!.tower;

  double get initialExtent => delegateState?.widget.initialExtent ?? 0;

  bool get isScrolled => scrollControllers.map<double>((e){
    try{
      return e.offset;
    }catch(e){
      return 0.0;
    }
  }).reduce((value, offset) => value + offset) > 0;

  ///The state of the delegate builder
  _PerceiveSlidableDelegateBuilderState? delegateState;

  PerceiveSlidableDelegate({required this.pageCount, this.initialPage = 0, this.delegateObject, this.staticScrollModifier = 0.0})
    : scrollControllers = List.generate(pageCount, (index) => ScrollController());
  
  void _delegateSheetStateListener(BuildContext context, SheetState state){
    if(delegateState != null){
      sheetListener(context, state);
      delegateState!.sheetListener(state.extent);
    }
  }

  void _bind(_PerceiveSlidableDelegateBuilderState state){
    delegateState = state;

    //Bind scroll controller behaviour
    for (var controller in scrollControllers) {
      state.initiateListener(controller);
    }

    //Create tab controller and add listener for page controller
    tabController = TabController(
      initialIndex: initialPage,
      vsync: state,
      length: pageCount,
    );
  }

  void _dispose(){
    dispose();
    tabController.dispose();
    for (var controller in scrollControllers) {
      controller.dispose();
    }

    delegateState = null;
  }

  // Calls the set state within the delegate
  void rebuild([void Function()? fn]){
    delegateState?.rebuild(fn ?? () {});
  }

  /// Builders and Listeners to be overriden
  Widget headerBuilder(BuildContext context, dynamic pageObj, Widget spacer, double borderRadius);
  Widget customBodyBuilder(BuildContext context, SheetState? state, double extent, int pageIndex);
  Widget wrapperBuilder(BuildContext context, Widget page) => page;
  void sheetListener(BuildContext context, SheetState state){}
  void dispose(){}

}

/// Provides a builder that provides the current scroll controller
abstract class ScrollablePerceiveSlidableDelegate extends PerceiveSlidableDelegate{

  ScrollablePerceiveSlidableDelegate({required int pageCount, int initialPage = 0, dynamic delegateObject, double? staticScrollModifier}) : super(pageCount: pageCount, initialPage: initialPage, delegateObject: delegateObject, staticScrollModifier: staticScrollModifier ?? 0.0);

  @override
  Widget customBodyBuilder(BuildContext context, SheetState? state, double extent, int pageIndex){
    throw 'Disabled in favour of the scroll body builder';
  }

  Widget scrollingBodyBuilder(BuildContext context, SheetState? state, ScrollController scrollController, int pageIndex, bool scrollLock, double footerHeight);
}

///Base Sheet Delegate
class _PerceiveSlidableBaseDelegate extends PerceiveSlidableDelegate{

  /// Listeners
  final Function(double extent)? extentListener;
  final Widget Function(BuildContext context, SheetState?, double)? body;
  final Widget Function(BuildContext context, dynamic pageObj, Widget spacer, double borderRadius)? header;

  _PerceiveSlidableBaseDelegate({
    required this.extentListener,
    required this.body,
    required this.header,
    dynamic delegateObject,
    int? initialPage
  }) : super(pageCount: 1, initialPage: initialPage ?? 0, delegateObject: delegateObject);

  @override
  void sheetListener(BuildContext context, SheetState state){
    extentListener?.call(state.extent);
  }

  @override
  Widget customBodyBuilder(BuildContext context, SheetState? state, double extent, int pageIndex) {
    return body?.call(context, state, extent) ?? SizedBox.shrink();
  }

  @override
  Widget headerBuilder(BuildContext context, pageObj, Widget spacer, double borderRadius) {
    return header?.call(context, pageObj, spacer, borderRadius) ?? SizedBox.shrink();
  }

}