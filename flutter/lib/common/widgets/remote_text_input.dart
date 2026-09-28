import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/dialog.dart';
import 'package:flutter_hbb/models/model.dart';
import 'package:flutter_hbb/models/platform_model.dart';

void showRemoteTextInput(FFI ffi) {
  final controller = TextEditingController();
  var sentText = '';

  void sendBackspace() {
    bind.sessionInputKey(
      sessionId: ffi.sessionId,
      name: 'VK_BACK',
      down: false,
      press: true,
      alt: false,
      ctrl: false,
      shift: false,
      command: false,
    );
  }

  void mirrorText() {
    final value = controller.value;
    // Only forward committed text; IME preedit may change without a matching
    // edit in the remote application.
    if (value.composing.isValid && !value.composing.isCollapsed) return;

    final previous = sentText.runes.toList();
    final current = value.text.runes.toList();
    var common = 0;
    while (common < previous.length &&
        common < current.length &&
        previous[common] == current[common]) {
      common++;
    }
    if (common == previous.length && common == current.length) return;

    for (var i = common; i < previous.length; i++) {
      sendBackspace();
    }
    if (common < current.length) {
      bind.sessionInputString(
        sessionId: ffi.sessionId,
        value: String.fromCharCodes(current.skip(common)),
      );
    }
    sentText = value.text;
  }

  controller.addListener(mirrorText);
  final dialog = ffi.dialogManager.show((setState, close, context) {
    return CustomAlertDialog(
      title: Text(translate('Type text on remote')),
      content: SizedBox(
        width: 360,
        child: TextField(controller: controller, autofocus: true),
      ),
      actions: [dialogButton('OK', onPressed: close)],
      onCancel: close,
    );
  });
  dialog.whenComplete(controller.dispose);
}
