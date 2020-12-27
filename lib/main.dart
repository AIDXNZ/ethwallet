import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ethwallet/send.dart';
import 'package:ethwallet/setting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beautiful_popup/main.dart';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:majascan/majascan.dart';
import 'package:share/share.dart';
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
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:wallet_core/wallet_core.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

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
            backgroundColor: Colors.white,
            body: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF834d9b), Color(0xFFd04ed6)])),
              child: SafeArea(
                child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Eth Wallet',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 48,
                              color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          height: 50.0,
                          width: 200,
                          child: RaisedButton(
                            onPressed: () {
                              genWallet();
                            },
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(80.0)),
                            padding: EdgeInsets.all(0.0),
                            child: Ink(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30.0)),
                              child: Container(
                                constraints: BoxConstraints(
                                    maxWidth: 300.0, minHeight: 50.0),
                                alignment: Alignment.center,
                                child: Text(
                                  "Generate Wallet",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black),
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
                          width: 200,
                          child: RaisedButton(
                            onPressed: () async {
                              String qrResult = await MajaScan.startScan(
                                  barColor: Colors.black,
                                  titleColor: Colors.white,
                                  qRCornerColor: Colors.blue,
                                  qRScannerColor: Colors.deepPurple,
                                  flashlightEnable: true,
                                  scanAreaScale: 0.7);
                              genWalletFromJson(qrResult);
                            },
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(80.0)),
                            padding: EdgeInsets.all(0.0),
                            child: Ink(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30.0)),
                              child: Container(
                                constraints: BoxConstraints(
                                    maxWidth: 300.0, minHeight: 50.0),
                                alignment: Alignment.center,
                                child: Text(
                                  "Login",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black),
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
                          width: 200,
                          child: RaisedButton(
                            onPressed: () async {
                              var box = await Hive.openBox('myBox');
                              TextEditingController controller =
                                  TextEditingController();
                              final popup = BeautifulPopup(
                                context: context,
                                template: TemplateAuthentication,
                              );
                              popup.show(
                                title: 'Enter Wallet Json',
                                content: TextField(
                                  controller: controller,
                                ),
                                actions: [
                                  popup.button(
                                    label: 'Close',
                                    onPressed: () async {
                                      var box = await Hive.openBox('myBox');
                                      box.put('wallet', controller.text);
                                    },
                                  ),
                                ],
                                // bool barrierDismissible = false,
                                // Widget close,
                              );
                            },
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(80.0)),
                            padding: EdgeInsets.all(0.0),
                            child: Ink(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30.0)),
                              child: Container(
                                constraints: BoxConstraints(
                                    maxWidth: 300.0, minHeight: 50.0),
                                alignment: Alignment.center,
                                child: Text(
                                  "Enter Wallet Json",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ])),
              ),
            ),
          );
        });
  }

  void genWalletFromJson(String data) async {
    var box = await Hive.openBox('myBox');
    var wallet = Wallet.fromJson(data, "password");
    box.put('wallet', wallet.toJson());
  }
}

class HomeScreen extends StatefulWidget {
  HomeScreen({Key key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String bal = '0.0';
  String ethPrice = '0.0';
  String totalEthereum = '0.0';
  String tokenBalance = '0.0';
  String numOfTx = '';

  String recentTx = '';
  @override
  void initState() {
    super.initState();
    loadBalance();
    loadAddr();
  }

  Future<bool> approvalCallback() async {
    return true;
  }

  mint() async {
    var box = await Hive.openBox('myBox');
    String content = box.get('wallet');
    Wallet wallet = Wallet.fromJson(content, 'password');
    Credentials credentials = wallet.privateKey;
    var addr = await credentials.extractAddress();
    var contractAddr = '0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5';
    var apiUrl =
        "https://mainnet.infura.io/v3/b63606f0825343fd85b553d6e471a53b";
    var httpClient = new Client();
    var ethClient = new Web3Client(apiUrl, httpClient);
    final abiCode = await rootBundle.loadString("assets/abi.json");
    final contract = DeployedContract(ContractAbi.fromJson(abiCode, 'Compound'),
        EthereumAddress.fromHex(contractAddr));
    var mintFunction = contract.function('mint');
    var hash = await ethClient.sendTransaction(
        credentials,
        Transaction.callContract(
            contract: contract, function: mintFunction, parameters: []));
    // var hash2 = await ethClient.sendTransaction(
    //     credentials,
    //     Transaction(
    //         to: contract.address,
    //         from: addr,
    //         value: EtherAmount.fromUnitAndValue(EtherUnit.wei, 10000000)));
    print(hash);
    //print(hash2);
  }

  callContract() async {
    var box = await Hive.openBox('myBox');
    String content = box.get('wallet');
    Wallet wallet = Wallet.fromJson(content, 'password');
    Credentials credentials = wallet.privateKey;
    var addr = await credentials.extractAddress();
    var contractAddr = '0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5';
    var apiUrl =
        "https://mainnet.infura.io/v3/b63606f0825343fd85b553d6e471a53b";
    var httpClient = new Client();
    var ethClient = new Web3Client(apiUrl, httpClient);
    final abiCode = await rootBundle.loadString("assets/abi.json");
    final contract = DeployedContract(ContractAbi.fromJson(abiCode, 'Compound'),
        EthereumAddress.fromHex(contractAddr));

    final balanceFunction = contract.function('balanceOf');

    // check our balance in MetaCoins by calling the appropriate function
    final balance = await ethClient
        .call(contract: contract, function: balanceFunction, params: [addr]);
    if (balance.isEmpty) {
      print("0.0 CToken");
    } else if (balance.isNotEmpty) {
      setState(() {
        tokenBalance = balance.first.toString();
      });
      print('We have ${balance.first} CTokens');
    }
  }

  loadTokenBalance() async {
    loadBalance();
    callContract();
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
    double total = ethToUsd.etherum['usd'] * eth;
    print("Total: $total");
    print('Wei ${EtherAmount.inWei(BigInt.from(eth))}');

    setState(() {
      bal = (total.toString().length > 3)
          ? total.toString().substring(0, 4)
          : "0.0";
      ethPrice = ethToUsd.etherum['usd'].toString();
      totalEthereum = eth.toString();
    });
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

  loadAddr() async {
    var box = await Hive.openBox('myBox');
    var wallet = Wallet.fromJson(box.get('wallet'), 'password');
    var addr = await wallet.privateKey.extractAddress();
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

  //Pull to refresh
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {
    // monitor network fetch
    // if failed,use refreshFailed()
    loadBalance();
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    // monitor network fetch
    // if failed,use loadFailed(),if no data return,use LoadNodata()
    loadBalance();
    setState(() {});
    _refreshController.loadComplete();
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
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return SettingsPage();
              }));
            },
            child: Icon(Icons.settings),
          ),
          backgroundColor: box.get('darkMode') ? Colors.black : Colors.white,
          body: Center(
              child: Stack(
            children: [
              SafeArea(
                child: SmartRefresher(
                  enablePullDown: true,
                  header: WaterDropHeader(
                    waterDropColor: Colors.black,
                  ),
                  controller: _refreshController,
                  onRefresh: _onRefresh,
                  onLoading: _onLoading,
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Color(0xFF834d9b),
                                  Color(0xFFd04ed6)
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                  Text(tokenBalance),
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
                                      borderRadius:
                                          BorderRadius.circular(30.0)),
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
                                onPressed: () async {
                                  var box = await Hive.openBox('myBox');
                                  final popup = BeautifulPopup(
                                      context: context, template: TemplateCoin);
                                  popup.show(
                                    title: 'Your Address',
                                    content: Center(
                                      child: QrImage(
                                        data: box.get('addr'),
                                      ),
                                    ),
                                    actions: [
                                      popup.button(
                                        label: 'Share',
                                        onPressed: () {
                                          Share.share(box.get('addr'));
                                        },
                                      ),
                                      popup.button(
                                        label: 'Close',
                                        onPressed: Navigator.of(context).pop,
                                      ),
                                    ],
                                    // bool barrierDismissible = false,
                                    // Widget close,
                                  );
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
                                      borderRadius:
                                          BorderRadius.circular(30.0)),
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
                                    fontSize: 18,
                                    color: box.get('darkMode')
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            ),
                            Text(
                              totalEthereum,
                              style: TextStyle(
                                  fontSize: 18,
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
                                    fontSize: 18,
                                    color: box.get('darkMode')
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            ),
                            Icon(Icons.attach_money),
                            Text(
                              ethPrice,
                              style: TextStyle(
                                  fontSize: 18,
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
                      SizedBox(
                        height: 200,
                      )
                    ],
                  ),
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
                      [Color(0xFF834d9b), Color(0xFFd04ed6)]
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
                    50,
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
    String content = box.get('wallet');
    Wallet wallet = Wallet.fromJson(content, 'password');
    Credentials credentials = wallet.privateKey;
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

class Dapp extends StatelessWidget {
  final String name;
  final String description;

  const Dapp({Key key, this.name, this.description}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 300,
          width: 300,
          decoration: BoxDecoration(color: Colors.black, boxShadow: [
            BoxShadow(blurRadius: 10, color: Colors.black, spreadRadius: 20)
          ]),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$name",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                  ),
                ),
                Text(
                  "$description",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
