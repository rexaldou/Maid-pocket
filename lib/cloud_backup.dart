import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'database_helper.dart';

class CloudService {
  static Future<void> autoBackupCloud(GoogleSignInAccount? currentUser) async {
    // Kalau belum login, nggak usah ngapa-ngapain
    if (currentUser == null) return;
    
    // Cek koneksi internet
    final List<ConnectivityResult> connectRes = await Connectivity().checkConnectivity();
    if (connectRes.contains(ConnectivityResult.none)) return;

    final firestore = FirebaseFirestore.instance;
    final String uid = currentUser.id;
    final lokalKantong = await DatabaseHelper.instance.ambilSemuaTabungan();

    for (var kntg in lokalKantong) {
      final String idDompet = kntg['id'].toString();
      
      // Backup data dompetnya
      await firestore
          .collection('users')
          .doc(uid)
          .collection('dompet')
          .doc(idDompet)
          .set({
        'nama': kntg['nama'], 
        'saldo': kntg['saldo'],
        'limit_kuning': kntg['limit_kuning'], 
        'limit_hijau': kntg['limit_hijau'],
        'tema_id': kntg['tema_id'],
      });

      // Backup semua riwayat transaksi di dalam dompet itu
      final lokalTrx = await DatabaseHelper.instance.ambilRiwayat(kntg['id']);
      for (var trx in lokalTrx) {
        await firestore
            .collection('users')
            .doc(uid)
            .collection('dompet')
            .doc(idDompet)
            .collection('transaksi')
            .doc(trx['id'].toString())
            .set({
          'amount': trx['amount'], 
          'notes': trx['notes'], 
          'created_at': trx['created_at'],
        });
      }
    }
  }
}