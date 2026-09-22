import 'dart:convert';

import 'package:demo_access_refresh_token_app/constants/constant_uri.dart';
import 'package:demo_access_refresh_token_app/core/services/api_service.dart';
import 'package:demo_access_refresh_token_app/models/post/Content.dart';
import 'package:demo_access_refresh_token_app/models/post/PostResponse.dart';
import 'package:get/get.dart';

class PostController extends GetxController {
  final ApiService apiService;

  PostController({required this.apiService});
  var postList = <Content>[].obs;
  var loading = false.obs;

  @override
  void onInit() {
    getAllPost();
    super.onInit();
  }

  void getAllPost() async {
    loading.value = true;
    var response = await apiService.getApi(
      "${ConstantUri.getAllPostPath}?page=0&size=10&status=ACT",
    );
    if (response != null) {
      PostResponse postResponse = PostResponse.fromJson(jsonDecode(response));
      if (postResponse.data != null && postResponse.data!.content!.isNotEmpty) {
        postList.value = postResponse.data!.content ?? [];
      }
    }
    loading.value = false;
  }
}
