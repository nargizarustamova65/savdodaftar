import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';

/// 6 xonali OTP maydoni (TZ 6-ekran).
///
/// Ko'rinadigan kataklar ustida shaffof [TextField] turadi — shunda
/// tizim klaviaturasi, SMS autofill va nusxa-joylash ishlaydi.
class OtpField extends StatefulWidget {
  const OtpField({
    super.key,
    required this.controller,
    this.length = 6,
    this.hasError = false,
    this.onCompleted,
    this.onChanged,
  });

  final TextEditingController controller;
  final int length;
  final bool hasError;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    setState(() {});
    widget.onChanged?.call(value);
    if (value.length == widget.length) {
      widget.onCompleted?.call(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String value = widget.controller.text;

    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(widget.length, (int index) {
              final bool filled = index < value.length;
              final bool active = index == value.length && _focusNode.hasFocus;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                height: 56,
                width: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.field,
                  border: Border.all(
                    color: widget.hasError
                        ? AppColors.danger
                        : active
                            ? AppColors.primary
                            : AppColors.border,
                    width: active || widget.hasError ? 1.6 : 1,
                  ),
                ),
                child: Text(
                  filled ? value[index] : '',
                  style: textTheme.titleLarge,
                ),
              );
            }),
          ),
          Positioned.fill(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: widget.length,
              showCursor: false,
              enableInteractiveSelection: false,
              cursorColor: Colors.transparent,
              style: const TextStyle(color: Colors.transparent, height: 0.01),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                counterText: '',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: _handleChanged,
            ),
          ),
        ],
      ),
    );
  }
}
