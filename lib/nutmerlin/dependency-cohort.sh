#!/bin/sh

# This file is sourced by the release-matched dependency planner.
# shellcheck disable=SC2034

# Release-matched package metadata from the supported Entware AArch64 feed.
# The index digest makes a changed feed a new qualification input rather than
# silently broadening this planner's dependency set.
dependency_catalog_schema=nutmerlin.entware-cohort.v1
dependency_catalog_feed_name=entware
dependency_catalog_feed_url=https://bin.entware.net/aarch64-k3.10
dependency_catalog_configured_feed_url=http://bin.entware.net/aarch64-k3.10
dependency_catalog_feed_architecture=aarch64-3.10
dependency_catalog_index_bytes=1659256
dependency_catalog_index_sha256=b1f04218d93d967d79fdf8d58badd759c3fd44dda4edeb2d68670f9fbbff1283
dependency_catalog_index_last_modified=2026-06-27T18:00:59Z
dependency_catalog_nut_version=2.8.4-1
dependency_catalog_gpgv2_version=2.4.8-1
dependency_catalog_gpgv2_installed_bytes=522240
dependency_catalog_gpgv2_archive_bytes=247842
dependency_catalog_gpgv2_filename=gpgv2_2.4.8-1_aarch64-3.10.ipk
dependency_catalog_gpgv2_sha256=2df7a6554da8a7704bee6ec586aa4a5e1696e49e0663fb312d806bb0534be906
dependency_compatibility_metadata=nutmerlin.nut-compatibility.v1

dependency_catalog_packages() {
	cat <<'EOF'
core|libatomic|8.4.0-12|40960|10747|2a3ab50ae1173bc85d16fe17cfff87f3e983f87beecb11a13c15775d9e9bedb4
core|libc|2.27-12|2867200|1367072|4d7825a9ddf7a382a985a44ec85c4ab458f8ebe12c3e3b5fb25da814f71167bb
core|libexpat|2.7.4-1|153600|58455|f16fe4687701eb11ce1beb45de3926fda1869bf1a1a68d8644875e6238c9609a
core|libgcc|8.4.0-12|81920|36583|123882cd0063342b8cd058ea97541601d793ef1f847920e1da6be4c3a0b8da8b
core|libneon|0.32.4-1|194560|77630|f50996670ed8cdb8e5998ab7c0456e7403a40259a5351463fa8677a5281faeb2
core|libnetsnmp-ssl|5.9.4-6|1402880|544823|dab386d8a6afd380bea9dd6bdc9607bdde7b4a7dc9e6842f22c0fcbc1dff724a
core|libnl|3.11.0-1|10240|800|6c82eaab9f18692029c501676d511ba9ba6bb822c1a4a5eef3a54c35ff6472aa
core|libnl-cli|3.11.0-1|51200|14404|c49458b804340ec5f1798003e67972e9c2b00180fa28314bbd4f0ea99d8daea8
core|libnl-core|3.11.0-1|133120|50539|a7c2cbe6108d32d4b8ea5d00a00df4f54e7625fcadea3f18dd89d99e2c3ffde9
core|libnl-genl|3.11.0-1|40960|10147|00f2f9ff66aa98eb22a7ec96fd1bc5001cfabc2655936680ce2ad690414974c6
core|libnl-nf|3.11.0-1|112640|34380|94096334fd554b838b1eb9205024b3063745a4aa5c0c2a4c519b65c66f0613cc
core|libnl-route|3.11.0-1|634880|206772|a6a33b26503434a9d854e25e8cc700b69ac07f319f5871c99f22bcae2e97042d
core|libopenssl|3.5.5-1|6686720|2471054|d1b3738612336121d5510eb5f212f1154e30db1653be827bc09721a53ac2d260
core|libpci|3.14.0-1|81920|33587|e52b5d2c9b0ce4f95774f5803e48a7be6d18dd871f856bd9c3d44180dbc41cc4
core|libpcre2|10.47-1|624640|250186|177e0ac6a084c81a2731e99b0c386989752482a52068f16f3024eb67db3f6e92
core|libpthread|2.27-12|112640|44699|a2af364e6e139069f8b37dd9e7f2accaf529efd35738c6d381d2e43e78b876d4
core|librt|2.27-12|40960|13307|86d4adc05b939793f4fb7d54ecc6c34b867a1fe9c449983393f708f245b72b43
core|libssp|8.4.0-12|20480|4092|8d85e466962569005ec604a64b2ffa739454a9db017a9a5e8dbe23b3c4bf2c25
core|libusb-1.0|1.0.29-1|102400|42058|01293d0054b60a94cbc898e2b16537b90063d4800d275b340c3b988a335e1c56
core|libusb-compat|0.1.8-1|30720|8637|c8143f17c3fa73b477e9c34a3fe107b293eaa412d36e1dff9cac3ce010837e1c
core|nut|2.8.4-1|10240|872|ac7bd1b1605e85ffc27befb469da88ea23e2b53841d2170ec38e2db197b8ed53
core|nut-common|2.8.4-1|112640|41672|d050e259deb5ebed79c513b090bd6bfdeaea819cdab015bd5a82535fdd4f0a61
core|nut-driver-dummy-ups|2.8.4-1|163840|66348|d672afa22226dea2c07657f1a385935207f43051dc0608c5c0d910e9575dc5c9
core|nut-driver-usbhid-ups|2.8.4-1|389120|128521|ded43f862baa60c8d36d0b2f51efc1207a5805e5ef695bf3b584e4ed1eca78de
core|nut-server|2.8.4-1|399360|130311|6d38103670339bf3c00afced08ebc6faa1e4ab7d085611f6c070327532f44229
core|nut-upsc|2.8.4-1|71680|27355|48d34e3f4f5c0cd3bf3b2915d8bba38b3fac19dd7d883eb23ef69f33558b8300
core|zlib|1.3.1-1|92160|43197|30470ce83557e2438cac7a0a874a1fb7e50570c4a7cbbe3f2ac1b4a2d1efb372
ssh|openssh-client|10.2_p1-1|1249280|544905|6b0ae326316a1e056c85822a20458d8c7367064dde0fa5723f76c89be4904ed0
ssh|openssh-client-utils|10.2_p1-1|1986560|840950|a1fd340609d6bac26463a096c98e5b9b0267f480429d0cc645812a4fe036392e
ssh|openssh-keygen|10.2_p1-1|583680|240540|bc4492f7678a8ca1abf4397ba58707399ca1e36c2b64cfe095c8870cf15ee878
EOF
}

dependency_catalog_package_relationships() {
	cat <<'EOF'
libatomic|libgcc|libatomic-any
libc|libgcc|libc-any
libexpat|libc, libssp, librt, libpthread|libexpat-any
libgcc||libgcc-any
libneon|libc, libssp, librt, libpthread, libopenssl, libexpat, zlib|libneon-any
libnetsnmp-ssl|libc, libssp, librt, libpthread, libnl, libpci, libpcre2, libopenssl|libnetsnmp-ssl-any, libnetsnmp
libnl|libc, libssp, librt, libpthread, libnl-genl, libnl-route, libnl-nf, libnl-cli|libnl-any
libnl-cli|libc, libssp, librt, libpthread, libnl-genl, libnl-nf|libnl-cli-any
libnl-core|libc, libssp, librt, libpthread, libpthread|libnl-core-any
libnl-genl|libc, libssp, librt, libpthread, libnl-core|libnl-genl-any
libnl-nf|libc, libssp, librt, libpthread, libnl-route|libnl-nf-any
libnl-route|libc, libssp, librt, libpthread, libnl-core|libnl-route-any
libopenssl|libc, libssp, librt, libpthread, zlib|libopenssl-any
libpci|libc, libssp, librt, libpthread|libpci-any
libpcre2|libc, libssp, librt, libpthread|libpcre2-any
libpthread|libgcc|libpthread-any
librt|libpthread|librt-any
libssp||libssp-any
libusb-1.0|libc, libssp, librt, libpthread, libpthread, librt, libatomic|libusb-1.0-any
libusb-compat|libc, libssp, librt, libpthread, libusb-1.0|libusb-compat-any
nut|libc, libssp, librt, libpthread|nut-any
nut-common|libc, libssp, librt, libpthread, nut, libnetsnmp, libusb-compat, libneon, libopenssl|nut-common-any
nut-driver-dummy-ups|libc, libssp, librt, libpthread, nut, nut-server|nut-driver-dummy-ups-any
nut-driver-usbhid-ups|libc, libssp, librt, libpthread, nut, nut-server|nut-driver-usbhid-ups-any
nut-server|libc, libssp, librt, libpthread, nut, nut-common|nut-server-any
nut-upsc|libc, libssp, librt, libpthread, nut, nut-common|nut-upsc-any
zlib|libc, libssp, librt, libpthread|zlib-any
openssh-client|libc, libssp, librt, libpthread, libopenssl, zlib|openssh-client-any
openssh-client-utils|libc, libssp, librt, libpthread, libopenssl, zlib, openssh-client, openssh-keygen|openssh-client-utils-any
openssh-keygen|libc, libssp, librt, libpthread, libopenssl, zlib|openssh-keygen-any
EOF
}

dependency_catalog_nut_roots() {
	printf '%s\n' nut nut-common nut-server nut-upsc nut-driver-usbhid-ups nut-driver-dummy-ups
}

dependency_catalog_ssh_roots() {
	printf '%s\n' openssh-client openssh-client-utils openssh-keygen
}

dependency_is_nut_cohort_package() {
	dependency_catalog_wanted_root=$1
	while IFS= read -r dependency_catalog_root; do
		[ "$dependency_catalog_root" != "$dependency_catalog_wanted_root" ] || return 0
	done <<EOF
$(dependency_catalog_nut_roots)
EOF
	return 1
}

dependency_catalog_binary_records() {
	cat <<'EOF'
nut-server|/opt/sbin/upsd|-V|-h|-F|-u||NUT_CONFPATH
nut-server|/opt/sbin/upsdrvctl|-V|-h|-t|-F|-u|NUT_CONFPATH
nut-upsc|/opt/bin/upsc|-V|-h||||
nut-driver-usbhid-ups|/opt/lib/nut/usbhid-ups|-V|-h|-a|-u|-D|NUT_CONFPATH
nut-driver-dummy-ups|/opt/lib/nut/dummy-ups|-V|-h|-a|-u|-D|NUT_CONFPATH
EOF
}

dependency_catalog_join_options() {
	dependency_catalog_joined_options=
	for dependency_catalog_option in "$@"; do
		[ -n "$dependency_catalog_option" ] || continue
		if [ -n "$dependency_catalog_joined_options" ]; then
			dependency_catalog_joined_options=$dependency_catalog_joined_options,$dependency_catalog_option
		else
			dependency_catalog_joined_options=$dependency_catalog_option
		fi
	done
	printf '%s' "$dependency_catalog_joined_options"
}

dependency_catalog_required_binaries_json() {
	dependency_catalog_binary_json=
	while IFS='|' read -r dependency_catalog_binary_package dependency_catalog_binary_path dependency_catalog_binary_option_1 dependency_catalog_binary_option_2 dependency_catalog_binary_option_3 dependency_catalog_binary_option_4 dependency_catalog_binary_option_5 dependency_catalog_binary_contract; do
		dependency_catalog_binary_options=$(dependency_catalog_join_options \
			"$dependency_catalog_binary_option_1" "$dependency_catalog_binary_option_2" "$dependency_catalog_binary_option_3" \
			"$dependency_catalog_binary_option_4" "$dependency_catalog_binary_option_5")
		dependency_catalog_binary_item="{\"package\":\"$dependency_catalog_binary_package\",\"path\":\"$dependency_catalog_binary_path\",\"required_options\":\"$dependency_catalog_binary_options\",\"environment_contract\":\"$dependency_catalog_binary_contract\"}"
		if [ -n "$dependency_catalog_binary_json" ]; then
			dependency_catalog_binary_json=$dependency_catalog_binary_json,$dependency_catalog_binary_item
		else
			dependency_catalog_binary_json=$dependency_catalog_binary_item
		fi
	done <<EOF
$(dependency_catalog_binary_records)
EOF
	printf '%s' "$dependency_catalog_binary_json"
}

dependency_catalog_package_relationships_json() {
	dependency_catalog_package_relationship_json=
	while IFS='|' read -r dependency_catalog_relationship_package dependency_catalog_relationship_depends dependency_catalog_relationship_provides; do
		dependency_catalog_package_relationship_item="{\"package\":\"$dependency_catalog_relationship_package\",\"depends\":\"$dependency_catalog_relationship_depends\",\"provides\":\"$dependency_catalog_relationship_provides\"}"
		if [ -n "$dependency_catalog_package_relationship_json" ]; then
			dependency_catalog_package_relationship_json=$dependency_catalog_package_relationship_json,$dependency_catalog_package_relationship_item
		else
			dependency_catalog_package_relationship_json=$dependency_catalog_package_relationship_item
		fi
	done <<EOF
$(dependency_catalog_package_relationships)
EOF
	printf '%s' "$dependency_catalog_package_relationship_json"
}

dependency_catalog_root_array_json() {
	dependency_catalog_root_json=
	while IFS= read -r dependency_catalog_root; do
		if [ -n "$dependency_catalog_root_json" ]; then
			dependency_catalog_root_json=$dependency_catalog_root_json,\"$dependency_catalog_root\"
		else
			dependency_catalog_root_json=\"$dependency_catalog_root\"
		fi
	done
	printf '%s' "$dependency_catalog_root_json"
}

dependency_catalog_relationships_json() {
	dependency_catalog_required_roots=$(dependency_catalog_nut_roots | dependency_catalog_root_array_json)
	dependency_catalog_optional_ssh_roots=$(dependency_catalog_ssh_roots | dependency_catalog_root_array_json)
	dependency_catalog_package_relationship_records=$(dependency_catalog_package_relationships_json)
	printf '%s' "\"required_roots\":[$dependency_catalog_required_roots],\"optional_roots\":{\"ssh\":[$dependency_catalog_optional_ssh_roots]},\"virtual_providers\":{\"libnetsnmp\":\"libnetsnmp-ssl\"},\"package_relationships\":[$dependency_catalog_package_relationship_records]"
}
