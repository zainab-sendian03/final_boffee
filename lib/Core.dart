// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:userboffee/Core/constants/colors.dart';
import 'package:userboffee/Core/provider/Theme_provider.dart';
import 'package:userboffee/views/baises_screen/BooksUi.dart';
import 'package:userboffee/views/baises_screen/Levels_Ui.dart';

import 'package:userboffee/views/baises_screen/QuetsPage.dart';
import 'package:userboffee/views/baises_screen/Shelves_Ui.dart';
import 'package:userboffee/views/baises_screen/setting.dart';

class CorePage extends StatefulWidget {
  const CorePage({
    Key? key,
  }) : super(key: key);
  @override
  _CorePageState createState() => _CorePageState();
}

class _CorePageState extends State<CorePage> {
  int page = 0;
  GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  List<Widget> Pages = [QuetsPage(), BookUi(), Shelves_UI(), Levels_UI()];
  List<String> AppBarTitle = ["Home", "Books", "Shelves", "Levels"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth:150,
        leading:Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: 150,
            child: Text(
              AppBarTitle[page],
              style: TextStyle(color: dark_Brown,fontSize: 20,fontWeight: FontWeight.w500),
            ),
          ),
        ) ,
        actions: [
          
          PopupMenuButton(
            onSelected: (value) {
              if(value=="value_Setting"){
                Navigator.push(context, MaterialPageRoute(builder: (context){return SettingUi();}));
              }
            },
            iconColor:dark_Brown,
            color: biege,
              itemBuilder: (context) => [
                
                    PopupMenuItem(
                        child: Row(
                      children: [Icon(Icons.settings,color: dark_Brown,), Text("Setting",style: TextStyle(color: dark_Brown),
                      
                      ),],
                    ),value: "value_Setting",),
                    PopupMenuItem(
                        child: Row(
                      children: [Icon(Icons.person,color: dark_Brown,), Text("My Profile",style: TextStyle(color: dark_Brown))],
                    )
                    ,value: "value_Profile",),
                    PopupMenuItem(
                        child: Row(
                      children: [Icon(Icons.logout,color: dark_Brown,), Text("Logout",style: TextStyle(color: dark_Brown))],
                    ),value: "value_Logout",),
                     PopupMenuItem(
                        child: Row(
                      children: [Icon(Icons.email,color: dark_Brown,), Text("Contact us",style: TextStyle(color: dark_Brown))],
                    ),value: "value_Contact",)
                  ])
        ],
        backgroundColor: Light_Brown,
       
      ),
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: 0,
        items: [
          CurvedNavigationBarItem(
            child: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.book),
            label: 'Books',
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.shelves),
            label: 'Shelves',
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.add_chart),
            label: 'Levels',
          ),
        ],
        color: Light_Brown,
        buttonBackgroundColor: medium_Brown,
        backgroundColor: no_color,
        animationCurve: Curves.linear,
        animationDuration: Duration(milliseconds: 600),
        onTap: (index) {
          setState(() {
            page = index;
          });
        },
        letIndexChange: (index) => true,
      ),
      body: Pages[page],
    );
  }
}
