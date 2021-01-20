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
  List<String> listOfTitles=new List();

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

    for(MusicFile musicFile in ActualPlaylist.listOfMusicFiles){
      List<String> tab = musicFile.music.toString().split('/');

      String temp = tab!=null?tab[tab.length-1]:'Wybierz piosenkę';

      listOfTitles.add(temp.replaceAll(".mp3", ""));
    }



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
                    icon: Icon(NowPlayingFile.isPlaying?Icons.pause:Icons.play_arrow,color:Colors.white),
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


                  Container(width: MediaQuery.of(context).size.width*3/4,
                      child: Text(NowPlayingFile.title!=null?NowPlayingFile.title:"Dodaj piosenkę")),


                  ActualPlaylist.index!=null&&ActualPlaylist.listOfMusicFiles!=null?
                  IconButton(
                    icon: Icon(Icons.skip_next, color: ActualPlaylist.index+1<ActualPlaylist.listOfMusicFiles.length?
                    Colors.white:Colors.grey[800]),

                    onPressed: ActualPlaylist.index+1>=ActualPlaylist.listOfMusicFiles.length?null:()async{
                      ActualPlaylist.index++;
                      NowPlayingFile.listaBitow = await NowPlayingFile.readBytes();
                      NowPlayingFile.isPlaying=true;

                      setState(() {
                        NowPlayingFile.cache.playBytes(NowPlayingFile.listaBitow);
                      });
                    },
                  ):Container(),
                ],
              ),
            )
        ),
        body: Container(
            color: Colors.grey[850],
            child: Column(
              children: [
                SizedBox(height: 40),

                RaisedButton(
                    color: Colors.blueGrey[700],
                    onPressed: () => _openFileExplorer(),
                    child:Row(
                      children: [
                        SizedBox(width: 15),
                        Icon(Icons.music_note,color: Colors.white,size: 25,),
                        Expanded(child: Text("Dodaj utwór", textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white,fontSize: 22))),
                      ],
                    )
                ),
                SizedBox(height: 40),
                ActualPlaylist.listOfMusicFiles.length!=0?
                  ListView(physics: NeverScrollableScrollPhysics(), shrinkWrap: true, scrollDirection: Axis.vertical,
                    children: ActualPlaylist.listOfMusicFiles.map((item) => Container(color:Colors.transparent,child:RaisedButton(
                      color: Colors.blueGrey[700],
                      child: Text(listOfTitles[item.id],
                          style: TextStyle(color:Colors.white),textAlign: TextAlign.center),
                      onPressed: ()async{

                        ActualPlaylist.index = item.id;

                        List<String> tab = ActualPlaylist.listOfMusicFiles.length>0?ActualPlaylist.listOfMusicFiles[ActualPlaylist.index].music.toString().split('/'):null;

                        NowPlayingFile.title = tab!=null?tab[tab.length-1]:'Wybierz piosenkę';

                        NowPlayingFile.title= NowPlayingFile.title.replaceAll(".mp3", "");

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
    bool isFound=false;
    for(MusicFile musicFilePom in ActualPlaylist.listOfMusicFiles){
      if(musicFilePom.music==file.path){
        isFound=true;
      }
    }
    if(!isFound) {
      MusicFile musicFilePom = MusicFile(music: file.path,
          photo: null,
          id: ActualPlaylist.listOfMusicFiles.length);

      ActualPlaylist.listOfMusicFiles.add(musicFilePom);
      databaseHelper.insertItem(musicFilePom);
    }
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

  Future<bool> onBackPressed(){
    Navigator.pop(context);
  }
}
