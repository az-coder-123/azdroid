import 'package:desk_droid/features/mcp/data/utils/mcp_point.dart';

/// A point given as raw `x`/`y` tool arguments (unit inferred).
McpPoint rawPoint(double x, double y) =>
    McpPoint(McpAxis(x, McpUnit.auto), McpAxis(y, McpUnit.auto));
