import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../helpers/profile_constants.dart';
import '../helpers/profile_models.dart';
import '../helpers/profile_validators.dart';

Future<String?> showProfileEditSheet(
  BuildContext context, {
  required ProfileEditableField field,
  required String initialValue,
}) {
  return showModalBottomSheet<String>(
    context: context,
    // Keep profile edit sheets open until the user chooses Cancel or Save.
    isDismissible: false,
    // Prevent swipe-down dismissal so the close behavior stays button-driven.
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return PopScope(
        canPop: false,
        // Keep back navigation from dismissing the sheet outside Cancel/Save.
        child: _EditProfileSheet(field: field, initialValue: initialValue),
      );
    },
  );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.field, required this.initialValue});

  final ProfileEditableField field;
  final String initialValue;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: Material(
        color: context.isDarkMode ? colors.surface : ProfileConstants.softCard,
        borderRadius: BorderRadius.circular(26),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? colors.divider
                            : const Color(0xFFCED8C6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Edit ${widget.field.label}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _controller,
                    autofocus: true,
                    keyboardType: widget.field.keyboardType,
                    style: TextStyle(color: colors.textPrimary),
                    textInputAction: TextInputAction.done,
                    maxLines: widget.field.maxLines,
                    minLines: widget.field.maxLines > 1 ? 3 : 1,
                    inputFormatters: widget.field.inputFormatters,
                    validator: widget.field.validate,
                    onFieldSubmitted: (_) {
                      if (widget.field.maxLines == 1) {
                        _submit();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: widget.field.hintText,
                      filled: true,
                      fillColor: colors.surfaceHigh,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: context.isDarkMode
                              ? colors.border
                              : ProfileConstants.surfaceBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colors.accent,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: context.isDarkMode
                                  ? colors.border
                                  : ProfileConstants.surfaceBorder,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            foregroundColor: colors.textPrimary,
                            backgroundColor: colors.surfaceHigh,
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
