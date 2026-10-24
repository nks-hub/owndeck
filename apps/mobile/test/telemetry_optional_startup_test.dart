import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/telemetry.dart';
import 'package:nextclouddeck/core/telemetry_bootstrap.dart';

void main() {
  test(
    'unconfigured runtime construction does not require a preferences plugin',
    () async {
      final runtime = TelemetryRuntime(config: const TelemetryConfig());
      await runtime.initialize();
      expect(runtime.preferences.loaded, isFalse);
      expect(runtime.crashesReady, isFalse);
      expect(runtime.analyticsReady, isFalse);
      // No SDK was started, so no native backend shutdown is needed either.
    },
  );
}
