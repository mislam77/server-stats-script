#!/bin/bash

# server-stats.sh - A script to analyze basic server performance stats
# Author: Your Name
# Date: $(date +"%Y-%m-%d")

# ANSI color codes for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}==== $1 ====${NC}"
}

# Function to print info
print_info() {
    echo -e "${GREEN}$1:${NC} $2"
}

# Function to print warning (for high usage values)
print_warning() {
    echo -e "${YELLOW}$1:${NC} $2"
}

# Function to print critical (for very high usage values)
print_critical() {
    echo -e "${RED}$1:${NC} $2"
}

# Check if required tools are installed
check_requirements() {
    local missing_tools=()
    
    for tool in top ps free df awk; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo "Error: The following required tools are missing: ${missing_tools[*]}"
        echo "Please install them and try again."
        exit 1
    fi
}

# Get system information
get_system_info() {
    print_header "SYSTEM INFORMATION"
    
    # OS info
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        print_info "OS" "$PRETTY_NAME"
    else
        print_info "OS" "$(uname -s) $(uname -r)"
    fi
    
    # Kernel version
    print_info "Kernel" "$(uname -r)"
    
    # Uptime
    uptime_seconds=$(cat /proc/uptime | awk '{print $1}' | cut -d. -f1)
    days=$((uptime_seconds/86400))
    hours=$(( (uptime_seconds%86400)/3600 ))
    minutes=$(( (uptime_seconds%3600)/60 ))
    print_info "Uptime" "$days days, $hours hours, $minutes minutes"
    
    # Load average
    load_avg=$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')
    print_info "Load Average" "$load_avg (1min, 5min, 15min)"
    
    # Logged in users
    user_count=$(who | wc -l)
    print_info "Logged in users" "$user_count"
    
    # Last logins
    print_info "Last 3 logins" ""
    last -a | head -n 3 | awk '{print "  - " $1 " from " $3 " at " $5 " " $6 " " $7 " " $8 " " $9 " " $10}'
}

# Get CPU usage statistics
get_cpu_stats() {
    print_header "CPU USAGE"
    
    # Use top to get CPU usage, run it in batch mode for 1 second
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    cpu_usage_rounded=$(printf "%.1f" $cpu_usage)
    
    # Print with color based on usage threshold
    if (( $(echo "$cpu_usage > 90" | bc -l) )); then
        print_critical "CPU Usage" "${cpu_usage_rounded}%"
    elif (( $(echo "$cpu_usage > 70" | bc -l) )); then
        print_warning "CPU Usage" "${cpu_usage_rounded}%"
    else
        print_info "CPU Usage" "${cpu_usage_rounded}%"
    fi
    
    # Get number of cores
    core_count=$(grep -c processor /proc/cpuinfo)
    print_info "CPU Cores" "$core_count"
}

# Get memory usage statistics
get_memory_stats() {
    print_header "MEMORY USAGE"
    
    # Get memory stats
    total_mem=$(free -m | awk 'NR==2 {print $2}')
    used_mem=$(free -m | awk 'NR==2 {print $3}')
    free_mem=$(free -m | awk 'NR==2 {print $4}')
    shared_mem=$(free -m | awk 'NR==2 {print $5}')
    cache_mem=$(free -m | awk 'NR==2 {print $6}')
    avail_mem=$(free -m | awk 'NR==2 {print $7}')
    
    # Calculate percentages
    used_percent=$(echo "scale=1; ($used_mem * 100) / $total_mem" | bc)
    free_percent=$(echo "scale=1; ($free_mem * 100) / $total_mem" | bc)
    avail_percent=$(echo "scale=1; ($avail_mem * 100) / $total_mem" | bc)
    
    # Print with color based on usage threshold
    if (( $(echo "$used_percent > 90" | bc -l) )); then
        print_critical "Memory Used" "${used_mem}MB / ${total_mem}MB (${used_percent}%)"
    elif (( $(echo "$used_percent > 70" | bc -l) )); then
        print_warning "Memory Used" "${used_mem}MB / ${total_mem}MB (${used_percent}%)"
    else
        print_info "Memory Used" "${used_mem}MB / ${total_mem}MB (${used_percent}%)"
    fi
    
    print_info "Memory Free" "${free_mem}MB / ${total_mem}MB (${free_percent}%)"
    print_info "Memory Available" "${avail_mem}MB / ${total_mem}MB (${avail_percent}%)"
    print_info "Memory Shared" "${shared_mem}MB"
    print_info "Memory Cached" "${cache_mem}MB"
}

# Get disk usage statistics
get_disk_stats() {
    print_header "DISK USAGE"
    
    # Get the file systems, exclude pseudo file systems
    df -h -T | grep -v "tmpfs\|devtmpfs\|squashfs\|overlay" | grep -v "Filesystem" | sort | while read line; do
        filesystem=$(echo $line | awk '{print $1}')
        type=$(echo $line | awk '{print $2}')
        size=$(echo $line | awk '{print $3}')
        used=$(echo $line | awk '{print $4}')
        avail=$(echo $line | awk '{print $5}')
        use_percent=$(echo $line | awk '{print $6}' | tr -d '%')
        mounted_on=$(echo $line | awk '{print $7}')
        
        # Print with color based on usage threshold
        if [ "$use_percent" -gt 90 ]; then
            print_critical "$mounted_on ($type)" "Used: $used / $size ($use_percent%)"
        elif [ "$use_percent" -gt 70 ]; then
            print_warning "$mounted_on ($type)" "Used: $used / $size ($use_percent%)"
        else
            print_info "$mounted_on ($type)" "Used: $used / $size ($use_percent%)"
        fi
    done
}

# Get top processes by CPU usage
get_top_cpu_processes() {
    print_header "TOP 5 PROCESSES BY CPU USAGE"
    
    # Use ps to get top 5 processes by CPU usage
    echo -e "${GREEN}PID      CPU%  MEM%  USER     COMMAND${NC}"
    ps aux --sort=-%cpu | head -n 6 | tail -n 5 | awk '{printf "%-8s %-6s %-6s %-9s %s\n", $2, $3, $4, $1, $11}'
}

# Get top processes by memory usage
get_top_memory_processes() {
    print_header "TOP 5 PROCESSES BY MEMORY USAGE"
    
    # Use ps to get top 5 processes by memory usage
    echo -e "${GREEN}PID      MEM%  CPU%  USER     COMMAND${NC}"
    ps aux --sort=-%mem | head -n 6 | tail -n 5 | awk '{printf "%-8s %-6s %-6s %-9s %s\n", $2, $4, $3, $1, $11}'
}

# Get failed login attempts
get_failed_logins() {
    print_header "FAILED LOGIN ATTEMPTS"
    
    # Check if we have access to auth.log or secure log
    if [ -f /var/log/auth.log ]; then
        log_file="/var/log/auth.log"
    elif [ -f /var/log/secure ]; then
        log_file="/var/log/secure"
    else
        print_info "Failed Logins" "Log file not accessible"
        return
    fi
    
    # Get failed login attempts
    failed_count=$(grep "Failed password" $log_file 2>/dev/null | wc -l)
    if [ $failed_count -gt 0 ]; then
        print_warning "Failed Login Attempts" "$failed_count"
        echo -e "${YELLOW}Recent failures:${NC}"
        grep "Failed password" $log_file 2>/dev/null | tail -n 3 | awk '{print "  - " $1 " " $2 " " $3 " " $(NF-3) " from " $(NF)}'
    else
        print_info "Failed Login Attempts" "0"
    fi
}

# Main function
main() {
    # Clear the screen
    clear
    
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${BLUE}      SERVER PERFORMANCE STATS      ${NC}"
    echo -e "${BLUE}=====================================${NC}"
    echo -e "Generated on: $(date)"
    
    # Check if required tools are available
    check_requirements
    
    # Get system information
    get_system_info
    
    # Get CPU usage
    get_cpu_stats
    
    # Get memory usage
    get_memory_stats
    
    # Get disk usage
    get_disk_stats
    
    # Get top processes by CPU usage
    get_top_cpu_processes
    
    # Get top processes by memory usage
    get_top_memory_processes
    
    # Get failed login attempts (stretch goal)
    get_failed_logins
    
    echo -e "\n${BLUE}=====================================${NC}"
    echo -e "Report complete"
}

# Run the main function
main