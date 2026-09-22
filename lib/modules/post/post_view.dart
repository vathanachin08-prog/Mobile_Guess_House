import 'package:demo_access_refresh_token_app/routes/app_route_name.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/loading_widget.dart';
import 'post_controller.dart';

class PostView extends GetView<PostController> {
  const PostView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor: const Color(0xffF5F7FA),
        appBar: AppBar(
          actions: [
            IconButton(onPressed: (){
              Get.toNamed(AppRouteName.adminPostForm);
            }, icon: Icon(Icons.add))
          ],
          iconTheme: IconThemeData(color: Colors.white),
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.cyan,
          title: const Text(
            "Posts",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: controller.loading.value == true
            ? LoadingWidget()
            : RefreshIndicator(
                onRefresh: () async {
                  controller.getAllPost();
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.postList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final data = controller.postList[index];

                    return Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Image
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(18),
                            ),
                            child: Image.network(
                              data.image ?? "",
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;

                                    return Container(
                                      height: 220,
                                      alignment: Alignment.center,
                                      child: const CircularProgressIndicator(),
                                    );
                                  },
                              errorBuilder: (_, __, ___) {
                                return Container(
                                  height: 220,
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Title
                                Text(
                                  data.title ?? "",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                /// Description
                                Text(
                                  data.description ?? "",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey.shade700,
                                    height: 1.5,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                /// Tags
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: (data.tags ?? [])
                                      .map(
                                        (tag) => Chip(
                                          backgroundColor: Colors.cyan.shade50,
                                          label: Text(tag),
                                        ),
                                      )
                                      .toList(),
                                ),

                                const SizedBox(height: 16),

                                /// Likes & Dislikes
                                Row(
                                  children: [
                                    Icon(
                                      Icons.thumb_up_alt,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 5),
                                    Text("${data.reactions?.likes ?? 0}"),

                                    const SizedBox(width: 20),

                                    Icon(
                                      Icons.thumb_down_alt,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 5),
                                    Text("${data.reactions?.dislikes ?? 0}"),
                                  ],
                                ),

                                const Divider(height: 30),

                                /// Category
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.category,
                                      color: Colors.cyan,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      data.postCategory?.name ?? "-",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      );
    });
  }
}
