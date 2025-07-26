import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:ping_discover_network_forked/ping_discover_network_forked.dart';
import 'package:worker_manager/worker_manager.dart';

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
    });
    final rootIsolateToken = RootIsolateToken.instance!;
    await workerManager.executeWithPort<void, String>(
      onMessage: (String ip) {
        setState(() {
          _devices.add(_Device(name: ip, ip: ip, manufacturer: "Unknown"));
        });
      },
      (SendPort send) async {
        BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
        final String ip = (await NetworkInfo().getWifiIP())!;
        final String subnet = ip.substring(0, ip.lastIndexOf('.'));
        final int port = 80;

        final stream = NetworkAnalyzer.discover2(subnet, port);
        stream.listen((NetworkAddress addr) {
          if (addr.exists) {
            print(addr.ip);
            send.send(addr.ip);
          }
        });
      },
    );
    setState(() {
      _scanning = false;
    });
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
