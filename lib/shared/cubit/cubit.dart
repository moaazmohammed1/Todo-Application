import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:todo_app/modules/archive_tasks/archived_task.dart';
import 'package:todo_app/modules/done_tasks/done_task.dart';
import 'package:todo_app/modules/new_tasks/new_task.dart';
import 'package:todo_app/shared/cubit/states.dart';


class AppCubit extends Cubit<AppStates> {
  AppCubit() : super(AppInitialState());

  static AppCubit get(context) => BlocProvider.of(context);

  int currentIndex = 0;

  List<Widget> taskType = [
    NewTask(),
    DoneTask(),
    ArchivedTask(),
  ];

  List<String> titleTasks = [
    'New Tasks',
    'Done Tasks',
    'Archived Tasks',
  ];

  void changeIndex(int index) {
    currentIndex = index;
    emit(AppBottomNavigationBarState());
  }

  Database? database;
  List<Map> newTasks = [];
  List<Map> doneTasks = [];
  List<Map> archiveTasks = [];
  bool isBottomSheetShown = false;
  Icon iconBottomSheet = const Icon(Icons.edit);

  void createDatabase() {
    openDatabase('todo_app.db', version: 1, onCreate: (database, version) {
      print('create database');
      database
          .execute(
              'CREATE TABLE tasks (id INTEGER PRIMARY KEY, title TEXT, time TEXT, date TEXT, status TEXT)')
          .then((value) {
        print('create table');
      }).catchError((error) {
        print('Error when create table ${error.toString()}');
      });
    }, onOpen: (database) {
      getDataFromDatabase(database);

      print('Open Database');
    }).then((value) {
      database = value;
      emit(AppCreateDatabaseState());
    });
  }

  insertToDatabase({
    required String title,
    required String time,
    required String date,
  }) async {
    await database!.transaction((txn) async {
      await txn
          .rawInsert(
              'INSERT INTO tasks(title, time, date, status) VALUES("$title", "$time", "$date", "NEW")')
          .then((value) {
        print('$value Inserted Successfully');
        emit(AppInsertDatabaseState());

        getDataFromDatabase(database);
      }).catchError((error) {
        print('Error When Inserting New Record ${error.toString()}');
      });
      return null;
    });
  }

  void getDataFromDatabase(database) {
    newTasks = [];
    doneTasks = [];
    archiveTasks = [];
    emit(AppGetDatabaseLoadingState());
    database!.rawQuery('SELECT * FROM tasks').then((value) {
      // tasks = value;
      // print(tasks);
      value.forEach((element) {
        if (element['status'] == 'NEW') {
          newTasks.add(element);
        } else if (element['status'] == 'done') {
          doneTasks.add(element);
        } else {
          archiveTasks.add(element);
        }
      });
      emit(AppGetDatabaseState());
    });
  }

  void updateData({required String status, required int id}) {
    database!.rawUpdate(
      'UPDATE tasks SET status = ? WHERE id = ?',
      ['$status', id],
    ).then((value) {
      getDataFromDatabase(database);
      emit(AppUpdateDatabaseState());
    });
  }

  void deleteData({required int id}) {
    database!.rawDelete(
      'DELETE FROM tasks WHERE id = ?',
      [id],
    ).then((value) {
      getDataFromDatabase(database);
      emit(AppDeleteDatabaseState());
    });
  }

  changeBottomSheetShown({required bool isBottomSheet, required Icon icon}) {
    isBottomSheetShown = isBottomSheet;
    iconBottomSheet = icon;
    emit(AppBottomSheetShownState());
  }
}
