import 'package:desk_droid/core/models/device_entity.dart';
import 'package:flutter/widgets.dart';

/// Builds the route that opens the mirroring workspace for a device.
///
/// Supplied by the app shell (`main.dart`) so discovery does not depend on
/// the streaming feature.
typedef MirroringRouteBuilder = Route<void> Function(DeviceEntity device);
