import 'package:flutter/material.dart';

class ButtonCustomWidget extends StatelessWidget {
  bool? isLoading;
  String? title;
  ButtonCustomWidget({super.key, this.isLoading, this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      padding: EdgeInsets.symmetric(vertical: 18),
      width: double.infinity,
      child: Center(
        child: isLoading == true
            ? CircularProgressIndicator(color: Colors.white)
            : Text(title ?? "", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
