build:
    fvm flutter build linux

bundle arch="x64": build
    mkdir -p bundle-out/
    cp -r build/linux/{{arch}}/release/bundle/* bundle-out/
    cp rust/target/release/scan-hosts bundle-out/
    zip -r spectator.zip bundle-out/*