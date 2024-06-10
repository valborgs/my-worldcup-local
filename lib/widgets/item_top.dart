import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_worldcup_local/widgets/worldcup_game.dart';
import 'package:provider/provider.dart';

import '../models/worldcup_item_model.dart';
import '../provider/worldcup_select_provider.dart';

class ItemTop extends StatefulWidget {
  WorldCupItemModel itemModel;
  ItemTop(this.itemModel, {super.key});

  @override
  State<ItemTop> createState() => _ItemTopState();
}

class _ItemTopState extends State<ItemTop> with TickerProviderStateMixin {

  late AnimationController _controller;
  late Tween<Offset> _tween;
  late Animation<Offset> _animation;

  void resetController(){
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _tween = Tween<Offset>(begin: const Offset(0,0), end: const Offset(0,0));
    _animation = _tween.animate(CurvedAnimation(parent: _controller, curve: Curves.decelerate));
  }

  @override
  void initState() {
    super.initState();
    resetController();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    resetController();
    // Provider
    var selectProvider = Provider.of<WorldCupSelectProvider>(context, listen: false);

    if(_animation.status == AnimationStatus.completed){
      _controller.reset();
      resetController();
    }

    selectProvider.addListener(() {
      if(selectProvider.selectedItemPosition == SelectedItemPosition.top){
        _tween.end = const Offset(0, 0.5);
        _controller.forward();
      }else{
        _tween.end = const Offset(0, -1.1);
        _controller.forward();
      }
    });

    return Expanded(
      child: SlideTransition(
        position: _animation,
        child: InkWell(
          onTap: () {
            selectProvider.setSelectedItem(SelectedItemPosition.top, widget.itemModel);
          },
          child: Container(
            color: Colors.black,
            child: Center(
              child: Stack(
                children: [
                  Image.file(
                    File(widget.itemModel.imagePath),
                    width: double.infinity/2,
                    height: double.infinity/2,
                    fit: BoxFit.contain,
                  ),
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(top: 150),
                    child: Text(
                      widget.itemModel.imageInfo,
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        backgroundColor: Colors.grey.withOpacity(0.5),
                      ),
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
}
