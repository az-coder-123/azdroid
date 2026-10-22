import 'package:desk_droid/features/mcp/domain/entities/mcp_semantic_element.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_semantic_tree_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sampleXml = '''<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>
<hierarchy rotation="0">
  <node index="0" text="" resource-id="" class="android.widget.FrameLayout" package="com.android.settings" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,0][1080,2340]">
    <node index="0" text="" resource-id="" class="android.widget.LinearLayout" package="com.android.settings" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,0][1080,2340]">
      <node index="0" text="" resource-id="android:id/action_bar" class="android.view.ViewGroup" package="com.android.settings" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,72][1080,240]">
        <node index="0" text="Search settings" resource-id="com.android.settings:id/search_action_bar_title" class="android.widget.TextView" package="com.android.settings" content-desc="Search" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[168,96][912,216]" />
      </node>
      <node index="1" text="" resource-id="android:id/list" class="androidx.recyclerview.widget.RecyclerView" package="com.android.settings" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="true" focused="false" scrollable="true" long-clickable="false" password="false" selected="false" bounds="[0,240][1080,2340]">
        <node index="0" text="" resource-id="com.android.settings:id/network_tile" class="android.widget.LinearLayout" package="com.android.settings" content-desc="" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[48,264][1032,456]">
          <node index="0" text="Network &amp; internet" resource-id="android:id/title" class="android.widget.TextView" package="com.android.settings" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[216,300][750,360]" />
          <node index="1" text="Wi-Fi, mobile, hotspot" resource-id="android:id/summary" class="android.widget.TextView" package="com.android.settings" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[216,364][650,412]" />
        </node>
        <node index="1" text="" resource-id="android:id/switch_widget" class="android.widget.Switch" package="com.android.settings" content-desc="Toggle Airplane" checkable="true" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[880,310][980,410]" />
        <node index="2" text="" resource-id="" class="android.view.View" package="com.android.settings" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,500][0,500]" />
      </node>
    </node>
  </node>
</hierarchy>''';

  group('McpSemanticTreeParser Tests', () {
    const parser = McpSemanticTreeParser();

    test('prunes non-interactive layout containers and empty nodes', () {
      final elements = parser.parse(
        sampleXml,
        screenWidth: 1080,
        screenHeight: 2340,
      );

      // Verify that raw FrameLayout & LinearLayout & zero-size View are pruned.
      // Expected retained:
      // 1. TextView "Search settings" (clickable=true, text, desc)
      // 2. RecyclerView (scrollable=true)
      // 3. LinearLayout (clickable=true)
      // 4. TextView "Network & internet" (has text)
      // 5. TextView "Wi-Fi, mobile, hotspot" (has text)
      // 6. Switch (checkable=true, clickable=true)
      expect(elements.length, 6);

      // Verify sequential 1-based IDs
      expect(elements.map((e) => e.id).toList(), [1, 2, 3, 4, 5, 6]);

      // Verify zero-sized node bounds="[0,500][0,500]" was pruned
      final zeroSized = elements.where((e) => e.bounds == '[0,500][0,500]');
      expect(zeroSized, isEmpty);
    });

    test('accurately calculates center and normalized coordinates', () {
      final elements = parser.parse(
        sampleXml,
        screenWidth: 1080,
        screenHeight: 2340,
      );

      // Search settings bounds: [168,96][912,216]
      final search = elements.first;
      expect(search.text, 'Search settings');
      expect(search.centerX, (168 + 912) ~/ 2); // 540
      expect(search.centerY, (96 + 216) ~/ 2); // 156
      expect(search.normX, closeTo(540 / 1080, 0.001));
      expect(search.normY, closeTo(156 / 2340, 0.001));
    });

    test('handles malformed or empty XML gracefully', () {
      expect(parser.parse(''), isEmpty);
      expect(parser.parse('   '), isEmpty);
      expect(parser.parse('<not-valid-xml'), isEmpty);
    });

    test('formatDigest creates token-efficient indexed lines', () {
      final elements = parser.parse(sampleXml);
      final digest = parser.formatDigest(elements);

      expect(digest, contains('=== Screen UI Tree (6 elements) ==='));
      expect(digest, contains('[#1] TextView text:"Search settings"'));
      expect(digest, contains('[#6] Switch desc:"Toggle Airplane"'));
      expect(
        digest,
        contains(
          'Tip: Use android_click_element_by_id(id: N) to tap any element.',
        ),
      );
    });

    test('findByQuery resolves elements by text, id, or contentDesc', () {
      final elements = parser.parse(sampleXml);

      final byText = parser.findByQuery(elements, text: 'network');
      expect(byText, isNotNull);
      expect(byText!.text, 'Network & internet');

      final byId = parser.findByQuery(elements, resourceId: 'switch_widget');
      expect(byId, isNotNull);
      expect(byId!.shortClass, 'Switch');

      final byDesc = parser.findByQuery(elements, contentDesc: 'airplane');
      expect(byDesc, isNotNull);
      expect(byDesc!.contentDesc, 'Toggle Airplane');

      final notFound = parser.findByQuery(elements, text: 'Bluetooth');
      expect(notFound, isNull);
    });

    test('prunes anonymous containers and inherits clickability for Compose/Flutter', () {
      const composeXml =
          '''<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>
<hierarchy rotation="0">
  <node index="0" text="" resource-id="" class="android.widget.FrameLayout" package="com.openplayer" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" bounds="[0,0][1080,2340]">
    <!-- Compose Tab: Anonymous clickable View with child TextView -->
    <node index="0" text="" resource-id="" class="android.view.View" package="com.openplayer" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" bounds="[0,180][360,280]">
      <node index="0" text="Recent (25)" resource-id="" class="android.widget.TextView" package="com.openplayer" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" bounds="[50,200][310,260]" />
    </node>
    <!-- Standalone clickable element with no text and no children (e.g. FloatingActionButton/IconButton) -->
    <node index="1" text="" resource-id="" class="android.widget.ImageButton" package="com.openplayer" content-desc="" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" bounds="[900,2000][1020,2120]" />
  </node>
</hierarchy>''';

      final elements = parser.parse(
        composeXml,
        screenWidth: 1080,
        screenHeight: 2340,
      );

      // Expected:
      // 1. TextView "Recent (25)" with inherited clickable=true (anonymous View pruned)
      // 2. ImageButton (kept because it has no children to provide content)
      expect(elements.length, 2);

      final tab = elements.first;
      expect(tab.shortClass, 'TextView');
      expect(tab.text, 'Recent (25)');
      expect(
        tab.clickable,
        isTrue,
        reason: 'Child should inherit clickability from Compose parent',
      );
      expect(tab.centerX, 180);
      expect(tab.centerY, 230);

      final iconBtn = elements.last;
      expect(iconBtn.shortClass, 'ImageButton');
      expect(iconBtn.clickable, isTrue);

      final digest = parser.formatDigest(elements);
      expect(
        digest,
        contains('[#1] TextView text:"Recent (25)" clickable:true'),
      );
    });
  });

  group('McpSemanticElement Model Tests', () {
    test('shortClass extracts final class name correctly', () {
      const el = McpSemanticElement(
        id: 1,
        text: 'OK',
        resourceId: 'android:id/button1',
        className: 'android.widget.Button',
        package: 'com.android.settings',
        contentDesc: '',
        clickable: true,
        scrollable: false,
        checkable: false,
        checked: false,
        enabled: true,
        bounds: '[100,200][300,400]',
        centerX: 200,
        centerY: 300,
        normX: 0.2,
        normY: 0.3,
      );

      expect(el.shortClass, 'Button');
      expect(
        el.toDigestLine(),
        '[#1] Button text:"OK" id:"button1" clickable:true center:(200,300)',
      );

      final map = el.toMap();
      expect(map['id'], 1);
      expect(map['text'], 'OK');
      expect(map['centerPixels'], {'x': 200, 'y': 300});
    });
  });
}
