import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:muzyka2/ActualPlaylist.dart';
import 'package:muzyka2/NowPlayingFile.dart';
import 'package:muzyka2/database_helper.dart';
import 'package:sqflite/sqflite.dart';

import 'MusicFile.dart';
class FirstMainScreen extends StatefulWidget {
  @override
  _FirstMainScreenState createState() => _FirstMainScreenState();
}
class _FirstMainScreenState extends State<FirstMainScreen> {

  DatabaseHelper databaseHelper=  new DatabaseHelper();

  File file;
  File image;
  String fileName="";
  FileType pickingType = FileType.audio;


  CarouselController _carouselController = new CarouselController();
  ScrollController _scrollController = ScrollController();

  Timer timer;

  Widget slider(){
    return Container(
      width: 300,
      child: Slider.adaptive(

        value: NowPlayingFile.position.inSeconds.toDouble()<=NowPlayingFile.musicLength.inSeconds.toDouble()?NowPlayingFile.position.inSeconds.toDouble():
        NowPlayingFile.musicLength.inSeconds.toDouble(),

        max:NowPlayingFile.musicLength.inSeconds.toDouble(),
        activeColor: Colors.white,
        inactiveColor: Colors.grey[700],

        onChanged: (value){
          seekToSec(value.toInt());
      })
    );
  }

  void _openFileExplorer([int indexPom]) async {
    try {
      pickingType=FileType.image;
      file = await FilePicker.getFile(type: pickingType);
      setState(() {
        if(file!=null) {
          addImageFile(File(file.path), indexPom);
        }
      });
    } catch (e) {
      print("Unsupported operation" + e.toString());
    }
  }

  void seekToSec(int value){
    Duration newPosition = new Duration(seconds: value);
    NowPlayingFile.player.seek(newPosition);
  }


  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
    });

  }

  void goOut(){
    timer.cancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    if(ActualPlaylist.listOfMusicFiles==null){
      ActualPlaylist.listOfMusicFiles = List<MusicFile>();
      updateList();
    }
    List<String> tab = ActualPlaylist.listOfMusicFiles.length>0?ActualPlaylist.listOfMusicFiles[ActualPlaylist.index].music.toString().split('/'):null;

    NowPlayingFile.title = tab!=null?tab[tab.length-1]:'Choose a song';

    NowPlayingFile.title= NowPlayingFile.title.replaceAll(".mp3", "");

    return Dismissible(

      key:const Key('key'),
      onDismissed: (_) => goOut(),
      direction: DismissDirection.down,


      child:Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: Icon(Icons.keyboard_arrow_down),
            splashRadius: 20,
            splashColor: Colors.grey[900],
            onPressed: (){
              goOut();
          }),
          title: Text("Muzyka"),
        ),
        body: WillPopScope(
          onWillPop: onBackPressed,
          child: Container(
            width: double.infinity,
            color: Colors.grey[850],

            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0,horizontal: 12.0),
              child: Container(
                child: Column(
                  children: [


                    SizedBox(height: 40),

                    CarouselSlider.builder(
                      carouselController: _carouselController,
                      options: CarouselOptions(height: 250,enableInfiniteScroll: false,  onPageChanged: onPhotoChanged,initialPage: ActualPlaylist.index),
                      itemCount: ActualPlaylist.listOfMusicFiles.length,
                      itemBuilder: (BuildContext context, int itemIndex) {
                        return Container(
                          child: ActualPlaylist.listOfMusicFiles[itemIndex].photo!=null?
                          Container(child:Image.file(File(ActualPlaylist.listOfMusicFiles[itemIndex].photo))):
                          RaisedButton(child:Text("Add image"),
                          onPressed: (){
                            _openFileExplorer(itemIndex);
                          }),
                        );
                      }
                    ),

                    SizedBox(height: 40),

                    SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      child: Text(ActualPlaylist.listOfMusicFiles.length>0?NowPlayingFile.title:"Wybierz piosenkę",
                        style: TextStyle(color: Colors.white,fontSize: 32, fontWeight: FontWeight.w600),maxLines: 1,
                      ),
                    ),

                    SizedBox(height: 20),

                    Container(
                      child: Column(
                        children: [

                          Container(
                            width: 500,
                            child: Row(
                              children: [
                                Text('${NowPlayingFile.position.inMinutes}:'+(NowPlayingFile.position.inSeconds.remainder(60)<10?"0":"")
                                    +NowPlayingFile.position.inSeconds.remainder(60).toString(),
                                    style: TextStyle(color: Colors.white)),

                                slider(),

                                Text('${NowPlayingFile.musicLength.inMinutes}:'+(NowPlayingFile.musicLength.inSeconds.remainder(60)<10?"0":"")
                                    +NowPlayingFile.musicLength.inSeconds.remainder(60).toString(),
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [

                              IconButton(

                                icon: Icon(Icons.skip_previous, size: 45,color: ActualPlaylist.index-1<0?Colors.grey[800]:Colors.white),

                                onPressed: ActualPlaylist.index-1<0?null:()async{
                                  ActualPlaylist.index--;
                                  _carouselController.animateToPage(ActualPlaylist.index);
                                  NowPlayingFile.listaBitow = await NowPlayingFile.readBytes();
                                  NowPlayingFile.isPlaying=true;
                                  _scrollController.jumpTo(_scrollController.position.minScrollExtent);

                                  setState(() {
                                    NowPlayingFile.cache.playBytes(NowPlayingFile.listaBitow);
                                  });
                                },
                              ),

                              IconButton(

                                icon: Icon(NowPlayingFile.isPlaying?Icons.pause:Icons.play_arrow, size: 45,color: Colors.white),

                                onPressed: () async{
                                  if(NowPlayingFile.isPlaying){
                                    NowPlayingFile.player.pause();
                                    setState(() {
                                      NowPlayingFile.isPlaying=!NowPlayingFile.isPlaying;
                                    });
                                  }

                                  else{

                                      if(NowPlayingFile.position.inSeconds==0) {
                                        NowPlayingFile.listaBitow = await NowPlayingFile.readBytes();
                                        NowPlayingFile.cache.playBytes(NowPlayingFile.listaBitow);
                                      }

                                      else{
                                        NowPlayingFile.cache.playBytes(NowPlayingFile.listaBitow);
                                        NowPlayingFile.player.seek(NowPlayingFile.position);
                                      }

                                      _scrollController.animateTo(
                                        _scrollController.position.maxScrollExtent,
                                        duration: Duration(milliseconds: NowPlayingFile.title.length*160),
                                        curve: Curves.easeInOut
                                      );

                                      _scrollController.addListener(() {

                                        if(_scrollController.offset==_scrollController.position.maxScrollExtent){
                                          _scrollController.animateTo(_scrollController.position.minScrollExtent,
                                              duration: Duration(milliseconds: NowPlayingFile.title.length*160),
                                              curve: Curves.easeInOut);
                                        }

                                        else if(_scrollController.offset==_scrollController.position.minScrollExtent){
                                          _scrollController.animateTo(
                                              _scrollController.position.maxScrollExtent,
                                              duration: Duration(milliseconds: NowPlayingFile.title.length*160),
                                              curve: Curves.easeInOut
                                          );

                                        }
                                      });

                                      setState(() {
                                        NowPlayingFile.isPlaying=!NowPlayingFile.isPlaying;
                                      });

                                    }
                                },
                              ),

                              IconButton(

                                icon: Icon(Icons.skip_next, size: 45,color: ActualPlaylist.index+1>=
                                    ActualPlaylist.listOfMusicFiles.length?Colors.grey[800]:Colors.white),

                                onPressed: ActualPlaylist.index+1>=ActualPlaylist.listOfMusicFiles.length?null:()async{
                                  ActualPlaylist.index++;
                                  _carouselController.animateToPage(ActualPlaylist.index);
                                  NowPlayingFile.listaBitow = await NowPlayingFile.readBytes();
                                  NowPlayingFile.isPlaying=true;
                                  _scrollController.jumpTo(_scrollController.position.minScrollExtent);

                                  setState(() {
                                    NowPlayingFile.cache.playBytes(NowPlayingFile.listaBitow);
                                  });
                                },
                              ),

                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      )
    );
  }

  void onPhotoChanged(int indexOfPhoto, reason)async{
    ActualPlaylist.index=indexOfPhoto;
    NowPlayingFile.listaBitow = await NowPlayingFile.readBytes();
    NowPlayingFile.isPlaying=true;

    setState(() {
      NowPlayingFile.cache.playBytes(NowPlayingFile.listaBitow);
    });
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

  void addMusicFile(File musicFile){
    MusicFile musicFilePom = MusicFile(music: file.path, photo: null, id: ActualPlaylist.listOfMusicFiles.length);
    ActualPlaylist.listOfMusicFiles.add(musicFilePom);
    databaseHelper.insertItem(musicFilePom);
  }

  void addImageFile(File imageFile, int index){
    MusicFile musicFilePom = ActualPlaylist.listOfMusicFiles[index];
    musicFilePom.photo= imageFile.path;
    databaseHelper.updateItem(musicFilePom);
  }

  Future<bool> onBackPressed(){
    showDialog(context: context, builder: (BuildContext context)=>alertCloseApp(context));
  }

  Widget alertCloseApp(BuildContext context) {
    return AlertDialog(
      title: Text('Czy chcesz opuścić aplikację?'),
      content: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[],
      ),
      actions: <Widget>[
        FlatButton(
          onPressed: () {
            SystemNavigator.pop();
          },
          textColor: Colors.cyan,
          child: Text('Tak, opuść'),
        ),
        new FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          textColor: Colors.cyan,
          child: const Text('Anuluj'),
        ),
      ],
    );
  }
}
