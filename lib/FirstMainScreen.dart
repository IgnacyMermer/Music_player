import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:muzyka2/database_helper.dart';
import 'package:sqflite/sqflite.dart';

import 'MusicFile.dart';
class FirstMainScreen extends StatefulWidget {
  @override
  _FirstMainScreenState createState() => _FirstMainScreenState();
}
class _FirstMainScreenState extends State<FirstMainScreen> {

  bool isPlaying=false;
  DatabaseHelper databaseHelper = new DatabaseHelper();

  int index=0;
  /*List<dynamic> listOfSongs=List();
  List<dynamic> listOfImages = List();*/
  List<MusicFile> listOfMusicFiles;

  AudioPlayer player;
  AudioCache cache;
  Duration position = new Duration();
  Duration musicLength = new Duration();
  File file;
  File image;
  String _path = "", fileName="";
  FileType _pickingType = FileType.audio;
  Uint8List listaBitow;

  CarouselController _carouselController = new CarouselController();
  ScrollController _scrollController = ScrollController();

  Widget slider(){
    return Container(
      width: 300,
      child: Slider.adaptive(
        value: position.inSeconds.toDouble(),
        max:musicLength.inSeconds.toDouble(),
        activeColor: Colors.white,
        inactiveColor: Colors.grey[700],
        onChanged: (value){
          seekToSec(value.toInt());
      })
    );
  }

  void _openFileExplorer(bool isImage, [int indexPom]) async {
    try {
      _pickingType=isImage?FileType.image:FileType.audio;
      file = await FilePicker.getFile(type: _pickingType);
      setState(() {
        if(file!=null) {
          if (isImage) {
            addImageFile(File(file.path), indexPom);
          }
          else {
            addMusicFile(File(file.path));
          }
        }
      });
    } catch (e) {
      print("Unsupported operation" + e.toString());
    }
  }

  void seekToSec(int value){
    Duration newPosition = new Duration(seconds: value);
    player.seek(newPosition);
  }


  @override
  void initState() {
    super.initState();
    player=AudioPlayer();
    cache=AudioCache(fixedPlayer: player);
    player.durationHandler=(d){
      setState(() {
        musicLength=d;
      });
    };

    player.positionHandler=(d){
      setState(() {
        position=d;
      });
    };
  }
  Future<Uint8List> readBytes() async{
    return await File(listOfMusicFiles[index].music).readAsBytes();
  }
  @override
  Widget build(BuildContext context) {

    if(listOfMusicFiles==null){
      listOfMusicFiles = List<MusicFile>();
      updateList();
    }
    List<String> tab = listOfMusicFiles.length>0?listOfMusicFiles[index].music.toString().split('/'):null;

    String nameOfSong = tab!=null?tab[tab.length-1]:'Choose a song';

    nameOfSong= nameOfSong.replaceAll(".mp3", "");

    return Scaffold(
      body: WillPopScope(
        onWillPop: onBackPressed,
        child: Container(
          width: double.infinity,
          color: Colors.grey[850],
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0,horizontal: 12.0),
            child: Container(
              child: ListView(
                children: [
                  Text("Muzyka",
                      style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white)),

                  RaisedButton(
                    color: Colors.blueGrey[700],
                    onPressed: () => _openFileExplorer(false),
                    child:Row(
                      children: [
                        SizedBox(width: 15),
                        Icon(Icons.music_note),
                        Expanded(child: Text("Dodaj plik .mp3", textAlign: TextAlign.center)),
                      ],
                    )
                  ),

                  SizedBox(height: 40),

                  CarouselSlider.builder(
                    carouselController: _carouselController,
                    options: CarouselOptions(height: 250,enableInfiniteScroll: false,  onPageChanged: onPhotoChanged),
                    itemCount: listOfMusicFiles.length,
                    itemBuilder: (BuildContext context, int itemIndex) {
                      return Container(
                        child: listOfMusicFiles[itemIndex].photo!=null?Container(child:Image.file(File(listOfMusicFiles[itemIndex].photo))):RaisedButton(child:Text("Add image"),
                        onPressed: (){
                          _openFileExplorer(true, itemIndex);
                        }),
                      );
                    }
                  ),

                  SizedBox(height: 40),

                  SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Text(listOfMusicFiles.length>0?nameOfSong:"Wybierz piosenkę",
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
                              Text('${position.inMinutes}:'+(position.inSeconds.remainder(60)<10?"0":"")+position.inSeconds.remainder(60).toString(),
                                  style: TextStyle(color: Colors.white)),

                              slider(),

                              Text('${musicLength.inMinutes}:'+(musicLength.inSeconds.remainder(60)<10?"0":"")+musicLength.inSeconds.remainder(60).toString(),
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [

                            IconButton(

                              icon: Icon(Icons.skip_previous, size: 45,color: index-1<0?Colors.grey[800]:Colors.white),

                              onPressed: index-1<0?null:()async{
                                index--;
                                _carouselController.animateToPage(index);
                                listaBitow = await readBytes();
                                isPlaying=true;
                                _scrollController.jumpTo(_scrollController.position.minScrollExtent);

                                setState(() {
                                  cache.playBytes(listaBitow);
                                });
                              },
                            ),

                            IconButton(

                              icon: Icon(isPlaying?Icons.pause:Icons.play_arrow, size: 45,color: Colors.white),

                              onPressed: () async{
                                if(isPlaying){
                                  player.pause();
                                  setState(() {
                                    isPlaying=!isPlaying;
                                  });
                                }

                                else{

                                    if(position.inSeconds==0) {
                                      listaBitow = await readBytes();
                                      cache.playBytes(listaBitow);
                                    }

                                    else{
                                      cache.playBytes(listaBitow);
                                      player.seek(position);
                                    }

                                    _scrollController.animateTo(
                                      _scrollController.position.maxScrollExtent,
                                      duration: Duration(milliseconds: nameOfSong.length*160),
                                      curve: Curves.easeInOut
                                    );

                                    _scrollController.addListener(() {

                                      if(_scrollController.offset==_scrollController.position.maxScrollExtent){
                                        _scrollController.animateTo(_scrollController.position.minScrollExtent,
                                            duration: Duration(milliseconds: nameOfSong.length*160),
                                            curve: Curves.easeInOut);
                                      }

                                      else if(_scrollController.offset==_scrollController.position.minScrollExtent){
                                        _scrollController.animateTo(
                                            _scrollController.position.maxScrollExtent,
                                            duration: Duration(milliseconds: nameOfSong.length*160),
                                            curve: Curves.easeInOut
                                        );

                                      }
                                    });

                                    setState(() {
                                      isPlaying=!isPlaying;
                                    });

                                  }
                              },
                            ),

                            IconButton(

                              icon: Icon(Icons.skip_next, size: 45,color: index+1>=listOfMusicFiles.length?Colors.grey[800]:Colors.white),

                              onPressed: index+1>=listOfMusicFiles.length?null:()async{
                                index++;
                                _carouselController.animateToPage(index);
                                listaBitow = await readBytes();
                                isPlaying=true;
                                _scrollController.jumpTo(_scrollController.position.minScrollExtent);

                                setState(() {
                                  cache.playBytes(listaBitow);
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
    );
  }

  void onPhotoChanged(int indexOfPhoto, reason)async{
    index=indexOfPhoto;
    listaBitow = await readBytes();
    isPlaying=true;

    setState(() {
      cache.playBytes(listaBitow);
    });
  }

  void updateList(){

    final Future<Database> dbFuture = databaseHelper.initialiseDatabase();

    dbFuture.then((database) {
      Future<List<MusicFile>> itemsListFuture = databaseHelper.getItemsList();
      itemsListFuture.then((itemList){
        setState(() {
          this.listOfMusicFiles=itemList;
        });
      });
    });
  }

  void addMusicFile(File musicFile){
    MusicFile musicFilePom = MusicFile(music: file.path, photo: null,/* isPlayingNow: false,*/ id: listOfMusicFiles.length);
    listOfMusicFiles.add(musicFilePom);
    databaseHelper.insertItem(musicFilePom);
  }

  void addImageFile(File imageFile, int index){
    MusicFile musicFilePom = listOfMusicFiles[index];
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
