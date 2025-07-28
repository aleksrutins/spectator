use std::{collections::HashMap, env, net::IpAddr, os, process::Command, thread, time::Duration};

use ipnet::Ipv4Net;
use netscan::{
    host::Host,
    scan::{scanner::HostScanner, setting::HostScanSetting},
};

pub fn scan_hosts() -> HashMap<String, String> {
    let iface = netdev::get_default_interface().unwrap();
    let mut scan_setting = HostScanSetting::default()
        .set_if_index(iface.index)
        .set_scan_type(netscan::scan::setting::HostScanType::IcmpPingScan)
        .set_async_scan(false)
        .set_timeout(Duration::from_secs(2))
        .set_wait_time(Duration::from_millis(500));

    let src_ip = iface.ipv4[0].addr();
    let net = Ipv4Net::new(src_ip, 24).unwrap();
    let nw_addr = Ipv4Net::new(net.network(), 24).unwrap();
    let hosts = nw_addr.hosts();

    for host in hosts {
        let dst = Host::new(IpAddr::V4(host), String::new());
        scan_setting.add_target(dst);
    }

    let scanner = HostScanner::new(scan_setting);
    let _rx = scanner.get_progress_receiver();

    let result = scanner.scan();

    result.hosts.iter().map(|h| (h.ip_addr.to_string(), h.hostname.clone())).collect()
}

pub fn scan_hosts_elevate() -> HashMap<String, String> {
    let bin_path = env::var("SCAN_HOSTS_PATH").unwrap_or_else(|_| "scan-hosts".to_string());

    let run = Command::new("pkexec").args(&["--disable-internal-agent", &bin_path]).output().unwrap();
    println!("{}",str::from_utf8(&run.stdout).unwrap());

    serde_json::from_str(str::from_utf8(&run.stdout).unwrap()).unwrap()
}