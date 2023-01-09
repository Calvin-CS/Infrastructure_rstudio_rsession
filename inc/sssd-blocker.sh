# New setup
/usr/bin/sleep 2.5

#if [ -f /usr/bin/python3 ]; then
#	echo "s6-rc: info: service wait: launching SSSD blocker..."
#	/usr/bin/python3 /root/sssd-blocker.py
#else
#	echo "s6-rc: info: service wait: launcher sleep (2.5 seconds)"
#	/usr/bin/sleep 2.5
#fi

# Old setup
#if [ -f /opt/python/%%PYTHON_VERSION%%/bin/python ]; then
#	echo "s6-rc: info: service wait: launching SSSD blocker..."
#	/opt/python/%%PYTHON_VERSION%%/bin/python /root/sssd-blocker.py
#else
#	echo "s6-rc: info: service wait: launcher sleep (2.5 seconds)"
#	/usr/bin/sleep 2.5
#fi
