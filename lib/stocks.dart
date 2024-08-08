import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class Stocks extends StatefulWidget {
  const Stocks({super.key, required this.title});

  final String title;

  @override
  State<Stocks> createState() => _StocksState();
}

class _StocksState extends State<Stocks> {
  late WebSocketChannel channel;
  final ValueNotifier<String> lastPrice = ValueNotifier<String>('');
  final Box box = Hive.box('stockPricesBox');

  @override
  void initState() {
    super.initState();
    _loadLastPrice();
    channel = WebSocketChannel.connect(
      Uri.parse('wss://ws.eodhistoricaldata.com/ws/us?api_token=demo'),
    );

    // we can also use provider and keep the logic and ui in different files but right now, keeping it in a single file
    channel.stream.listen((data) {
      final decodedData = jsonDecode(data);
      if (decodedData.containsKey('p')) {
        lastPrice.value = decodedData['p'].toString();
        _saveLastPrice(lastPrice.value);
      }
    }, onError: (error) {
      print('WebSocket Error: $error');
    });
  }

  // Load the last price
  Future<void> _loadLastPrice() async {
    lastPrice.value = box.get('lastPrice', defaultValue: 'No data') as String;
  }

  // Save the last price
  Future<void> _saveLastPrice(String price) async {
    await box.put('lastPrice', price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(widget.title),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: lastPrice,
        builder: (context, value, child) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tesla stocks",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text('Price : $value',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _getLiveData,
        label: const Text('Get Live Data'),
      ),
    );
  }

  void _getLiveData() {
    final message = jsonEncode({"action": "subscribe", "symbols": "TSLA"});
    channel.sink.add(message);
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }
}
