# sssd-blocker.py
# Author: Chris Wieringa <cwieri39@calvin.edu>
# Date: 2022-08-22
# Purpose: block for up to 10 seconds, testing for SSSD to come online
# and to be able to successfully lookup a known group for Rstudio.
# Group: CS-Rights-rstudio  GID: 364562
# 
# Changelog: 2023-01-05
#   - the container should populate a copy of several groups and users
#     automatically now into /etc/passwd and /etc/group.  If it does this 
#     correctly, this startup script should be MUCH faster, but without the
#     guarentees that SSSD comes online.  This *should* be OK; aznfs is making
#     these files every hour and it should contain everything the container
#     needs to make this all work correctly.

import grp
import time

timeout = 15.0
elapsed = 0.0
success = False
debug = False

# loop until successful or until time elapsed
while (elapsed < timeout and success == False):
    try:
        rgroup = grp.getgrnam('CS-Rights-rstudio')
        if(rgroup.gr_gid == 364562 and len(rgroup.gr_mem) > 0):
           success = True
        else:
           raise KeyError('Invalid gid or group length')
    except KeyError:
        if(debug):
            print("failed",elapsed,rgroup)
        
    elapsed += 0.1
    time.sleep(0.1)

# echo out results
if success:
    print("SSSD successfully queried in",elapsed,"seconds.")
else:
    print("SSSD query failed after",timeout,"seconds.")
