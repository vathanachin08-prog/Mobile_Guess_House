import 'package:flutter/material.dart';

class InputCustomWidget extends StatelessWidget {
  TextEditingController? controller;
  String? hint;
  InputCustomWidget({super.key, this.controller, this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 10
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hint: Text(hint ?? ""),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueGrey),
          ),
        ),
      ),
    );
  }
}
