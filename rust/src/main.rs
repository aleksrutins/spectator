use rust_lib_spectator::api::net::scan_hosts;

fn main() {
    let hosts = scan_hosts();

    println!("{}", serde_json::to_string(&hosts).unwrap());
}