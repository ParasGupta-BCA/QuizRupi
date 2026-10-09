// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter_web_plugins/url_strategy.dart';

void configureDomainOnlyUrlStrategy() {
  try {
    // Explicitly configure PathUrlStrategy so Flutter Web never uses Hash fragments (/#/)
    usePathUrlStrategy();
  } catch (_) {}
  ensureRootDomainUrl();
  try {
    html.window.addEventListener('popstate', (_) => ensureRootDomainUrl());
    html.window.addEventListener('hashchange', (_) => ensureRootDomainUrl());
  } catch (_) {}
}

void ensureRootDomainUrl() {
  try {
    final currentPath = html.window.location.pathname ?? '';
    final currentHash = html.window.location.hash;
    final currentSearch = html.window.location.search;
    final hasHash = currentHash.isNotEmpty && currentHash != '#';
    final hasSearch = currentSearch != null && currentSearch.isNotEmpty;
    if (currentPath != '/' || hasHash || hasSearch) {
      html.window.history.replaceState(html.window.history.state, '', '/');
    }
  } catch (_) {}
}
