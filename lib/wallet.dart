import 'package:http/http.dart';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:web3dart/web3dart.dart';

class SaturnWallet {
  loadBalance() async {
    var box = await Hive.openBox('myBox');
    getBalance(box.get('pk'));
  }

  genWallet() async {
    var rng = new Random.secure();
    Credentials creds = EthPrivateKey.createRandom(rng);
    var box = await Hive.openBox('myBox');
    var addr = await creds.extractAddress();
    box.put('pk', addr.hex);

    print(addr);
  }

  getBalance(String pk) async {
    var apiUrl =
        "https://mainnet.infura.io/v3/b63606f0825343fd85b553d6e471a53b"; //Replace with your API

    var httpClient = new Client();
    var ethClient = new Web3Client(apiUrl, httpClient);

    var credentials = await ethClient.credentialsFromPrivateKey(pk);
    var addr = await credentials.extractAddress();

// You can now call rpc methods. This one will query the amount of Ether you own
    EtherAmount balance = await ethClient.getBalance(addr);
    print(balance.getValueInUnit(EtherUnit.ether));
  }
}
