import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:muzyka2/database_helper.dart';
import 'package:sqflite/sqlite_api.dart';

import 'ActualPlaylist.dart';
import 'FirstMainScreen.dart';
import 'MusicFile.dart';
import 'NowPlayingFile.dart';

class ShowPlaylist extends StatefulWidget {
  @override
  _ShowPlaylistState createState() => _ShowPlaylistState();
}

class _ShowPlaylistState extends State<ShowPlaylist> {

  DatabaseHelper databaseHelper=new DatabaseHelper();

  @override
  void initState() {
    super.initState();
    updateList();
  }

  @override
  Widget build(BuildContext context) {
    if(ActualPlaylist.listOfMusicFiles==null){
      ActualPlaylist.listOfMusicFiles=new List();
    }
    /*else{
      print("HI"+ActualPlaylist.listOfPlaylist.length.toString());
    }*/
    return WillPopScope(
      onWillPop: onBackPressed,
      child: Scaffold(
        bottomNavigationBar: Container(
            height: 50,
            color: Colors.grey[800],
            child: GestureDetector(
              onTap: () {
                showGeneralDialog(
                  barrierLabel: "Label",
                  barrierDismissible: false,
                  barrierColor: Colors.black.withOpacity(0.1),
                  transitionDuration: Duration(milliseconds: 400),
                  context: context,
                  pageBuilder: (context, anim1, anim2) {
                    return FirstMainScreen();
                  },
                  transitionBuilder: (context, anim1, anim2, child) {
                    return SlideTransition(
                      position: Tween(begin: Offset(0, 1), end: Offset(0, 0))
                          .animate(anim1),
                      child: child,
                    );
                  },
                );
              },
              child: Row(
                children: [

                  IconButton(
                    icon: Icon(NowPlayingFile.isPlaying?Icons.pause:Icons.play_arrow,color:Colors.black),
                    onPressed: (){
                      if(NowPlayingFile.player!=null){
                        if(NowPlayingFile.isPlaying){
                          NowPlayingFile.player.pause();
                        }
                        else{
                          NowPlayingFile.cache.playBytes(NowPlayingFile.listaBitow);
                          NowPlayingFile.player.seek(NowPlayingFile.position);
                        }

                        setState(() {
                          NowPlayingFile.isPlaying=!NowPlayingFile.isPlaying;
                        });
                      }
                    },
                  ),


                  Container(width: MediaQuery.of(context).size.width*3/4,child: Text(NowPlayingFile.title!=null?NowPlayingFile.title:"Dodaj piosenkę")),


                  ActualPlaylist.index!=null&&ActualPlaylist.listOfMusicFiles!=null?
                  IconButton(
                    icon: Icon(Icons.skip_next, color: ActualPlaylist.index+1<ActualPlaylist.listOfMusicFiles.length?Colors.white:Colors.grey[800]),
                  ):Container(),
                ],
              ),
            )
        ),
        body: Container(
            child: Column(
              children: [
                SizedBox(height: 20),

                RaisedButton(
                    color: Colors.blueGrey[700],
                    onPressed: () => _openFileExplorer(),
                    child:Row(
                      children: [
                        SizedBox(width: 15),
                        Icon(Icons.music_note),
                        Expanded(child: Text("Dodaj plik .mp3", textAlign: TextAlign.center)),
                      ],
                    )
                ),
                SizedBox(height: 40),
                ActualPlaylist.listOfMusicFiles.length!=0?ListView(physics: NeverScrollableScrollPhysics(), shrinkWrap: true, scrollDirection: Axis.vertical,
                    children: ActualPlaylist.listOfMusicFiles.map((item) => Container(color:Colors.grey,child:RaisedButton(
                      child: Text(item.music,style: TextStyle(color:Colors.white)),onPressed: ()async{
                        ActualPlaylist.index = item.id;
                        NowPlayingFile.listaBitow = await NowPlayingFile.readBytes();
                        NowPlayingFile.position=new Duration();
                        NowPlayingFile.isPlaying=true;
                        setState(() {
                          NowPlayingFile.cache.playBytes(NowPlayingFile.listaBitow);
                        });
                    },
                    ))).toList()):Container(),
              ],
            )
        ),
      ),
    );
  }

  FileType pickingType;
  File file;

  void _openFileExplorer() async {
    try {
      pickingType=FileType.audio;
      file = await FilePicker.getFile(type: pickingType);
      setState(() {
        if(file!=null) {
          addMusicFile(File(file.path));
        }
      });
    } catch (e) {
      print("Unsupported operation" + e.toString());
    }
  }

  void addMusicFile(File musicFile){
    MusicFile musicFilePom = MusicFile(music: file.path, photo: null, id: ActualPlaylist.listOfMusicFiles.length);
    ActualPlaylist.listOfMusicFiles.add(musicFilePom);
    databaseHelper.insertItem(musicFilePom);
  }

  void updateList(){

    final Future<Database> dbFuture = databaseHelper.initialiseDatabase(ActualPlaylist.name);
    dbFuture.then((database) {
      Future<List<MusicFile>> itemsListFuture = databaseHelper.getItemsList();
      itemsListFuture.then((itemList){
        setState(() {
          ActualPlaylist.listOfMusicFiles=itemList;
        });
      });
    });
  }

  /*Future<Uint8List> readBytes() async{
    print(ActualPlaylist.listOfMusicFiles[ActualPlaylist.index].music);
    if(File(ActualPlaylist.listOfMusicFiles[ActualPlaylist.index].music)==null){
      print("Something wrong");
    }
    return await File(ActualPlaylist.listOfMusicFiles[ActualPlaylist.index].music).readAsBytes();
  }*/

  Future<bool> onBackPressed(){
    Navigator.pop(context);
  }
}
