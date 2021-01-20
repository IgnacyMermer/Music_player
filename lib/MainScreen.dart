import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:muzyka2/ActualPlaylist.dart';
import 'package:muzyka2/FirstMainScreen.dart';
import 'package:muzyka2/NowPlayingFile.dart';
import 'package:muzyka2/ShowPlaylist.dart';
import 'package:sqflite/sqflite.dart';

import 'MusicFile.dart';
import 'database_helper.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  DatabaseHelper databaseHelper = new DatabaseHelper();

  @override
  void initState() {
    super.initState();
    updateList();

    if(NowPlayingFile.position==null)NowPlayingFile.position=new Duration();
    if(NowPlayingFile.musicLength==null)NowPlayingFile.musicLength=new Duration();

    if(NowPlayingFile.player==null)NowPlayingFile.player=AudioPlayer();
    if(NowPlayingFile.cache==null)NowPlayingFile.cache=AudioCache(fixedPlayer: NowPlayingFile.player);

    NowPlayingFile.player.durationHandler=(d){
      NowPlayingFile.musicLength=d;

    };

    NowPlayingFile.player.positionHandler=(d)async{

      if(d.inSeconds==NowPlayingFile.musicLength.inSeconds){

        NowPlayingFile.player.pause();

        if(ActualPlaylist.index+1<ActualPlaylist.listOfMusicFiles.length) {

          ActualPlaylist.index++;

          NowPlayingFile.listaBitow = await NowPlayingFile.readBytes();
          NowPlayingFile.isPlaying = true;

          NowPlayingFile.cache.playBytes(NowPlayingFile.listaBitow);
        }

        else{

          NowPlayingFile.position=new Duration();
          NowPlayingFile.isPlaying=false;
        }

      }

      else {

        NowPlayingFile.position = d;

      }
    };
  }


  @override
  Widget build(BuildContext context) {

    if(ActualPlaylist.listOfPlaylist==null){
      ActualPlaylist.listOfPlaylist=new List();
    }


    List<String> tab = ActualPlaylist.listOfMusicFiles!=null?ActualPlaylist.listOfMusicFiles[ActualPlaylist.index].music.toString().split('/'):null;

    NowPlayingFile.title = tab!=null?tab[tab.length-1]:'Choose a song';

    NowPlayingFile.title= NowPlayingFile.title.replaceAll(".mp3", "");

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
                barrierColor: Colors.black.withOpacity(0.5),
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
              ).then((value) {refreshScreen();});
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


                Container(width: MediaQuery.of(context).size.width*3/4,child: Text(NowPlayingFile.title!=null?NowPlayingFile.title:"Dodaj piosenkę")),


                ActualPlaylist.index!=null&&ActualPlaylist.listOfMusicFiles!=null?
                IconButton(
                  icon: Icon(Icons.skip_next,
                      color: ActualPlaylist.index+1<ActualPlaylist.listOfMusicFiles.length?Colors.white:Colors.grey[800]),

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
          color: Colors.grey[900],
          child: Column(
            children: [
              ActualPlaylist.listOfPlaylist.length!=0?
              ListView(physics: NeverScrollableScrollPhysics(), shrinkWrap: true, scrollDirection: Axis.vertical,
              children: ActualPlaylist.listOfPlaylist.map((item) =>
                Container(color:Colors.grey,child:
                  RaisedButton(color: Colors.blueGrey[700],

                    child: Text(item.music,style: TextStyle(color:Colors.white)),
                    onPressed: (){

                    ActualPlaylist.name=item.music.replaceAll(" ","");

                    Navigator.push(context, PageRouteBuilder(
                      pageBuilder: (_, __, ___) => ShowPlaylist(),
                      transitionDuration: Duration(seconds: 0),
                    )).then((value) {refreshScreen();});
                  },
              ))).toList()):Container(),
              RaisedButton(
                child:Text("Dodaj playlistę"),
                onPressed: (){
                  showDialog(context: context, builder:
                  (BuildContext context)=>alertAddPlaylist(context)
                  );
                },
              )
            ],
          )
        ),
      ),
    );
  }

  void refreshScreen(){
    setState(() {});
  }


  String nazwaNowejPlaylisty;

  Widget alertAddPlaylist(BuildContext context){
    final formKey = GlobalKey<FormState>();
    return new AlertDialog(
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Dodaj nową playlistę', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 22)),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Container(
                    padding: EdgeInsets.only(left: 15,right: 15),
                    width:260,
                    child:TextFormField(
                      style: TextStyle(fontSize: 18,color: Colors.black),
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: 'Nazwa',
                        hintStyle: TextStyle(color: Colors.grey[700]),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white,width: 2.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green[900], width: 2.0),
                        ),
                      ),
                      textAlign: TextAlign.center,
                      onChanged: (val) => setState((){
                        nazwaNowejPlaylisty = val.toString();
                      }),
                      validator: (val)=>val.isEmpty? 'Podaj nazwę' :null,
                    )),
                ),
                SizedBox(width: 10),
              ],
            ),
            SizedBox(height: 20),
            ButtonBar(
              alignment: MainAxisAlignment.end,
              children: [
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  textColor: Colors.cyan,
                  child: Text('Zamknij'),
                ),
                FlatButton(
                  onPressed: () {
                    if(formKey.currentState.validate()) {
                      setState(() {
                        addPlaylist();
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  textColor: Colors.cyan,
                  child: Text('Dodaj'),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  void updateList(){
    final Future<Database> dbFuture = databaseHelper.initialiseDatabase("myPlaylist");
    dbFuture.then((database) {
      Future<List<MusicFile>> itemsListFuture = databaseHelper.getItemsList();
      itemsListFuture.then((itemList){
        setState(() {
          ActualPlaylist.listOfPlaylist=itemList;
        });
      });
    });
  }

  void addPlaylist(){
    MusicFile musicFilePom = MusicFile(music: nazwaNowejPlaylisty.replaceAll(" ", "_"), photo: null, id:ActualPlaylist.listOfPlaylist.length);
    ActualPlaylist.listOfPlaylist.add(musicFilePom);
    databaseHelper.insertItem(musicFilePom);
  }

  Future<bool> onBackPressed(){

  }
}
