import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import '../../../flutter_chat_ui.dart';
import '../../models/input_clear_mode.dart';
import '../../models/send_button_visibility_mode.dart';
import '../../util.dart';
import '../message/text_message.dart';
import '../state/inherited_chat_theme.dart';
import '../state/inherited_l10n.dart';
import 'attachment_button.dart';
import 'pen_button.dart';
import 'input_text_field_controller.dart';
import 'send_button.dart';

import 'package:flutter_svg/flutter_svg.dart';

/// A class that represents bottom bar widget with a text field, attachment and
/// send buttons inside. By default hides send button when text field is empty.
class Input extends StatefulWidget {
  /// Creates [Input] widget.
  const Input({
    super.key,
    this.isAttachmentUploading,
    this.onAttachmentPressed,
    this.onPenPressed,
    required this.onSendPressed,
    this.options = const InputOptions(),
    required this.messageSize,
    required this.textColor,
    this.penIcon,
    this.imageIcon,
    this.sendIcon,
  });

  /// Whether attachment is uploading. Will replace attachment button with a
  /// [CircularProgressIndicator]. Since we don't have libraries for
  /// managing media in dependencies we have no way of knowing if
  /// something is uploading so you need to set this manually.
  final bool? isAttachmentUploading;

  /// See [AttachmentButton.onPressed].
  final VoidCallback? onAttachmentPressed;

  final VoidCallback? onPenPressed;

  /// Will be called on [SendButton] tap. Has [types.PartialText] which can
  /// be transformed to [types.TextMessage] and added to the messages list.
  final void Function(types.PartialText) onSendPressed;

  /// Customisation options for the [Input].
  final InputOptions options;

  final double messageSize;

  final int textColor;

  final SvgPicture? penIcon;
  final SvgPicture? imageIcon;
  final SvgPicture? sendIcon;

  @override
  State<Input> createState() => _InputState();
}

/// [Input] widget state.
class _InputState extends State<Input> {
  late final _inputFocusNode = FocusNode(
    onKeyEvent: (node, event) {
      if (event.physicalKey == PhysicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.physicalKeysPressed.any(
            (el) => <PhysicalKeyboardKey>{
              PhysicalKeyboardKey.shiftLeft,
              PhysicalKeyboardKey.shiftRight,
            }.contains(el),
          )) {
        if (event is KeyDownEvent) {
          _handleSendPressed();
        }
        return KeyEventResult.handled;
      } else {
        return KeyEventResult.ignored;
      }
    },
  );

  bool _sendButtonVisible = false;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();

    _textController =
        widget.options.textEditingController ?? InputTextFieldController();
    _handleSendButtonVisibilityModeChange();
  }

  @override
  void didUpdateWidget(covariant Input oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.options.sendButtonVisibilityMode !=
        oldWidget.options.sendButtonVisibilityMode) {
      _handleSendButtonVisibilityModeChange();
    }
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => _inputFocusNode.requestFocus(),
        child: _inputBuilder(),
      );

  void _handleSendButtonVisibilityModeChange() {
    _textController.removeListener(_handleTextControllerChange);
    if (widget.options.sendButtonVisibilityMode ==
        SendButtonVisibilityMode.hidden) {
      _sendButtonVisible = false;
    } else if (widget.options.sendButtonVisibilityMode ==
        SendButtonVisibilityMode.editing) {
      _sendButtonVisible = _textController.text.trim() != '';
      _textController.addListener(_handleTextControllerChange);
    } else {
      _sendButtonVisible = true;
    }
  }

  // void _handleSendPressed() {
  //   final trimmedText = _textController.text.trim();
  //   if (trimmedText != '') {
  //     final partialText = types.PartialText(text: trimmedText);
  //     widget.onSendPressed(partialText);

  //     if (widget.options.inputClearMode == InputClearMode.always) {
  //       _textController.clear();
  //     }
  //   }
  // }

  void _handleSendPressed() {
    final trimmedText = _textController.text.trim();
    if (trimmedText != '') {
      Map<String, dynamic>? textStyle = {
        'color': widget.textColor,
        'fontsize': widget.messageSize,
      };
      final partialText =
          types.PartialText(text: trimmedText, metadata: textStyle);
      widget.onSendPressed(partialText);

      // final metaData = Metadata(
      //   textStyle: const TextStyle(
      //       // TODO: ここで、色、サイズ等指定.
      //       // color: Colors.red,
      //       // fontSize: 16,
      //       ),
      // );
      // final partialText =
      //     types.PartialText(text: trimmedText, metadata: metaData.toMap());

      if (widget.options.inputClearMode == InputClearMode.always) {
        _textController.clear();
      }
    }
  }

  void _handleTextControllerChange() {
    setState(() {
      _sendButtonVisible = _textController.text.trim() != '';
    });
    //print('TextField text changed: ${_textController.text}');
  }

  Widget _inputBuilder() {
    final query = MediaQuery.of(context);
    final buttonPadding = InheritedChatTheme.of(context)
        .theme
        .inputPadding
        .copyWith(left: 8, right: 8);
    final safeAreaInsets = isMobile
        ? EdgeInsets.fromLTRB(
            query.padding.left,
            0,
            query.padding.right,
            query.viewInsets.bottom + query.padding.bottom,
          )
        : EdgeInsets.zero;
    final textPadding = InheritedChatTheme.of(context)
        .theme
        .inputPadding
        .copyWith(left: 8, right: 0)
        .add(
          EdgeInsets.fromLTRB(
            widget.onAttachmentPressed != null ? 0 : 24,
            0,
            _sendButtonVisible ? 0 : 24,
            0,
          ),
        );

    return Focus(
      autofocus: true,
      child: Material(
        borderRadius: InheritedChatTheme.of(context).theme.inputBorderRadius,
        color: InheritedChatTheme.of(context).theme.inputBackgroundColor,
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            if (widget.onAttachmentPressed != null)
              AttachmentButton(
                imageIcon: widget.imageIcon,
                isLoading: widget.isAttachmentUploading ?? false,
                onPressed: widget.onAttachmentPressed,
                //padding: buttonPadding,
              ),
            if (widget.onPenPressed != null)
              PenButton(
                penIcon: widget.penIcon,
                isLoading: widget.isAttachmentUploading ?? false,
                onPressed: widget.onPenPressed,
                padding: buttonPadding,
              ),
            Expanded(
              child: Padding(
                padding: textPadding,
                child: TextField(
                  controller: _textController,
                  cursorColor:
                      InheritedChatTheme.of(context).theme.inputTextCursorColor,
                  decoration: InheritedChatTheme.of(context)
                      .theme
                      .inputTextDecoration
                      .copyWith(
                        hintStyle: InheritedChatTheme.of(context)
                            .theme
                            .inputTextStyle
                            .copyWith(
                              color: InheritedChatTheme.of(context)
                                  .theme
                                  .inputTextColor
                                  .withOpacity(0.5),
                            ),
                        hintText:
                            InheritedL10n.of(context).l10n.inputPlaceholder,
                      ),
                  focusNode: _inputFocusNode,
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  minLines: 1,
                  onChanged: widget.options.onTextChanged,
                  onTap: widget.options.onTextFieldTap,
                  style: InheritedChatTheme.of(context)
                      .theme
                      .inputTextStyle
                      .copyWith(
                        color:
                            InheritedChatTheme.of(context).theme.inputTextColor,
                      ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            Visibility(
              visible: _sendButtonVisible,
              child: SendButton(
                sendIcon: widget.sendIcon,
                onPressed: _handleSendPressed,
                //padding: buttonPadding,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class InputOptions {
  const InputOptions({
    this.inputClearMode = InputClearMode.always,
    this.onTextChanged,
    this.onTextFieldTap,
    this.sendButtonVisibilityMode = SendButtonVisibilityMode.editing,
    this.textEditingController,
  });

  /// Controls the [Input] clear behavior. Defaults to [InputClearMode.always].
  final InputClearMode inputClearMode;

  /// Will be called whenever the text inside [TextField] changes.
  final void Function(String)? onTextChanged;

  /// Will be called on [TextField] tap.
  final VoidCallback? onTextFieldTap;

  /// Controls the visibility behavior of the [SendButton] based on the
  /// [TextField] state inside the [Input] widget.
  /// Defaults to [SendButtonVisibilityMode.editing].
  final SendButtonVisibilityMode sendButtonVisibilityMode;

  /// Custom [TextEditingController]. If not provided, defaults to the
  /// [InputTextFieldController], which extends [TextEditingController] and has
  /// additional fatures like markdown support. If you want to keep additional
  /// features but still need some methods from the default [TextEditingController],
  /// you can create your own [InputTextFieldController] (imported from this lib)
  /// and pass it here.
  final TextEditingController? textEditingController;
}
