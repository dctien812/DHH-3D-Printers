#!/bin/bash
# Thu cong nap (gate.sh) voi manifest gia lap tro vao fleet/reflash/2026-11-25. Lenh nap thay bang echo.
# S: noi dat gate.sh (trong repo). G: thu muc lam viec cho file sinh ra (tests/tmp, da gitignore).
S=/mnt/d/WORK/3D-Printer-Klipper/tests/gate
G=/mnt/d/WORK/3D-Printer-Klipper/tests/tmp/gate-run
mkdir -p "$G"
B=/mnt/d/WORK/3D-Printer-Klipper/fleet/reflash/2026-11-25
export INSPECT=/mnt/d/WORK/3D-Printer-Klipper/docs-internal/tools/dump-inspect.py
cd "$G" || exit 1
# --- tao manifest giong khoi lenh trong tai lieu (chi thay $HOME/mcu-build bang $B, ~/reflash-work bang $G)
M=$G/MANIFEST; : > "$M"
for p in octopus_off0:octopus_off0 octopus_off128k:octopus_off128k ebb36_off0:ebb_off0 ebb36_off8k:ebb_off8k; do
  v=${p%%:*}; c=${p#*:}; bin=$B/${c}_klipper-0.13.0-822.bin; cfg=$B/$c.config
  addr=$(sed -n 's/^CONFIG_FLASH_APPLICATION_ADDRESS=//p' "$cfg")
  echo "$v $(sha256sum "$bin" | cut -d' ' -f1) $bin $cfg $addr" >> "$M"
done
cat "$M"; awk 'NF!=5{b=1} END{exit b || NR!=4}' "$M" && echo MANIFEST_OK
line() { awk -v v="$1" '$1==v' "$M"; }
# --- manifest bien the cho ca loi
head -c $((0x9000)) "$B/ebb_off8k_klipper-0.13.0-822.bin" > "$G/ebb_off8k_cut.bin"
mk() { cp "$M" "$G/$1"; }
mk M_cut;   sed -i "s#$B/ebb_off8k_klipper-0.13.0-822.bin#$G/ebb_off8k_cut.bin#" "$G/M_cut"
mk M_swap;  sed -i "/^ebb36_off8k /s#$B/ebb_off8k_klipper#$B/ebb_off0_klipper#" "$G/M_swap"
mk M_octbin; sed -i "/^ebb36_off0 /s#$B/ebb_off0_klipper#$B/octopus_off0_klipper#" "$G/M_octbin"
mk M_cfg;   sed -i "/^ebb36_off8k /s#$B/ebb_off8k.config#$B/ebb_off0.config#" "$G/M_cfg"
mk M_dup;   line ebb36_off8k >> "$G/M_dup"
mk M_miss;  sed -i '/^ebb36_off8k /d' "$G/M_miss"
t() { # mong_doi MANIFEST BO VARIANT OFF mo_ta
  exp=$1; export MANIFEST=$G/$2; shift 2; desc=$4
  BIN=$(bash "$S/gate.sh" "$1" "$2" "$3" 2>"$G/err.txt") && got="NAP: echo dfu-util -s $3:leave -D $BIN" || got="DUNG: $(grep '^CONG: DUNG' "$G/err.txt")"
  case "$got" in "$exp"*) r=OK;; *) r=SAI;; esac
  printf '%-3s %-58s -> %s\n' "$r" "$desc" "$got"
}
t NAP  MANIFEST ebb36   ebb36_off8k     0x08002000 "dung: EBB 8K"
t NAP  MANIFEST ebb36   ebb36_off0      0x08000000 "dung: EBB off0"
t NAP  MANIFEST octopus octopus_off128k 0x08020000 "dung: Octopus 128K"
t NAP  MANIFEST octopus octopus_off0    0x08000000 "dung: Octopus off0"
t DUNG MANIFEST ebb36   ebb36_off8k     0x08000000 "EBB dao: bien the 8K, OFF 0"
t DUNG MANIFEST ebb36   ebb36_off0      0x08002000 "EBB dao: bien the off0, OFF 8K"
t DUNG M_swap   ebb36   ebb36_off8k     0x08002000 "EBB dao file: dong 8K tro vao bin off0"
t DUNG MANIFEST ebb36   octopus_off0    0x08000000 "file Octopus o cong EBB (ten bien the)"
t DUNG M_octbin ebb36   ebb36_off0      0x08000000 "file Octopus o cong EBB (duong dan trong manifest)"
t DUNG MANIFEST octopus ebb36_off0      0x08000000 "file EBB o cong Octopus"
t DUNG M_cut    ebb36   ebb36_off8k     0x08002000 "file cat cut 0x9000 byte"
t DUNG M_cfg    ebb36   ebb36_off8k     0x08002000 ".config sai (off0) cho bien the 8K"
t DUNG M_dup    ebb36   ebb36_off8k     0x08002000 "manifest co 2 dong cung bien the"
t DUNG M_miss   ebb36   ebb36_off8k     0x08002000 "manifest thieu dong"
t DUNG MANIFEST ebb36   ""              0x08002000 "VARIANT rong"
t DUNG MANIFEST ebb36   ebb36_off8k     ""         "OFF rong"
t DUNG MANIFEST ebb36   ebb36_off8k     "0x08002000+0" "OFF dang la"
t DUNG MANIFEST octopus octopus_off128k 0x08000000 "Octopus 128K nhung OFF 0"
t DUNG NOFILE   ebb36   ebb36_off8k     0x08002000 "khong co file manifest"
t DUNG MANIFEST ebb36   ebb36_off8k     0x10000000008002000 "OFF tran 2^64+0x8002000 (EBB)"
t DUNG MANIFEST octopus octopus_off0    0x10000000008000000 "OFF tran 2^64+0x8000000 (Octopus)"
t NAP  MANIFEST ebb36   ebb36_off8k     0x8002000  "dung: OFF khong so 0 dau"
t DUNG MANIFEST ebb36   ebb36_off8k     0X08002000 "OFF 0X hoa"
t DUNG MANIFEST ebb36   ebb36_off8k     134225920  "OFF thap phan"
# manifest tu nhat quan (SHA + cfg khop nhan) nhung bin sai: chi kiem vector/VTOR bat
sh() { sha256sum "$1" | cut -d' ' -f1; }
oo=$B/octopus_off0_klipper-0.13.0-822.bin; e0=$B/ebb_off0_klipper-0.13.0-822.bin; e8=$B/ebb_off8k_klipper-0.13.0-822.bin
echo "ebb36_off0 $(sh $oo) $oo $B/ebb_off0.config 0x8000000" > "$G/M_x1"
echo "ebb36_off8k $(sh $e0) $e0 $B/ebb_off8k.config 0x8002000" > "$G/M_x2"
echo "ebb36_off0 $(sh $e8) $e8 $B/ebb_off0.config 0x8000000" > "$G/M_x3"
t DUNG M_x1 ebb36 ebb36_off0  0x08000000 "bin Octopus nhan ebb36_off0, sha+cfg khop"
t DUNG M_x2 ebb36 ebb36_off8k 0x08002000 "bin EBB off0 nhan 8K, sha+cfg 8K khop"
t DUNG M_x3 ebb36 ebb36_off0  0x08000000 "bin EBB 8K nhan off0, sha+cfg off0 khop"
# (A) SHA256SUMS ghi luc build nam canh file that; manifest lap tren chinh file hong van bi chan
m1() { echo "$1 $(sh "$2") $2 $3 $4" > "$G/$5"; } # bien_the bin cfg dia_chi ten_manifest
n8=ebb_off8k_klipper-0.13.0-822.bin; D=$G/sums; rm -rf "$D"; mkdir -p "$D"; cp "$B/SHA256SUMS" "$D/"
cp "$e8" "$D/$n8"; m1 ebb36_off8k "$D/$n8" "$B/ebb_off8k.config" 0x8002000 M_s0
t NAP  M_s0 ebb36 ebb36_off8k 0x08002000 "ban sao dung, SHA256SUMS luc build canh no"
ln -sf "$e0" "$G/lnk_e0.bin"; m1 ebb36_off0 "$G/lnk_e0.bin" "$B/ebb_off0.config" 0x8000000 M_s1
t NAP  M_s1 ebb36 ebb36_off0 0x08000000 "symlink toi bin that (SUMS theo file dich)"
for k in 1 4 64 4096; do
  head -c -$k "$e8" > "$D/$n8"; m1 ebb36_off8k "$D/$n8" "$B/ebb_off8k.config" 0x8002000 M_c$k
  t DUNG M_c$k ebb36 ebb36_off8k 0x08002000 "cat cut $k byte cuoi, manifest lap tren file cat"
done
{ cat "$e8"; printf 'x'; } > "$D/$n8"; m1 ebb36_off8k "$D/$n8" "$B/ebb_off8k.config" 0x8002000 M_c0
t DUNG M_c0 ebb36 ebb36_off8k 0x08002000 "them 1 byte, manifest lap tren file sua"
head -c -4 "$e0" > "$G/cut4.bin"; m1 ebb36_off0 "$G/cut4.bin" "$B/ebb_off0.config" 0x8000000 M_c5
t DUNG M_c5 ebb36 ebb36_off0 0x08000000 "cat cut 4 byte, thu muc khong co SHA256SUMS"
cp "$e8" "$D/$n8"; cp "$B/ebb_off8k.config" "$D/"; echo "# sua" >> "$D/ebb_off8k.config"
m1 ebb36_off8k "$D/$n8" "$D/ebb_off8k.config" 0x8002000 M_c6
t DUNG M_c6 ebb36 ebb36_off8k 0x08002000 ".config sua sau build (khac SHA256SUMS)"
# (B) literal VTOR ghep duoi; SHA256SUMS lap lai tren file da ghep (gia lap) nen chi luat LDR con bat
X=$G/relit; rm -rf "$X"; mkdir -p "$X"
cat "$e8" > "$X/a.bin"; printf '\x00\x00\x00\x08' >> "$X/a.bin"
cat "$e0" > "$X/b.bin"; printf '\x00\x20\x00\x08' >> "$X/b.bin"
cp "$e0" "$X/c.bin"; cp "$e8" "$X/d.bin"; ln -sf "$X/d.bin" "$G/lnk_d.bin"
(cd "$X" && sha256sum a.bin b.bin c.bin d.bin > SHA256SUMS)
m1 ebb36_off0  "$X/a.bin" "$B/ebb_off0.config"  0x8000000 M_l1; t DUNG M_l1 ebb36 ebb36_off0  0x08000000 "bin 8K + literal 0x8000000 ghep duoi, nhan off0"
m1 ebb36_off8k "$X/b.bin" "$B/ebb_off8k.config" 0x8002000 M_l2; t DUNG M_l2 ebb36 ebb36_off8k 0x08002000 "bin off0 + literal 0x8002000 ghep duoi, nhan 8K"
m1 ebb36_off0  "$X/c.bin" "$B/ebb_off0.config"  0x8000000 M_l3; t NAP  M_l3 ebb36 ebb36_off0  0x08000000 "bin off0 that (SUMS lap lai): literal LDR van dat"
m1 ebb36_off8k "$G/lnk_d.bin" "$B/ebb_off8k.config" 0x8002000 M_l4; t NAP  M_l4 ebb36 ebb36_off8k 0x08002000 "symlink toi bin 8K that (SUMS lap lai)"
sed 's/$/\r/' "$G/MANIFEST" > "$G/M_crlf"
t DUNG M_crlf ebb36 ebb36_off8k 0x08002000 "manifest CRLF (phai bao 'CRLF')"
grep -q 'CRLF' "$G/err.txt" && echo "OK  thong bao co chu CRLF" || echo "SAI thong bao thieu CRLF"
rm -f "$G/err.txt"
