# Make sure the script is executable
sudo chmod +x /usr/local/bin/yourscript.sh
# Log File setup:
 sudo touch /var/log/yourscript.log
- If running as a non-root user, grant ownership to that user
 sudo chown $(whoami):$(whoami) /var/log/yourscript.log

# Schedule with Cron Jobs:
sudo crontab -e
 * * * * * /usr/local/bin/network_monitor.sh

