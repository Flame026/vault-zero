/// Utility to sanitize error messages before presenting them to users via
/// snackbars, dialogs, or error banners.
///
/// Prevents accidental exposure of raw file-system paths, SQLite internal syntax,
/// and excessively long or unparsed error payloads.
String sanitizeErrorMessage(
  Object? error, {
  String fallback = 'An unexpected error occurred',
}) {
  if (error == null) return fallback;

  var msg = error.toString().trim();

  // Strip Dart exception prefixes
  msg = msg
      .replaceAll(
        RegExp(
          r'^(Exception|FormatException|Bad state|ArgumentError|StateError):\s*',
        ),
        '',
      )
      .replaceAll('Exception: ', '')
      .replaceAll('FormatException: ', '');

  // Strip absolute file paths (e.g. /data/user/0/..., /home/..., file:///...)
  msg = msg.replaceAll(
    RegExp(r'(?:file://)?/(?:[a-zA-Z0-9_\.\-]+/)+[a-zA-Z0-9_\.\-]+'),
    '[path]',
  );

  // Strip SQLite internal code details (e.g. (code 19 SQLITE_CONSTRAINT_UNIQUE))
  msg = msg.replaceAll(RegExp(r'\(code \d+ [A-Z_]+\)'), '');

  // Strip redundant whitespace
  msg = msg.replaceAll(RegExp(r'\s+'), ' ').trim();

  // Bound length for UI safety and calm UX
  if (msg.length > 200) {
    msg = '${msg.substring(0, 197)}...';
  }

  return msg.isEmpty ? fallback : msg;
}
