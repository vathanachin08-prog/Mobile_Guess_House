class Reactions {
  Reactions({
      this.likes, 
      this.dislikes,});

  Reactions.fromJson(dynamic json) {
    likes = json['likes'];
    dislikes = json['dislikes'];
  }
  int? likes;
  int? dislikes;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['likes'] = likes;
    map['dislikes'] = dislikes;
    return map;
  }

}