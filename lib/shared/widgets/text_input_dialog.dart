import 'package:flutter/material.dart';

class TextInputDialog extends StatefulWidget {
  const TextInputDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
    this.initialValue = '',
    this.hint,
    this.emptyMessage,
    this.minLines = 1,
    this.maxLines = 1,
    super.key,
  });

  final String title;
  final String label;
  final String confirmLabel;
  final String initialValue;
  final String? hint;
  final String? emptyMessage;
  final int minLines;
  final int maxLines;

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return AlertDialog(
      scrollable: keyboardVisible,
      title: keyboardVisible ? null : Text(widget.title),
      contentPadding: keyboardVisible
          ? const EdgeInsets.fromLTRB(24, 8, 24, 4)
          : null,
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          minLines: keyboardVisible ? 1 : widget.minLines,
          maxLines: widget.maxLines,
          textInputAction: widget.maxLines == 1
              ? TextInputAction.done
              : TextInputAction.newline,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
          ),
          validator: widget.emptyMessage == null
              ? null
              : (String? value) => value == null || value.trim().isEmpty
                    ? widget.emptyMessage
                    : null,
          onFieldSubmitted: widget.maxLines == 1 ? (_) => _submit() : null,
        ),
      ),
      actionsPadding: keyboardVisible
          ? const EdgeInsets.fromLTRB(16, 0, 16, 8)
          : null,
      actions: keyboardVisible && widget.maxLines == 1
          ? const <Widget>[]
          : <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
              FilledButton(
                onPressed: _submit,
                child: Text(widget.confirmLabel),
              ),
            ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text);
    }
  }
}
