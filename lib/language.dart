class Lang {
  static String kodeBahasa = 'id';

  static final Map<String, Map<String, String>> _kamus = {
    'id': {
      'judul': 'Maid Pocket',
      'masuk': 'Masuk',
      'keluar': 'Keluar',
      'transfer': 'Transfer',
      'riwayat': 'Riwayat Terakhir',
      'lihat_semua': 'Lihat Semua',
      'dompet_kosong': 'Uhee~ dompetnya masih kosong, Senpai!',
      'pilih_mood': 'Pilih Mood Dompet',
    },
    'en': {
      'judul': 'Maid Pocket',
      'masuk': 'Income',
      'keluar': 'Outcome',
      'transfer': 'Transfer',
      'riwayat': 'Recent History',
      'lihat_semua': 'View All',
      'dompet_kosong': 'Uhee~ your wallet is empty, Senpai!',
      'pilih_mood': 'Choose Wallet Mood',
    }
  };

  static String txt(String kunci) {
    return _kamus[kodeBahasa]?[kunci] ?? kunci;
  }
}