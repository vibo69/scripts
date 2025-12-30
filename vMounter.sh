#!/usr/bin/env bash
set -euo pipefail

while true; do
    DATA=()
    while read -r line; do
        eval "$line"
        lbl=${LABEL:-"(no label)"}
        mp=${MOUNTPOINT:-no}
        DATA+=("$NAME" "$lbl" "$SIZE" "$mp")
    done < <(lsblk -nPpo NAME,LABEL,SIZE,TYPE,MOUNTPOINT,RM | awk '
    {
      rm=""; type=""
      for(i=1;i<=NF;i++){
        split($i,a,"=")
        gsub(/"/,"",a[2])
        if(a[1]=="RM") rm=a[2]
        if(a[1]=="TYPE") type=a[2]
      }
      if(type=="part" && rm=="1") print $0
    }')
    if (( ${#DATA[@]} == 0 )); then
        yad --info --text="No removable media."
        exit 0
    fi
    SELECTED=$(yad --list \
        --title="USB Mount Manager" \
        --width=500 \
        --column="Device" \
        --column="Label" \
        --column="Size" \
        --column="Mounted" \
        "${DATA[@]}" \
        --button="mount / umount:0" \
        --button="Exit:1" )
    [[ -z "$SELECTED" ]] && exit 0

    DEVICE=$(cut -d'|' -f1 <<< "$SELECTED")
    MOUNTED=$(cut -d'|' -f4 <<< "$SELECTED")

    if [[ "$MOUNTED" == "no" ]]; then
        udisksctl mount -b "$DEVICE" #&& yad --info --text="Mounted $DEVICE"
    else
        udisksctl unmount -b "$DEVICE" #&& yad --info --text="Umounted $DEVICE"
    fi
done
