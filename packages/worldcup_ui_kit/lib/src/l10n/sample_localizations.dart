import 'generated/app_localizations.dart';

/// Localize built-in samples at display time, preserving stored user content.
extension SampleLocalizations on AppLocalizations {
  /// The repository combines these IDs with stored-text matches before paging.
  List<int> matchingSampleIds(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];
    return [
      for (final id in [-1, -2])
        if (worldCupTitle(id, '').toLowerCase().contains(normalized) ||
            worldCupInfo(id, '').toLowerCase().contains(normalized))
          id,
    ];
  }

  String worldCupTitle(int id, String original) => switch (id) {
    -1 => sampleFemaleTitle,
    -2 => sampleMaleTitle,
    _ => original,
  };

  String worldCupInfo(int id, String original) => switch (id) {
    -1 => sampleFemaleInfo,
    -2 => sampleMaleInfo,
    _ => original,
  };

  String worldCupItemInfo(
    int id,
    String imagePath,
    String original,
  ) => switch ((id, imagePath)) {
    (-1, 'assets/sample/female/aespa_carina.jpg') => sampleItemAespaCarina,
    (-1, 'assets/sample/female/hearts2_ian.jpg') => sampleItemHearts2Ian,
    (-1, 'assets/sample/female/nmix_sul.jpg') => sampleItemNmixSul,
    (-1, 'assets/sample/female/ive_jang.jpg') => sampleItemIveJang,
    (-1, 'assets/sample/female/babymon_ahyun.jpg') => sampleItemBabymonAhyun,
    (-1, 'assets/sample/female/promise_song.jpg') => sampleItemPromiseSong,
    (-1, 'assets/sample/female/ilit_wonhee.jpg') => sampleItemIlitWonhee,
    (-1, 'assets/sample/female/newjeans_haerin.jpg') =>
      sampleItemNewjeansHaerin,
    (-1, 'assets/sample/female/itzy_yuna.jpg') => sampleItemItzyYuna,
    (-1, 'assets/sample/female/rescene_won.jpg') => sampleItemResceneWon,
    (-1, 'assets/sample/female/meovv_anna.jpg') => sampleItemMeovvAnna,
    (-1, 'assets/sample/female/triples_chaewon.jpg') =>
      sampleItemTriplesChaewon,
    (-1, 'assets/sample/female/chu.jpg') => sampleItemChu,
    (-1, 'assets/sample/female/izone_hyewon.jpg') => sampleItemIzoneHyewon,
    (-1, 'assets/sample/female/idle_miyeon.jpg') => sampleItemIdleMiyeon,
    (-1, 'assets/sample/female/lesserafim_kimchaewon.jpg') =>
      sampleItemLesserafimKimchaewon,
    (-2, 'assets/sample/male/park_ji_hun.jpg') => sampleItemParkJiHun,
    (-2, 'assets/sample/male/cortis_gunho.jpg') => sampleItemCortisGunho,
    (-2, 'assets/sample/male/nct127_jaehyun.jpg') => sampleItemNct127Jaehyun,
    (-2, 'assets/sample/male/tws_dohun.jpg') => sampleItemTwsDohun,
    (-2, 'assets/sample/male/and2ble_yujin.jpg') => sampleItemAnd2BleYujin,
    (-2, 'assets/sample/male/bnd_myung.jpg') => sampleItemBndMyung,
    (-2, 'assets/sample/male/bts_v.jpg') => sampleItemBtsV,
    (-2, 'assets/sample/male/txt_yun.jpg') => sampleItemTxtYun,
    (-2, 'assets/sample/male/theboyz_juyeon.jpg') => sampleItemTheboyzJuyeon,
    (-2, 'assets/sample/male/riize_wonbin.jpg') => sampleItemRiizeWonbin,
    (-2, 'assets/sample/male/nctwish_riku.jpg') => sampleItemNctwishRiku,
    (-2, 'assets/sample/male/btob_yuk.jpg') => sampleItemBtobYuk,
    (-2, 'assets/sample/male/enhyphen_sunwoo.jpg') => sampleItemEnhyphenSunwoo,
    (-2, 'assets/sample/male/txt_taehyun.jpg') => sampleItemTxtTaehyun,
    (-2, 'assets/sample/male/astro_cha.jpg') => sampleItemAstroCha,
    (-2, 'assets/sample/male/got7_jinyoung.jpg') => sampleItemGot7Jinyoung,
    _ => original,
  };
}
