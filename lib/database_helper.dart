import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muzyka2/MusicFile.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper{
  static DatabaseHelper _databaseHelper;
  static Database _database;

  String myTable = 'myTable';
  String colId = 'id';
  String colMusic = 'music';
  String colPhoto = 'photo';

  DatabaseHelper.createInstance();

  factory DatabaseHelper(){
    if(_databaseHelper==null) {
      _databaseHelper = DatabaseHelper.createInstance();
    }

    return _databaseHelper;
  }

  Future<Database> get database async{
    if(_database==null){
      _database = await initialiseDatabase();
    }
    return _database;
  }

  Future<Database> initialiseDatabase() async{
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path+'myDB.db';
    var myDB = await openDatabase(path,version: 1,onCreate: createDB);

    return myDB;

  }

  void createDB(Database db, int newVersion)async{
    await db.execute('CREATE TABLE $myTable($colId INTEGER PRIMARY KEY AUTOINCREMENT, $colMusic TEXT, $colPhoto TEXT)');
  }

  Future<List<Map<String, dynamic>>> getItemsMapList() async{
    Database db = await this.database;
    var result = await db.query(myTable);
    print('hi'+result.length.toString());
    return result;
  }
  
  Future<int> insertItem(MusicFile musicFile)async{
    Database db = await this.database;
    var result = await db.insert(myTable, musicFile.toMap());
    return result;
  }

  Future<int> updateItem(MusicFile musicFile)async{
    var db = await this.database;
    var result = await db.update(myTable, musicFile.toMap(), where: '$colId=?',
    whereArgs: [musicFile.id]);
    return result;
  }

  Future<int> deleteItem(int id)async{
    var db = await this.database;
    var result = await db.delete(myTable, where: '$colId=$id');
    return result;
  }

  Future<List<MusicFile>> getItemsList() async{
    List<Map<String, dynamic>> itemsMapList = await getItemsMapList();
    List<MusicFile> itemsList = List<MusicFile>();
    for(int i=0;i<itemsMapList.length;i++){
      itemsList.add(MusicFile.fromMap(itemsMapList[i]));
    }
    return itemsList;
  }

}