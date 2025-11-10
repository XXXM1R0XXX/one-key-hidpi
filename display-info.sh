#!/bin/bash

# Display information script for macOS
# Lists connected displays with their VendorID, ProductID, and Monitor Name

is_applesilicon=$([[ "$(uname -m)" == "arm64" ]] && echo true || echo false)

function get_displays_intel() {
    local index=0
    local gDisplayInf
    local MonitorName
    local VendorID
    local ProductID
    
    # Using readarray/mapfile is better but not available in older bash
    # shellcheck disable=SC2207
    gDisplayInf=($(ioreg -lw0 | grep -i "IODisplayEDID" | sed -e "/[^<]*</s///" -e "s/\>//"))
    
    if [[ "${#gDisplayInf[@]}" -eq 0 ]]; then
        echo "No monitors found."
        return
    fi
    
    for display in "${gDisplayInf[@]}"; do
        (( index++ ))
        MonitorName="$(echo "${display:190:24}" | xxd -p -r)"
        VendorID=${display:16:4}
        ProductID=${display:22:2}${display:20:2}
        
        if [[ ${VendorID} == 0610 ]]; then
            MonitorName="Apple Display"
        fi
        
        if [[ ${VendorID} == 1e6d ]]; then
            MonitorName="LG Display"
        fi
        
        printf " %d | %s | %s | %s\n" "${index}" "${VendorID}" "${ProductID}" "${MonitorName}"
    done
}

function get_displays_applesilicon() {
    local index=0
    local prodnamesindex=0
    local vends prods prodnames
    local MonitorName VendorID ProductID
    
    # shellcheck disable=SC2207
    vends=($(ioreg -l | grep "DisplayAttributes" | sed -n 's/.*"LegacyManufacturerID"=\([0-9]*\).*/\1/p'))
    # shellcheck disable=SC2207
    prods=($(ioreg -l | grep "DisplayAttributes" | sed -n 's/.*"ProductID"=\([0-9]*\).*/\1/p'))
    
    set -o noglob
    # shellcheck disable=SC2207
    IFS=$'\n' prodnames=($(ioreg -l | grep "DisplayAttributes" | sed -n 's/.*"ProductName"="\([^"]*\)".*/\1/p'))
    set +o noglob
    
    if [[ "${#prods[@]}" -eq 0 ]]; then
        echo "No monitors found."
        return
    fi
    
    for _ in "${prods[@]}"; do
        MonitorName=${prodnames[$prodnamesindex]}
        VendorID=$(printf "%04x" "${vends[$index]}")
        ProductID=$(printf "%04x" "${prods[$index]}")
        
        (( index++ ))
        (( prodnamesindex++ ))
        
        if [[ ${VendorID} == 0610 ]]; then
            MonitorName="Apple Display"
            (( prodnamesindex-- ))
        fi
        
        if [[ ${VendorID} == 1e6d ]]; then
            MonitorName="LG Display"
        fi
        
        printf " %d | %s | %s | %s\n" "${index}" "${VendorID}" "${ProductID}" "${MonitorName}"
    done
}

# Main execution
if [[ $is_applesilicon == true ]]; then
    get_displays_applesilicon
else
    get_displays_intel
fi
