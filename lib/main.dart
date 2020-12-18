import 'dart:convert';
import 'dart:io';

import 'package:ethwallet/send.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:wave/config.dart';
import 'package:web3dart/web3dart.dart';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as stellar;
import 'package:qr_flutter/qr_flutter.dart';
import 'qr.dart';
import 'package:wave/wave.dart';
import 'package:path/path.dart' show join, dirname;

final File abiFile = File('lib/abi.json');

Future<void> main() async {
  await Hive.initFlutter();
  await Hive.openBox('myBox');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: Hive.box('myBox').listenable(),
        builder: (context, box, widget) {
          if (box.get('wallet') == null) {
            return WelcomeScreen();
          } else {
            return HomeScreen();
          }
        });
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key key}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  genWallet() async {
    var rng = new Random.secure();
    Credentials credentials = EthPrivateKey.createRandom(rng);
    var box = await Hive.openBox('myBox');
    var addr = await credentials.extractAddress();
    Wallet wallet = Wallet.createNew(credentials, 'password', rng);
    print(wallet.toJson());
    print("Address: ${addr.hex}");
    box.put('addr', addr.hex);
    box.put('wallet', wallet.toJson());
  }

  loadDefault() async {
    var box = await Hive.openBox('myBox');
    box.put('darkMode', false);
  }

  @override
  void initState() {
    super.initState();
    loadDefault();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: Hive.box('myBox').listenable(),
        builder: (context, box, widget) {
          return Scaffold(
            backgroundColor: box.get('darkMode') ? Colors.black : Colors.white,
            body: SafeArea(
              child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Saturn Wallet',
                        style: TextStyle(
                            fontSize: 48,
                            color: box.get('darkMode')
                                ? Colors.white
                                : Colors.black),
                      ),
                    ),
                    FlatButton(
                      color: Colors.blue,
                      child: Text(
                        'Generate Wallet',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        genWallet();
                      },
                    ),
                    ValueListenableBuilder(
                        valueListenable: Hive.box('myBox').listenable(),
                        builder: (context, box, widget) {
                          return Switch(
                              value: box.get('darkMode', defaultValue: false),
                              onChanged: (val) {
                                box.put('darkMode', val);
                              });
                        })
                  ])),
            ),
          );
        });
  }
}

class HomeScreen extends StatefulWidget {
  HomeScreen({Key key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String bal = '';
  String ethPrice = '';
  String totalEthereum = '';

  String numOfTx = '';

  String recentTx = '';
  @override
  void initState() {
    super.initState();
    loadBalance();
  }

  loadBalance() async {
    var box = await Hive.openBox('myBox');
    String content = box.get('wallet');
    Wallet wallet = Wallet.fromJson(content, 'password');
    Credentials credentials = wallet.privateKey;
    var eth = await getBalance(credentials);
    var cli = Client();
    var res = await cli.get(
        'https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd');
    print(res.body);
    var ethToUsd = EthToUsd.fromJson(jsonDecode(res.body));
    print(ethToUsd.etherum['usd']);
    var total = ethToUsd.etherum['usd'] * eth;
    print("Total: $total");
    setState(() {
      bal = total.toString().substring(0, 4);
      ethPrice = ethToUsd.etherum['usd'].toString();
      totalEthereum = eth.toString();
    });
    getNumOfTx(credentials);
  }

  getNumOfTx(Credentials creds) async {
    var apiUrl =
        "https://mainnet.infura.io/v3/b63606f0825343fd85b553d6e471a53b"; //Replace with your API

    var httpClient = new Client();
    var ethClient = new Web3Client(apiUrl, httpClient);
    var addr = await creds.extractAddress();
    var count = await ethClient.getTransactionCount(addr);
    setState(() {
      numOfTx = count.toString();
    });
  }

  genWallet() async {
    var rng = new Random.secure();
    Credentials pk = EthPrivateKey.createRandom(rng);
    var box = await Hive.openBox('myBox');
    var addr = await pk.extractAddress();
    box.put('pk', pk.toString());
    box.put('addr', addr.hex);

    print(addr);
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

  sendTrans() async {
    var apiUrl =
        "https://mainnet.infura.io/v3/b63606f0825343fd85b553d6e471a53b"; //Replace with your API
    var contractAddress = '0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5';
    final abiCode = await rootBundle.loadString("assets/abi.json");
    final contract = DeployedContract(ContractAbi.fromJson(abiCode, 'Compound'),
        EthereumAddress.fromHex(contractAddress));
    var httpClient = new Client();
    var ethClient = new Web3Client(apiUrl, httpClient);
    var box = await Hive.openBox('myBox');
    String content = box.get('wallet');
    Wallet wallet = Wallet.fromJson(content, 'password');
    Credentials credentials = wallet.privateKey;
    final mintFunction = contract.function('mint');
    var hash = await ethClient.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: mintFunction,
        parameters: [],
      ),
    );
    print(hash);
  }

  @override
  Widget build(BuildContext context) {
    var apiUrl =
        "https://mainnet.infura.io/v3/b63606f0825343fd85b553d6e471a53b"; //Replace with your API

    var httpClient = new Client();
    var ethClient = new Web3Client(apiUrl, httpClient);

    return ValueListenableBuilder(
      valueListenable: Hive.box('myBox').listenable(),
      builder: (context, box, widget) {
        return Scaffold(
          backgroundColor: box.get('darkMode') ? Colors.black : Colors.white,
          body: Center(
              child: Stack(
            children: [
              SafeArea(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Color(0xFFe96443),
                                Color(0xFF904e95)
                              ]),
                              boxShadow: [
                                BoxShadow(
                                    blurRadius: 10,
                                    color: Colors.black,
                                    spreadRadius: 10)
                              ]),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 150,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.attach_money,
                                        size: 48,
                                        color: Colors.white,
                                      ),
                                      Text(
                                        "$bal",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 68,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            height: 50.0,
                            width: 100,
                            child: RaisedButton(
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return FormPage();
                                }));
                              },
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(80.0)),
                              padding: EdgeInsets.all(0.0),
                              child: Ink(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xff374ABE),
                                        Color(0xff64B6FF)
                                      ],
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
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            height: 50.0,
                            width: 100,
                            child: RaisedButton(
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return QrPage(
                                    addr: box.get('addr'),
                                  );
                                }));
                              },
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(80.0)),
                              padding: EdgeInsets.all(0.0),
                              child: Ink(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.white, Colors.white],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(30.0)),
                                child: Container(
                                  constraints: BoxConstraints(
                                      maxWidth: 300.0, minHeight: 50.0),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Recieve",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    FlatButton(
                        onPressed: () {
                          loadBalance();
                        },
                        child: Text('Get balance')),
                    ValueListenableBuilder(
                        valueListenable: Hive.box('myBox').listenable(),
                        builder: (context, box, widget) {
                          return Center(
                            child: Switch(
                                value: box.get('darkMode', defaultValue: false),
                                onChanged: (val) {
                                  box.put('darkMode', val);
                                }),
                          );
                        }),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Account Balance',
                          style: TextStyle(
                              color: box.get('darkMode')
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                          child: Row(
                        children: [
                          SizedBox(
                              height: 50,
                              width: 50,
                              child: Image.asset('assets/ethwallet.png')),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Ethereum',
                              style: TextStyle(
                                  color: box.get('darkMode')
                                      ? Colors.white
                                      : Colors.black),
                            ),
                          ),
                          Text(
                            totalEthereum,
                            style: TextStyle(
                                color: box.get('darkMode')
                                    ? Colors.white
                                    : Colors.black),
                          )
                        ],
                      )),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Market Price',
                          style: TextStyle(
                              color: box.get('darkMode')
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: WaveWidget(
                  config: CustomConfig(
                    gradients: [
                      [Color(0xFFCFDEF3), Color(0xFFE0EAFC)],
                      [Color(0xFF457fca), Color(0xFF5691c8)],
                      [Color(0xFF834d9b), Color(0xFFd04ed6)],
                      [Color(0xFFe96443), Color(0xFF904e95)]
                    ],
                    durations: [35000, 19440, 10800, 6000],
                    heightPercentages: [0.20, 0.23, 0.25, 0.30],
                    blur: MaskFilter.blur(BlurStyle.solid, 10),
                    gradientBegin: Alignment.bottomLeft,
                    gradientEnd: Alignment.topRight,
                  ),
                  waveAmplitude: 0,
                  backgroundColor: Colors.transparent,
                  size: Size(
                    double.infinity,
                    100,
                  ),
                ),
              ),
            ],
          )),
        );
      },
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

class PendingTrans extends StatefulWidget {
  @override
  _PendingTransState createState() => _PendingTransState();
}

class _PendingTransState extends State<PendingTrans> {
  Future<Stream> tranStream() async {
    var apiUrl =
        "https://mainnet.infura.io/v3/b63606f0825343fd85b553d6e471a53b"; //Replace with your API

    var httpClient = new Client();
    var ethClient = new Web3Client(apiUrl, httpClient);
    var box = await Hive.openBox('myBox');
    var credentials = await ethClient.credentialsFromPrivateKey(box.get('pk'));
    var addr = await credentials.extractAddress();

    return ethClient.pendingTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder(
        stream: tranStream().asStream(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const Text('Loading...');
            default:
              if (snapshot.data.isEmpty) {
                return Text('No Pending Transactions');
              }
              return ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                return Text(snapshot.data[index]);
              });
          }
        },
      ),
    );
  }
}
