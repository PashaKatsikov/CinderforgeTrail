import 'package:flutter/foundation.dart';

/// Debug-only logger. The closure AND its string literals are dropped from
/// release builds because `assert` is compiled out — so no `[CFT.*]` tag ever
/// ships as a grep-able literal in the release binary.
void emberLog(String Function() build) {
  assert(() {
    debugPrint(build());
    return true;
  }());
}
