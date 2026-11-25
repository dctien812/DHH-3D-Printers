#!/bin/bash
# Mo phong khoi cong §4.3 (dong 368) va §4.4 (dong 404) cua mcu-reflash-v24.md, thay lenh nap bang echo.
R=/mnt/d/WORK/3D-Printer-Klipper/fleet/reflash/2026-11-25
S=/mnt/d/WORK/3D-Printer-Klipper/docs-internal/tools/dump-inspect.py
mcu_cfgaddr() { :; }
octo_gate() { # FILE CFG CFGADDR APPOFF
  FILE=$1; CFG=$2; CFGADDR=$3; APPOFF=$4
  test -n "$FILE" && test -f "$FILE" && grep -qx "CONFIG_FLASH_APPLICATION_ADDRESS=$CFGADDR" "$CFG" && python3 $S --board octopus --app "$APPOFF" "$FILE" >/dev/null && echo "  => NAP (echo dfu-util)" || echo "  => CHAN"
}
ebb_gate() {
  FILE=$1; CFG=$2; CFGADDR=$3; APPOFF=$4
  test -n "$FILE" && test -f "$FILE" && grep -qx "CONFIG_FLASH_APPLICATION_ADDRESS=$CFGADDR" "$CFG" && { python3 $S --board ebb36 --app "$APPOFF" "$FILE" >/dev/null; RR=$?; test $RR -eq 0 -o $RR -eq 5; } && echo "  => NAP (echo dfu-util)" || echo "  => CHAN"
}
O0=$R/octopus_off0_klipper-0.13.0-822.bin; O128=$R/octopus_off128k_klipper-0.13.0-822.bin
E0=$R/ebb_off0_klipper-0.13.0-822.bin; E8=$R/ebb_off8k_klipper-0.13.0-822.bin
echo "Octopus, OFF=128K dung (file128k, cfg128k):  mong doi NAP";   octo_gate $O128 $R/octopus_off128k.config 0x8020000 0x20000
echo "Octopus, OFF=0 dung (file0, cfg0):           mong doi NAP";   octo_gate $O0 $R/octopus_off0.config 0x8000000 0x0
echo "Octopus, OFF=128K nhung FILE=off0 (cfg off0, CFGADDR 128K): mong doi CHAN (grep)"; octo_gate $O0 $R/octopus_off0.config 0x8020000 0x20000
echo "Octopus, OFF=128K, FILE=off0, CFG=off128k (grep qua): mong doi CHAN (--app MISMATCH)"; octo_gate $O0 $R/octopus_off128k.config 0x8020000 0x20000
echo "Octopus, OFF=0, FILE=off128k, CFG=off0 (grep qua): mong doi CHAN"; octo_gate $O128 $R/octopus_off0.config 0x8000000 0x0
echo "EBB, OFF=8K dung:                            mong doi NAP";   ebb_gate $E8 $R/ebb_off8k.config 0x8002000 0x2000
echo "EBB, OFF=0 dung:                             mong doi NAP";   ebb_gate $E0 $R/ebb_off0.config 0x8000000 0x0
echo "EBB, OFF=8K nhung FILE=off0, CFG=off0:       mong doi CHAN (grep)"; ebb_gate $E0 $R/ebb_off0.config 0x8002000 0x2000
echo "EBB, OFF=8K, FILE=off0, CFG=off8k (grep qua): ky vong ly tuong CHAN; du doan: NAP (cong khong phan biet)"; ebb_gate $E0 $R/ebb_off8k.config 0x8002000 0x2000
echo "EBB, OFF=0, FILE=off8k, CFG=off0 (grep qua):  du doan: NAP (cong khong phan biet)"; ebb_gate $E8 $R/ebb_off0.config 0x8000000 0x0
echo "EBB, file Octopus (sai bo) voi cfg ebb:       mong doi CHAN"; ebb_gate $O128 $R/ebb_off8k.config 0x8002000 0x2000
echo "Octopus gate voi file EBB (sai bo):            mong doi CHAN"; octo_gate $E8 $R/octopus_off128k.config 0x8020000 0x20000
