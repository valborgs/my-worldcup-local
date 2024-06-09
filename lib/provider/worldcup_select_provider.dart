import 'package:flutter/material.dart';

import '../models/worldcup_item_model.dart';
import '../widgets/worldcup_game.dart';

class WorldCupSelectProvider extends ChangeNotifier{

  // 선택한 아이템(top, bottom)
  SelectedItemPosition _selectedItemPosition = SelectedItemPosition.none;

  SelectedItemPosition get selectedItemPosition => _selectedItemPosition;

  // 선택한 아이템 id
  WorldCupItemModel _selectedModel = WorldCupItemModel(-1, "", "", -1);

  WorldCupItemModel get selectedModel => _selectedModel;


  void setSelectedItem(SelectedItemPosition item, WorldCupItemModel model){
    _selectedItemPosition = item;
    _selectedModel = model;
    notifyListeners();
  }
}