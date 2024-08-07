# vm_kill_on_switch_user
This is a PowerShell script to be used alongside Windows Task Scheduler in order to prevent certain processes (like VMs) from continuing running when another user logs in. This intended to be used in the ME597 lab computers.

## What does this script do?
This is a simple PowerShell script that follows these primary steps:
1. Get all processes with `vmware-vmx` in the name. This is analogous to opening task manager and searching vmware-vmx.
2. Get the username of the current user that has just logged on.
3. For each process found in step 1, get the username of the user that started it.
4. Then, if the user in step 3 is different from the current user found in step 2, end the process.
5. If they are the same user, do nothing.

There are some extra commands in this script that log details, such as timestamp, processes found, and memory usage of those processes.

## When will this script run?
This script is run by windows task scheduler, which is a windows job scheduling service that has been around since 1995. We will create a new task in the task scheduler that will run the PowerShell script above and be "triggered" on both user log-in and unlock.

## Instructions
1. Save the `kill_vm_on_switch_user.ps1` file somewhere on the Windows PC.
1. Open `Task Scheduler` either by searching in start menu or pressing `WIN + R` and typing `taskschd.msc`.
2. Open `Create Task...`
3. `General` Tab:
    - Give it a Name
    -  Go to `Change User or Group` and in `Enter the object name...` type `SYSTEM`, then click `Check Names`, then `OK`.
        -  Note: This means that the script will be run by SYSTEM, rather than a specific user who might have permissions issues.
    - Check `Run with highest privileges`
4. `TRIGGERS` Tab:
    - Click `New...`
    - Set `Begin the task:` to `At log on`. Click `OK` then do the same for `On workstation unlock`.
    - Click `OK`
5. `ACTIONS` Tab:
    - Click `New...`
    - In `Program/script` type `PowerShell`
    - In `Add arguments` type `-File "path/to/your/kill_vm_on_switch_user.ps1"`
    - Click `OK`
6. Click `OK`
7. Make sure the task is enabled. If you run into issues, check the log file, which is created at `C:\Users\Public\automate\log_killvm.txt` by default, but you may change this.
