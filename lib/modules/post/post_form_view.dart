import 'package:demo_access_refresh_token_app/modules/post/post_form_controller.dart';
import 'package:demo_access_refresh_token_app/widgets/button_custom_widget.dart';
import 'package:demo_access_refresh_token_app/widgets/input_custom_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostFormView extends GetView<PostFormController> {
  const PostFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Create Post", style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 16
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            InputCustomWidget(
              hint: "Title",
            ),
            InputCustomWidget(
              hint: "Description",
            ),
            ButtonCustomWidget(
              title: "Create",
            )
          ],
        ),
      ),
    );
  }
}
