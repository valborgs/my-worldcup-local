import 'package:flutter/material.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

class WorldCupSelectProvider extends ChangeNotifier{

  // 선택한 아이템(top, bottom)
  SelectedItemPosition _selectedItemPosition = SelectedItemPosition.none;

  SelectedItemPosition get selectedItemPosition => _selectedItemPosition;

  // 선택한 아이템 id
  WorldCupItemModel _selectedModel = const WorldCupItemModel(-1, "", "", -1);

  WorldCupItemModel get selectedModel => _selectedModel;


  void setSelectedItem(SelectedItemPosition item, WorldCupItemModel model){
    _selectedItemPosition = item;
    _selectedModel = model;
    notifyListeners();
  }

  // 현재 대결에서 이미 항목을 선택했는지 여부.
  // GameItem의 탭 가능 여부를 판단하는 유일한 기준으로 사용한다.
  bool get hasSelected => _selectedItemPosition != SelectedItemPosition.none;

  // 새 대결(라운드)을 시작할 때 선택 상태를 초기화한다.
  // notifyListeners를 호출하지 않는다: 리스너(GameItem)는 선택 여부에 따라
  // 슬라이드 애니메이션을 트리거하므로, 여기서 알림을 보내면 두 항목이
  // 모두 "선택되지 않음"으로 인식되어 화면 밖으로 밀려나는 애니메이션이
  // 잘못 재생된다.
  void resetSelection(){
    _selectedItemPosition = SelectedItemPosition.none;
  }
}