import 'package:demo_access_refresh_token_app/data/local/token_store_local.dart';
import 'package:demo_access_refresh_token_app/modules/home/home_controller.dart';
import 'package:demo_access_refresh_token_app/modules/login/login_view.dart';
import 'package:demo_access_refresh_token_app/routes/app_route_name.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx((){
      return  Scaffold(
        drawer: Drawer(
          backgroundColor: Colors.cyan,
          child: ListView(
            children: [
              Container(
                width: double.infinity,
                height: 150,
              ),
              ListTile(
                onTap: (){
                  Navigator.pop(context);
                  Get.toNamed(AppRouteName.adminPost);
                },
                leading: Icon(Icons.post_add, color: Colors.white,),
                trailing: Icon(Icons.navigate_next, color: Colors.white,),
                title: Text("post".tr, style: TextStyle(color: Colors.white),),
              )
            ],
          ),
        ),
        backgroundColor: Colors.white,
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white
          ),
          backgroundColor: Colors.cyan,
          title: Text("home".tr, style: TextStyle(color: Colors.white),),
          actions: [
            IconButton(onPressed: (){
              TokenStoreLocal.removeToken();
              Get.offAll(LoginView());
            }, icon: Icon(Icons.logout)),
            IconButton(onPressed: (){
              if(Get.locale!.languageCode == "km"){
                var locale = Locale('en', 'US');
                Get.updateLocale(locale);
              }else{
                var locale = Locale('km', 'KH');
                Get.updateLocale(locale);
              }
            }, icon: Icon(Icons.language))
          ],
        ),
        body: controller.loading.value ? CircularProgressIndicator(
          color: Colors.cyan,
        ) : Container(),
      );
    });
  }
}
