
import 'dart:io';

class MusicFile {
  String music, photo;
  //bool isPlayingNow;
  int id;

  MusicFile({this.music, this.photo, /*this.isPlayingNow,*/this.id});


  Map<String,dynamic> toMap() {
    print(id);
    var map = Map<String, dynamic>();
    map['photo'] = photo;
    map['music'] = music;
    map['id'] = id;

    return map;
  }

  MusicFile.fromMap(Map<String,dynamic> mapa){
    this.music = (mapa['music']);
    this.photo = (mapa['photo']);
    this.id = mapa['id'];
  }
}