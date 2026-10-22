// JSON-schema fragments shared by the MCP tool catalog, so every tool
// describes the same parameter the same way (and the catalog stays small:
// clients send it to the model on every session).

/// Which device a tool acts on.
const Map<String, dynamic> mcpDeviceSerialProp = {
  'type': 'string',
  'description':
      'Device serial or IP:port from android_list_devices. Required when '
      'several devices are connected; may be omitted when only one is.',
};

/// A raw coordinate whose unit is inferred.
const Map<String, dynamic> mcpCoordProp = {
  'type': 'number',
  'description':
      'Screen fraction when both values of the pair are within 0.0-1.0, '
      'otherwise pixels.',
};

/// A coordinate that is always a screen fraction.
const Map<String, dynamic> mcpCoordRatioProp = {
  'type': 'number',
  'description': 'Screen fraction 0.0-1.0 (wins over the raw value).',
};

/// A coordinate that is always in pixels.
const Map<String, dynamic> mcpCoordPixelProp = {
  'type': 'number',
  'description': 'Physical pixels, even when 0-1 (wins over the raw value).',
};
