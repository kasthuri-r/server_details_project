#shebang header tells the operating system which interpreter to use for executing the script.
#!/bin/bash  #specifies that the script should be run using the Bash shell

# Creating the  HTML output file
cat <<EOF > output.html
<!DOCTYPE html>  
<html lang="en"> 
<head>
    <meta charset="UTF-8">  
    <meta name="viewport" content="width=device-width, initial-scale=1.0">   
    <title>Server Details</title>
    <link rel="stylesheet" href="styles.css"> 
</head>
<body>
    <center><h1>Service Health Checker</h1><br><table border=1>
EOF

# Hostname
echo "<tr><th>HOSTNAME</th><td>$(hostname)</td></tr>" >> output.html

# IPv4 Address
echo "<tr><th>IP ADDRESS</th><td>$(hostname -I | awk '{print $1}')</td></tr>" >> output.html
#or $ ip -4 a | grep enp0s | grep inet | awk '{print $2}' | cut -d '/' -f1 

# OS Version
osver=$(grep "PRETTY_NAME" /etc/os-release | awk -F '=' '{print $2}' | tr -d '"')
echo "<tr><th>OS VERSION</th><td>$osver</td></tr>" >> output.html

# Runtime in days
echo "<tr><th>RUN TIME (days)</th><td>$(awk -F ' ' '{print int($1/86400)}' /proc/uptime)</td></tr>" >> output.html

# Hardware Details
echo "<tr><th>HARDWARE DETAILS</th><td><table border=1>" >> output.html

# Checking if the system is virtual or physical
if sudo dmidecode -t system | grep -iq virtual; then
    echo "<tr><th>TYPE</th><td>Virtual</td></tr>" >> output.html
    vmware_version=$(vmware-toolbox-cmd -v 2>/dev/null || echo "Not Installed")
    echo "<tr><th>VMware Tool Version</th><td>$vmware_version</td></tr>" >> output.html
else
    echo "<tr><th>TYPE</th><td>Physical</td></tr>" >> output.html
    serial_no=$(sudo dmidecode -t system | grep 'Serial Number' | awk -F ': ' '{print $2}')
    echo "<tr><th>Serial Number</th><td>$serial_no</td></tr>" >> output.html
    model=$(sudo dmidecode -t system | grep 'Product Name' | awk -F ': ' '{print $2}')
    echo "<tr><th>Hardware Model</th><td>$model</td></tr>" >> output.html
    hba_name=$(lspci | grep -i fibre | awk -F ': ' '{print $2}' | awk '{print $1" "$2}')
    hba_name=${hba_name:-"No HBA Found"}
    echo "<tr><th>Hardware Name</th><td>$hba_name</td></tr>" >> output.html
    hba_speed=$(lspci -vv | grep -i "LnkCap" | grep -oP '(?<=speed ).*?(?=,)' | head -n 1)
    hba_speed=${hba_speed:-"Unknown"}
    echo "<tr><th>SPEED</th><td>$hba_speed</td></tr>" >> output.html
    hba_port=$(lspci | grep -i fibre | awk '{print $1}')
    hba_port=${hba_port:-"No Ports Found"}
    echo "<tr><th>PORT</th><td>$hba_port</td></tr>" >> output.html
fi

# CPU Count
echo "</table></td></tr>" >> output.html
echo "<tr><th>CPU Count</th><td>$(nproc)</td></tr>" >> output.html

# Available memory
echo "<tr><th>Available Memory</th><td>$(free -h | grep Mem | awk '{print $7}')</td></tr>" >> output.html

# Disk Information
echo "<tr><th>DISK</th><td><table border=1>" >> output.html
echo "<tr><th>No of Disks</th><td>$(lsblk -d | grep disk | wc -l)</td></tr>" >> output.html
echo "<tr><th>Total Disk Size</th><td>$(lsblk -d | grep disk | awk '{sum += $4} END {print sum "G"}')</td></tr>" >> output.html
echo "</table></td></tr>" >> output.html

# NIC Information
echo "<tr><th>NIC Information</th><td>$(ip -4 a | grep ' state UP' | awk -F ': ' '{print $2}' | paste -sd ',' -)</td></tr>" >> output.html

# Filesystem Details
echo "<tr><th>FILESYSTEM DETAILS</th><td><table border=1>" >> output.html
echo "<tr><th>Filesystem</th><th>Type</th><th>Size</th><th>Used</th><th>Avail</th><th>Use%</th><th>Mounted on</th></tr>" >> output.html
df -hT | grep -Ev '(tmpfs|Filesystem)' | awk '{print "<tr><td>" $1 "</td><td>" $2 "</td><td>" $3 "</td><td>" $4 "</td><td>" $5 "</td><td>" $6 "</td><td>" $7 "</td></tr>"}' >> output.html
echo "</table></td></tr>" >> output.html

# CPU Socket Information
echo "<tr><th>CPU SOCKET Information</th><td>$(lscpu | grep 'Socket(s):' | awk '{print $2}')</td></tr>" >> output.html

# Firmware Details
firmware_version=$(sudo dmidecode -t bios | grep 'Version:' | awk -F ': ' '{print $2}')
echo "<tr><th>FIRMWARE DETAILS</th><td>$firmware_version</td></tr>" >> output.html

# Loaded, Active, and Running Services
echo "<tr><th>Service Status</th><td><table border=1>" >> output.html
echo "<tr><th>SERVICES</th><th>ACTIVE</th><th>SUB</th></tr>" >> output.html
#Loop through each service and apply CSS class for color coding
systemctl --type=service --state=loaded | head -n -5 | sed 's/●//g' | awk 'NR>1 {
  actv = $3;
  status = $4;
  color = "";
  if (actv == "active" && status == "running") {
      color = "green";
  } else if (actv == "active" && status == "exited") {
      color = "orange";
  } else if (actv == "inactive" && status == "dead") {
      color = "gray";
  } else if (actv == "failed" && status == "failed") {
      color = "red";
  } 
  print "<tr class=\"" color "\"><td>" $1 "</td><td>" actv "</td><td>" status "</td></tr>";
}' >> output.html

echo "</table></td></tr>" >> output.html

# Closing HTML file
echo "</table></center></body></html>" >> output.html
