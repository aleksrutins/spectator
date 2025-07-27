import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:ping_discover_network_forked/ping_discover_network_forked.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _Device {
  String name;
  String ip;
  String manufacturer;
  _Device({required this.name, required this.ip, required this.manufacturer});
}

class _ScanPageState extends State<ScanPage> {
  List<_Device> _devices = [];
  bool _scanning = false;

  void scanNetwork() async {
    setState(() {
      _scanning = true;
      _devices.clear(); // Clear previous results
    });

    // Get IP on main thread first
    final String ip = (await NetworkInfo().getWifiIP())!;
    final String subnet = ip.substring(0, ip.lastIndexOf('.'));
    final int port = 80;

    final rp = ReceivePort();
    rp.listen((message) {
      setState(() {
        if (message == "done") {
          _scanning = false;
          rp.close();
          return;
        }
        _devices.add(
          _Device(name: message, ip: message, manufacturer: "Unknown"),
        );
      });
    });

    // Pass subnet to isolate instead of getting IP inside isolate
    Isolate.spawn((Map<String, dynamic> args) async {
      final SendPort send = args['sendPort'];
      final String subnet = args['subnet'];
      final int port = args['port'];

      print("scanning subnet: $subnet");

      final stream = NetworkAnalyzer.discover2(subnet, port);

      await for (NetworkAddress addr in stream) {
        if (addr.exists) {
          print(addr.ip);
          send.send(addr.ip);
        }
      }

      send.send("done");
    }, {'sendPort': rp.sendPort, 'subnet': subnet, 'port': port});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 6,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Network Scan",
          style: FTheme.of(
            context,
          ).typography.lg.copyWith(fontWeight: FontWeight.bold),
        ),
        FButton(
          prefix: _scanning ? const FProgress.circularIcon() : null,
          onPress: _scanning
              ? null
              : () {
                  scanNetwork();
                },
          child: Text("Scan"),
        ),
        DataTable(
          columns: const [
            DataColumn(label: Text("Name")),
            DataColumn(label: Text("IP")),
            DataColumn(label: Text("Manufacturer")),
          ],
          rows: _devices
              .map(
                (device) => DataRow(
                  cells: [
                    DataCell(Text(device.name)),
                    DataCell(Text(device.ip)),
                    DataCell(Text(device.manufacturer)),
                  ],
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
