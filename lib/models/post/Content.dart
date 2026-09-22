import 'Reactions.dart';
import 'PostCategory.dart';

class Content {
  Content({
      this.createAt, 
      this.createBy, 
      this.updateAt, 
      this.updateBy, 
      this.id, 
      this.title, 
      this.description, 
      this.body, 
      this.views, 
      this.status, 
      this.image, 
      this.tags, 
      this.reactions, 
      this.postCategory, 
      this.user,});

  Content.fromJson(dynamic json) {
    createAt = json['createAt'];
    createBy = json['createBy'];
    updateAt = json['updateAt'];
    updateBy = json['updateBy'];
    id = json['id'];
    title = json['title'];
    description = json['description'];
    body = json['body'];
    views = json['views'];
    status = json['status'];
    image = json['image'];
    tags = json['tags'] != null ? json['tags'].cast<String>() : [];
    reactions = json['reactions'] != null ? Reactions.fromJson(json['reactions']) : null;
    postCategory = json['postCategory'] != null ? PostCategory.fromJson(json['postCategory']) : null;
    user = json['user'];
  }
  String? createAt;
  String? createBy;
  dynamic updateAt;
  dynamic updateBy;
  int? id;
  String? title;
  String? description;
  String? body;
  int? views;
  String? status;
  String? image;
  List<String>? tags;
  Reactions? reactions;
  PostCategory? postCategory;
  dynamic user;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['createAt'] = createAt;
    map['createBy'] = createBy;
    map['updateAt'] = updateAt;
    map['updateBy'] = updateBy;
    map['id'] = id;
    map['title'] = title;
    map['description'] = description;
    map['body'] = body;
    map['views'] = views;
    map['status'] = status;
    map['image'] = image;
    map['tags'] = tags;
    if (reactions != null) {
      map['reactions'] = reactions?.toJson();
    }
    if (postCategory != null) {
      map['postCategory'] = postCategory?.toJson();
    }
    map['user'] = user;
    return map;
  }

}