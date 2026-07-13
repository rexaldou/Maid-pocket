#include <iostream>
using namespace std;

int main () {
    long long gaji_masuk,bonus,gaji_total;
    int total_masuk;

    cout << "Masukan gaji pokok kamu\n";
    cin >> gaji_masuk;

    cout << "\nMasukan total tahun kamu selama bekerja di perusahaan ini\n";
    cin >> total_masuk;

    if (gaji_masuk < 5000000) {
        bonus = 0.05 * gaji_masuk;
    } else if (gaji_masuk < 10000000) {
        bonus = 0.1 * gaji_masuk;
    } else {
        bonus = 0.15 * gaji_masuk;
    }

    if (total_masuk >= 5) {
        bonus += 1000000;
    }

    gaji_total = gaji_masuk + bonus;

    cout << "Total gaji kamu adalah:Rp " << gaji_total << endl;
    cout << "Bonus kamu adalah:Rp " << bonus << endl;
    cout << "Gaji biasa kau adalah:Rp " << gaji_masuk << endl;
    cout << "Total tahun kamu bekerja disini adalah = " << total_masuk;
}