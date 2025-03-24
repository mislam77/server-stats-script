# Server Statistics Script

A Bash script for monitoring and analyzing Linux server performance.

## Overview

This utility provides a quick snapshot of system performance metrics in a clear, color-coded format. It displays critical information about CPU, memory, disk usage, and processes to help diagnose performance issues and monitor system health.

## Features

- **CPU Usage Statistics**
  - Total CPU utilization percentage
  - CPU core count

- **Memory Usage Analysis**
  - Total, used, and free memory
  - Memory usage percentages
  - Shared and cached memory information

- **Disk Space Monitoring**
  - Storage usage across all mounted filesystems
  - Available and used space with percentages

- **Process Management**
  - Top 5 CPU-intensive processes
  - Top 5 memory-consuming processes

- **System Information**
  - OS version and kernel details
  - System uptime
  - Current load average
  - Logged-in users

- **Security Insights**
  - Failed login attempt tracking
  - Recent login history

## Installation & Usage

1. Clone this repository:
   ```bash
   git clone https://github.com/mislam77/server-stats-script.git
   cd server-stats-script
   ```

2. Make the script executable:
   ```bash
   chmod +x server-stats.sh
   ```

3. Execute the script:
   ```bash
   ./server-stats.sh
   ```

## Requirements

The script requires the following standard Linux utilities:
- top
- ps
- free
- df
- awk

All of these are typically pre-installed on most Linux distributions.

## Customization

You can modify threshold values for warnings by editing the script. Look for conditions like:

```bash
if (( $(echo "$cpu_usage > 90" | bc -l) )); then
```

Adjust the values (90, 70, etc.) to change when warnings and critical alerts are triggered.

## Acknowledgments

- Inspired by the need for quick server diagnostics
- Developed as a learning project for Bash scripting