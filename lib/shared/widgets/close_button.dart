import 'package:flutter/material.dart';

class CloseIconButton extends StatelessWidget {
  final Function? onTap;
  const CloseIconButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => onTap ?? Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(8),

        child: const Icon(Icons.close_rounded, size: 24, color: Colors.white),
      ),
    );
  }
}
