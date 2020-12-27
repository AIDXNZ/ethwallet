import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:hive/hive.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:majascan/majascan.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FormPage extends StatefulWidget {
  FormPage({Key key}) : super(key: key);

  @override
  _FormPageState createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  TextEditingController addrController = TextEditingController();
  TextEditingController ammountController = TextEditingController();

  _showCupertinoDialog() {
    showDialog(
        context: context,
        builder: (_) => new CupertinoAlertDialog(
              title: new Text("Warning"),
              content: new Text("Are you sure you want to send?"),
              actions: <Widget>[
                FlatButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                  child: Text('Send All'),
                  onPressed: () {
                    if (addrController.text.isNotEmpty) {
                      sendAll();
                    } else {
                      Fluttertoast.showToast(msg: 'Missing address field');
                    }
                    Navigator.of(context).pop();
                  },
                )
              ],
            ));
  }

  Future<double> getBalance(Credentials creds) async {
    var apiUrl =
        "https://mainnet.infura.io/v3/b63606f0825343fd85b553d6e471a53b"; //Replace with your API

    var httpClient = new Client();
    var ethClient = new Web3Client(apiUrl, httpClient);

    var addr = await creds.extractAddress();

// You can now call rpc methods. This one will query the amount of Ether you own
    EtherAmount balance = await ethClient.getBalance(addr);
    print(balance.getValueInUnit(EtherUnit.ether));
    print("Wei ${balance.getValueInUnit(EtherUnit.wei)}");
    return balance.getValueInUnit(EtherUnit.ether);
  }

  sendAll() async {
    var box = await Hive.openBox('myBox');
    String content = box.get('wallet');
    Wallet wallet = Wallet.fromJson(content, 'password');
    Credentials credentials = wallet.privateKey;
    var balance = await getBalance(credentials);
    var apiUrl =
        "https://mainnet.infura.io/v3/b63606f0825343fd85b553d6e471a53b"; //Replace with your API
    var httpClient = new Client();
    var ethClient = new Web3Client(apiUrl, httpClient);
    var cli = Client();
    var res = await cli.get(
        'https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd');
    print(res.body);
    var ethToUsd = EthToUsd.fromJson(jsonDecode(res.body));
    var gasPrice = await ethClient.estimateGas(
        value: EtherAmount.fromUnitAndValue(EtherUnit.ether, balance));
    var amount = balance.toInt() -
        gasPrice.toInt() / ethToUsd.etherum['usd'] * 1000000000000000000;
    print("Ammount $amount");
    var hash = await ethClient.sendTransaction(
        credentials,
        Transaction(
            to: EthereumAddress.fromHex(addrController.text),
            maxGas: 100000,
            value: EtherAmount.fromUnitAndValue(
                EtherUnit.wei, amount.toString())));
    print(hash);
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return new WebviewScaffold(
        url: "https://etherscan.io/tx/$hash",
        appBar: AppBar(
          actions: [],
        ),
      );
    }));
  }

  sendTx() async {
    var apiUrl =
        "https://mainnet.infura.io/v3/b63606f0825343fd85b553d6e471a53b"; //Replace with your API
    var httpClient = new Client();
    var ethClient = new Web3Client(apiUrl, httpClient);
    var box = await Hive.openBox('myBox');
    String content = box.get('wallet');
    Wallet wallet = Wallet.fromJson(content, 'password');
    Credentials credentials = wallet.privateKey;
    var cli = Client();
    var res = await cli.get(
        'https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd');
    print(res.body);
    var ethToUsd = EthToUsd.fromJson(jsonDecode(res.body));
    var amount = double.parse(ammountController.text) /
        ethToUsd.etherum['usd'] *
        1000000000000000000;
    print("Ammount $amount");
    var hash = await ethClient.sendTransaction(
        credentials,
        Transaction(
            to: EthereumAddress.fromHex(addrController.text),
            maxGas: 100000,
            value:
                EtherAmount.fromUnitAndValue(EtherUnit.wei, amount.toInt())));
    print(hash);
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return new WebviewScaffold(
        url: "https://etherscan.io/tx/$hash",
        appBar: AppBar(
          actions: [],
        ),
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        backgroundColor: Color(0xff374ABE),
        onPressed: () async {
          String qrResult = await MajaScan.startScan(
              barColor: Colors.black,
              titleColor: Colors.white,
              qRCornerColor: Colors.blue,
              qRScannerColor: Colors.deepPurple,
              flashlightEnable: true,
              scanAreaScale: 0.7);
          setState(() {
            addrController.text = qrResult;
          });
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'Send',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: addrController,
                      decoration: InputDecoration(
                          labelText: 'Recipient address',
                          border: OutlineInputBorder()),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: ammountController,
                      decoration: InputDecoration(
                          labelText: 'Amount of USD',
                          border: OutlineInputBorder()),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 50.0,
                      width: 100,
                      child: RaisedButton(
                        onPressed: () {
                          sendTx();
                        },
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(80.0)),
                        padding: EdgeInsets.all(0.0),
                        child: Ink(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xff374ABE), Color(0xff64B6FF)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(30.0)),
                          child: Container(
                            constraints: BoxConstraints(
                                maxWidth: 300.0, minHeight: 50.0),
                            alignment: Alignment.center,
                            child: Text(
                              "Send",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  FlatButton(
                      onPressed: () {
                        _showCupertinoDialog();
                      },
                      child: Text('Send All'))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class EthToUsd {
  final Map<String, dynamic> etherum;

  EthToUsd({this.etherum});
  factory EthToUsd.fromJson(Map<String, dynamic> json) {
    return EthToUsd(etherum: json['ethereum']);
  }
}
