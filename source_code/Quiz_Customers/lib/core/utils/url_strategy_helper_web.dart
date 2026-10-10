// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'package:flutter_web_plugins/url_strategy.dart';

void configureDomainOnlyUrlStrategy() {
  try {
    // Configure PathUrlStrategy so Flutter Web uses clean, standard URLs (e.g. /website)
    usePathUrlStrategy();
  } catch (_) {}
}

void ensureRootDomainUrl() {
  // No-op: normal page URL navigation restored
}
