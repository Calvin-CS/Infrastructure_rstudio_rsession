# append /home/cspasswd to /etc/passwd and /home/csgroup to /etc/group
PASSWD=/opt/passwd/cspasswd
GROUP=/opt/passwd/csgroup

if test -f "$PASSWD"; then
	cat $PASSWD >> /etc/passwd
fi

if test -f "$GROUP"; then
	cat $GROUP >> /etc/group
fi
