#!/bin/bash
# Cong truoc moi lenh nap. Dung: bash ~/reflash-work/gate.sh <ebb36|octopus> <VARIANT> <OFF>
# Dat: in duong dan .bin ra stdout, ma 0. Sai bat ky dieu kien: ly do ra stderr, ma 1, stdout rong.
MANIFEST=${MANIFEST:-$HOME/reflash-work/MANIFEST}
INSPECT=${INSPECT:-$HOME/mcu-build/dump-inspect.py}
BO=$1; VARIANT=$2; OFF=$3
die() { echo "CONG: DUNG: $*" >&2; exit 1; }
[ $# -eq 3 ] && [ -n "$BO" ] && [ -n "$VARIANT" ] && [ -n "$OFF" ] || die "thieu BO/VARIANT/OFF"
case "$BO:$VARIANT" in
  ebb36:ebb36_off0|octopus:octopus_off0) WANT=0x8000000 ;;
  ebb36:ebb36_off8k) WANT=0x8002000 ;;
  octopus:octopus_off128k) WANT=0x8020000 ;;
  *) die "bien the '$VARIANT' khong thuoc bo '$BO'" ;;
esac
[[ $OFF =~ ^0x0*([0-9a-fA-F]{1,8})$ ]] && [ $((16#${BASH_REMATCH[1]})) -eq $((WANT)) ] || die "OFF=$OFF khong khop bien the $VARIANT ($WANT)"
[ -f "$MANIFEST" ] || die "khong co $MANIFEST"
grep -q $'\r' "$MANIFEST" && die "manifest co CRLF (doi sang LF: sed -i 's/\\r\$//' $MANIFEST)"
N=$(awk -v v="$VARIANT" '$1==v' "$MANIFEST" | wc -l)
[ "$N" -eq 1 ] || die "manifest co $N dong cho $VARIANT (phai dung 1)"
read -r NAME SHA BIN CFG ADDR REST < <(awk -v v="$VARIANT" '$1==v' "$MANIFEST")
[ -n "$ADDR" ] && [ -z "$REST" ] || die "dong manifest cua $VARIANT sai dinh dang"
[ "$ADDR" = "$WANT" ] || die "manifest ghi dia chi $ADDR, bien the $VARIANT doi $WANT"
[ -f "$BIN" ] && [ -f "$CFG" ] || die "thieu file $BIN hoac $CFG"
echo "$SHA  $BIN" | sha256sum -c --status - || die "SHA256 cua $BIN khong khop manifest"
for f in "$BIN" "$CFG"; do # bam ghi luc build (3.1) trong SHA256SUMS canh file that: bat file cat cut/sua sau build du manifest lap tren file hong
  r=$(readlink -f "$f"); S=${r%/*}/SHA256SUMS; [ -f "$S" ] || die "khong co $S (ghi luc build, 3.1)"
  H=$(awk -v a="${r##*/}" -v b="$r" '{n=$2; sub(/^\*/, "", n)} n==a || n==b {print $1}' "$S")
  [ "$H" = "$(sha256sum < "$r" | cut -d' ' -f1)" ] || die "$f khong khop dung 1 dong trong $S (cat cut/sua sau build?)"
done
grep -qx "CONFIG_FLASH_APPLICATION_ADDRESS=$ADDR" "$CFG" || die "$CFG khong co dong CONFIG_FLASH_APPLICATION_ADDRESS=$ADDR"
APPOFF=$(printf '0x%X' $((ADDR - 0x8000000)))
python3 "$INSPECT" --board "$BO" --app "$APPOFF" "$BIN" >&2; R=$?
if [ "$BO" = octopus ]; then OK="0"; else OK="0 5"; fi
case " $OK " in *" $R "*) ;; *) die "--app rc=$R (chap nhan: $OK)" ;; esac
if [ "$BO" = ebb36 ]; then # STM32G0B1: flash 512K tai 0x08000000, RAM 144K (SP = 0x20024000). Bang vector + literal VTOR
  SZ=$(stat -L -c %s "$BIN"); [ "$SZ" -ge 64 ] || die "$BIN qua ngan ($SZ byte)"
  A=$((ADDR)); LIM=$((A + SZ)); [ "$LIM" -le $((0x8080000)) ] || die "$BIN vuot flash G0B1 (512K)"
  mapfile -t V < <(od -An -v -tx4 -w4 -N64 "$BIN" | tr -d ' ')
  [ "$((16#${V[0]}))" -eq $((0x20024000)) ] || die "EBB: SP=0x${V[0]} khac 0x20024000 (khong phai G0B1?)"
  [ $((16#${V[1]} & 1)) -eq 1 ] || die "EBB: RESET=0x${V[1]} khong co bit Thumb"
  for w in "${V[@]:1}"; do
    x=$((16#$w)); [ $x -eq 0 ] || [ $x -eq $((0xFFFFFFFF)) ] && continue
    [ $x -ge $A ] && [ $x -lt $LIM ] || die "EBB: vector 0x$w ngoai [$ADDR, $(printf 0x%X $LIM)) (sai offset hoac sai MCU)"
  done
  # literal VTOR phai duoc ma that nap: co lenh Thumb LDR Rt,[PC,#imm8*4] (0x48xx, M0+ chi co dang 16-bit) cach <=1024 byte tro dung vao no
  od -An -v -tu2 -w2 "$BIN" | awk -v a=$A '{h[NR-1]=$1} END{for(i=0;i+1<NR;i+=2) if(h[i]+65536*h[i+1]==a){L=2*i
    for(p=L-2;p>=0 && p>=L-1024;p-=2){x=h[p/2]; if(int(x/2048)==9 && p+4-(p+4)%4+(x%256)*4==L) f=1}} exit !f}' ||
    die "EBB: bin khong co literal VTOR $ADDR duoc lenh LDR nap (build cho offset khac?)"
fi
echo "CONG: DAT: $VARIANT $BIN nap tai $OFF" >&2
echo "$BIN"
