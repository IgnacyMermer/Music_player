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
  }

  @override
  Widget build(BuildContext context) {
    if(ActualPlaylist.listOfPlaylist==null){
      ActualPlaylist.listOfPlaylist=new List();
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
              );
            },
            child: Row(
              children: [

                IconButton(
                  icon: Icon(NowPlayingFile.isPlaying?Icons.stop:Icons.play_arrow,color:Colors.black),
                  onPressed: (){

                  },
                ),


                Container(width: MediaQuery.of(context).size.width*3/4,child: Text(NowPlayingFile.title!=null?NowPlayingFile.title:"Add song")),


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
              ActualPlaylist.listOfPlaylist.length!=0?ListView(physics: NeverScrollableScrollPhysics(), shrinkWrap: true, scrollDirection: Axis.vertical,
              children: ActualPlaylist.listOfPlaylist.map((item) => Container(color:Colors.grey,child:RaisedButton(
                child: Text(item.music,style: TextStyle(color:Colors.white)),onPressed: (){
                  ActualPlaylist.name=item.music.replaceAll(" ","");
                  Navigator.push(context, PageRouteBuilder(
                    pageBuilder: (_, __, ___) => ShowPlaylist(),
                    transitionDuration: Duration(seconds: 0),
                  ),);
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
