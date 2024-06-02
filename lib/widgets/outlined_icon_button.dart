// 시작, 랭킹, 찜 버튼 커스텀 위젯
import 'package:flutter/material.dart';

class IconOutlinedButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color textColor;
  final void Function()? onPressed;
  const IconOutlinedButton(this.text, this.icon, this.textColor, {required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: const ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5.0))
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor),
          const Padding(padding: EdgeInsets.only(right: 10)),
          Text(text, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }
}