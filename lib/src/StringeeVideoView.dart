import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'StringeeConstants.dart';

class StringeeVideoView extends StatefulWidget {
  late final String? callId;
  late final String? trackId;
  bool isLocal = true;
  final bool? isOverlay;
  final bool? isMirror;
  final EdgeInsetsGeometry? margin;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final ScalingType? scalingType;
  final double? height;
  final double? width;
  final Color? color;
  final Widget? child;
  late final bool forCall;
  final BorderRadius? borderRadius;

  StringeeVideoView(
    this.callId,
    this.isLocal, {
    Key? key,
    this.isOverlay = false,
    this.isMirror = false,
    this.color,
    this.height,
    this.width,
    this.margin,
    this.alignment,
    this.padding,
    this.child,
    this.scalingType = ScalingType.fill,
    this.borderRadius,
  })  : assert(margin == null || margin.isNonNegative),
        assert(padding == null || padding.isNonNegative),
        super(key: key) {
    forCall = true;
  }

  StringeeVideoView.forTrack(
    this.trackId, {
    Key? key,
    this.isOverlay = false,
    this.isMirror = false,
    this.color,
    this.height,
    this.width,
    this.margin,
    this.alignment,
    this.padding,
    this.child,
    this.scalingType = ScalingType.fill,
    this.borderRadius,
  })  : assert(margin == null || margin.isNonNegative),
        assert(padding == null || padding.isNonNegative),
        super(key: key) {
    forCall = false;
  }

  @override
  StringeeVideoViewState createState() => StringeeVideoViewState();
}

class StringeeVideoViewState extends State<StringeeVideoView> {
  // This is used in the platform side to register the view.
  final String viewType = 'stringeeVideoView';

  // Pass parameters to the platform side.
  Map<dynamic, dynamic> creationParams = <dynamic, dynamic>{};

  @override
  void initState() {
    super.initState();

    if (widget.forCall) {
      creationParams = {
        'callId': widget.callId,
        'isLocal': widget.isLocal,
        'width': widget.width,
        'height': widget.height,
        'forCall': widget.forCall,
      };
    } else {
      creationParams = {
        'trackId': widget.trackId,
        'width': widget.width,
        'height': widget.height,
        'forCall': widget.forCall,
      };
    }

    switch (widget.scalingType) {
      case ScalingType.fill:
        creationParams['scalingType'] = "FILL";
        break;
      case ScalingType.fit:
        creationParams['scalingType'] = "FIT";
        break;
      default:
        creationParams['scalingType'] = "FILL";
        break;
    }

    if (Platform.isAndroid) {
      creationParams['isOverlay'] =
          widget.isOverlay == null ? false : widget.isOverlay;
      creationParams['isMirror'] =
          widget.isMirror == null ? false : widget.isMirror;
    }
  }

  Widget createVideoView(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return PlatformViewLink(
          viewType: viewType,
          surfaceFactory:
              (BuildContext context, PlatformViewController controller) {
            return AndroidViewSurface(
              controller: controller as AndroidViewController,
              gestureRecognizers: const <
                  Factory<OneSequenceGestureRecognizer>>{},
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            );
          },
          onCreatePlatformView: (PlatformViewCreationParams params) {
            return PlatformViewsService.initSurfaceAndroidView(
              id: params.id,
              viewType: viewType,
              layoutDirection: TextDirection.rtl,
              creationParams: creationParams,
              creationParamsCodec: StandardMessageCodec(),
            )
              ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
              ..create();
          },
        );
      case TargetPlatform.iOS:
        // Co loi FlutterPlatformView chua duoc fix => dung tam cach nay
        if (widget.width == null) {
          creationParams['width'] = MediaQuery.of(context).size.width;
        }

        if (widget.height == null) {
          creationParams['height'] = MediaQuery.of(context).size.height;
        }

        return UiKitView(
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        );
      default:
        throw UnsupportedError("Unsupported platform view");
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? nativeWidget;

    /// Border native widget
    if (widget.borderRadius != null) {
      nativeWidget = new ClipRRect(
        borderRadius: widget.borderRadius,
        child: createVideoView(context),
      );
    } else {
      nativeWidget = createVideoView(context);
    }

    List<Widget> childrenWidget = <Widget>[nativeWidget];

    /// Add native widget to Container for custom widget attributes
    Widget current = Container(
      height: widget.height,
      width: widget.width,
      margin: widget.margin,
      decoration:
          BoxDecoration(color: widget.color, borderRadius: widget.borderRadius),
      child: Stack(
        children: childrenWidget,
      ),
    );

    /// Modify child widget
    if (widget.child != null) {
      Widget? child = widget.child;

      if (widget.padding != null) {
        child = Padding(padding: widget.padding!, child: child);
      }

      childrenWidget.add(child!);
    }

    /// Set alignment for widget
    if (widget.alignment != null) {
      current = Align(alignment: widget.alignment!, child: current);
    }

    return current;
  }
}
