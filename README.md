# IntrusionReactionScript
Bash script that is to be put into crontab to check for an intrusion and ban
IP's using Netfilter.

How-To
- Place the program files in a desired folder
- Create file ‘deny_ips’ in the chosen folder
- Open ssh_monitor_config
- Change the values to what you see fit. 
 - Maxattempts is the amount of attempts before being banned
 - Timeout variables are all added to create the overall ban time
- Run command sudo crontab -e
- Press i, type ‘* * * * * /{ChosenFilepath}/ssh_monitor.ssh’
 - {ChosenFilepath} is the filepath to the folder you selected in step 1
- Type Esc → : → wq → Enter
