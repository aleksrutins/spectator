import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:ping_discover_network_forked/ping_discover_network_forked.dart';
import 'package:spectator/src/rust/api/net.dart';
import 'package:spectator/src/rust/frb_generated.dart';

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
  final List<_Device> _devices = [];
  bool _scanning = false;

  void scanNetwork() async {
    setState(() {
      _scanning = true;
      _devices.clear(); // Clear previous results
    });

    final hosts = await scanHosts();

    setState(() {
      _devices.addAll(
        hosts.entries.map(
          (e) => _Device(name: e.value, ip: e.key, manufacturer: "Unknown"),
        ),
      );
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
