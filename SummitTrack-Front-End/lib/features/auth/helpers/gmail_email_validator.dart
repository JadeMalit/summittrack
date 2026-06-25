const String gmailEmailErrorMessage =
    "Please enter a valid Gmail address ending with @gmail.com";

String normalizeGmailEmail(String value) {
  return value.trim().toLowerCase();
}

String? validateGmailEmail(String value) {
  final email = normalizeGmailEmail(value);

  if (email.isEmpty) {
    return null;
  }

  if (email.contains(RegExp(r'\s'))) {
    return gmailEmailErrorMessage;
  }

  if (!RegExp(r'^[a-z0-9._%+-]+@gmail\.com$').hasMatch(email)) {
    return gmailEmailErrorMessage;
  }

  return null;
}
