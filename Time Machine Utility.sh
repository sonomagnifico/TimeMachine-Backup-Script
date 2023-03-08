#!/bin/bash

## Choose Backup or Restore ##

initSelect=$(osascript -e 'display dialog "What do you want to do?" with title "Time Machine Backup Tool" with text buttons {"Restore", "Backup"} default button 2
set initSelect to the (button returned of the result)' )

## FUCTIONS ##

restore () {
    ## Select the volume where the backup is located ##
echo "Prompting user to select a volume to restore from"
RestoreFolderName=$(osascript -e 'set chooseFolder to POSIX path of (choose folder with prompt "Select the \"Users\" folder to restore from:")')
#destinationVolume=$(echo $RestoreFolderName | awk '{gsub(/ /,"\\ ");print}')
echo "Restore volume selected: ${RestoreFolderName}"

## Restores users' home folders to the /Users/ folder ##
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper \
        -windowType utility \
        -windowPosition ul \
        -title "Time Machine Restore Utility" \
        -alignHeading center \
        -alignDescription center \
        -description "Restoration in progress. Please wait..." \
        -icon "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericTimeMachineDiskIcon.icns" \
        -iconSize 100 &

jamfHUDPID=$!
sudo tmutil restore "$RestoreFolderName" /Users
kill "$jamfHUDPID"
}

backup () {
    #########################################################
##### Functions #########################################
#########################################################

getDestinationVolume () { echo "Prompting user to select a volume for the backup."
    destinationVolumeName=$(osascript -e 'do shell script "ls /Volumes/"
    set _Result to the paragraphs of result
    set theVolumeTemp to (choose from list _Result with prompt "Choose Volume:" without empty selection allowed)
    if theVolumeTemp is false then return
    set desinationVolumeName to "/Volumes/" & theVolumeTemp')
    destinationVolume=$(echo $destinationVolumeName | awk '{gsub(/ /,"\\ ");print}')
    echo "Volume selected: ${destinationVolume}"
}
getDestinationID () { echo "Getting current destination ID."
    destinationID=$(sudo tmutil destinationinfo | grep ID | cut -d " " -f 14)
}
startTMBackup () {
	echo "Setting destination."
    sudo tmutil setdestination $destinationVolume
	echo "Disabling Time Machine Throttling."
    sudo sysctl debug.lowpri_throttle_enabled=0
	echo "starting Time Machine Backup..."
    sudo tmutil startbackup
}
setExclusions () { echo "Adding exclusions to Time Machine."
    # Exclude all System folders
    sudo tmutil addexclusion -p /Applications
    sudo tmutil addexclusion -p /Library
    sudo tmutil addexclusion -p /System
    # Exclude any other users on the computer (Edit for your specifics)
    sudo tmutil addexclusion -p /Users/ccsa_ustadmin
    sudo tmutil addexclusion -p /Users/ccsa_ustadmins
    sudo tmutil addexclusion -p /Users/Shared
    # Exclude hidden root os folders
    sudo tmutil addexclusion -p /bin
    sudo tmutil addexclusion -p /cores
    sudo tmutil addexclusion -p /etc
    sudo tmutil addexclusion -p /Network
    sudo tmutil addexclusion -p /private
    sudo tmutil addexclusion -p /sbin
    sudo tmutil addexclusion -p /tmp
    sudo tmutil addexclusion -p /usr
    sudo tmutil addexclusion -p /var
}
preparing () { 
    currentState=$(tmutil status | grep BackupPhase)
    while [ "$currentState" = "    BackupPhase = SizingChanges;" ]
    do     
    echo "Getting ready to backup. Please wait..." 
    sleep 300
    currentState=$(tmutil status | grep BackupPhase)
    done
    sudo kill "$jamfHUDPID"
}
thinningPreBackup () { 
    currentState=$(tmutil status | grep BackupPhase)
    while [ "$currentState" = "    BackupPhase = ThinningPreBackup;" ]
    do     
    echo "Getting ready to backup. Please wait..." 
    sleep 300
    currentState=$(tmutil status | grep BackupPhase)
    done
    sudo kill "$jamfHUDPID"
}
getStatus () { 
    currentState=$(tmutil status | grep BackupPhase)
    while [ "$currentState" = "    BackupPhase = Copying;" ]
    do     
    echo "Backup in progress" 
    sleep 5m
    currentState=$(tmutil status | grep BackupPhase)
    done
    echo "Backup completed"
    sudo kill "$jamfHUDPID"
}
jamfHelperPreparing () {
    if [[ -e /Library/Application\ Support/JAMF/bin/jamfHelper.app ]]; then
    /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper \
        -windowType utility \
        -windowPosition ul \
        -title "Time Machine Backup Utility" \
        -alignHeading center \
        -alignDescription center \
        -description "Getting ready to backup. Please wait..." \
        -icon "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericTimeMachineDiskIcon.icns" \
        -iconSize 100 &

    jamfHUDPID=$!
    fi
}
jamfHelperThinningPreBackup () {
    if [[ -e /Library/Application\ Support/JAMF/bin/jamfHelper.app ]]; then
    /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper \
        -windowType utility \
        -windowPosition ul \
        -title "Time Machine Backup Utility" \
        -alignHeading center \
        -alignDescription center \
        -description "Getting ready to backup. Please wait..." \
        -icon "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericTimeMachineDiskIcon.icns" \
        -iconSize 100 &

    jamfHUDPID=$!
    fi
}
jamfHelperInProgress () {
    if [[ -e /Library/Application\ Support/JAMF/bin/jamfHelper.app ]]; then
    /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper \
        -windowType utility \
        -windowPosition ul \
        -title "Time Machine Backup Utility" \
        -alignHeading center \
        -alignDescription center \
        -description "Time Machine Backup in Progress. Please wait..." \
        -icon "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericTimeMachineDiskIcon.icns" \
        -iconSize 100 &

    jamfHUDPID=$!
    fi
}
removeTMConfig () {
	getDestinationID
    sudo tmutil removedestination $destinationID
    sudo sysctl debug.lowpri_throttle_enabled=1
}

#################################################################################################################

#######################################
#### Remove previous configuration ####
#######################################

echo "Getting current destination ID."
destinationID=$(sudo tmutil destinationinfo | grep ID | cut -d " " -f 14)
echo "Removing current destination disk."
sudo tmutil removedestination $destinationID
echo "Enabling Time Machine Throttling."
sudo sysctl debug.lowpri_throttle_enabled=1

####################################
#### Getting Destination Volume ####
####################################

echo "Prompting user to select a volume for the backup."
destinationVolumeName=$(osascript -e 'do shell script "ls /Volumes/"
set _Result to the paragraphs of result
set theVolumeTemp to (choose from list _Result with prompt "Choose Volume:" without empty selection allowed)
if theVolumeTemp is false then return
set destinationVolumeName to "/Volumes/" & theVolumeTemp')
destinationVolume=$(echo $destinationVolumeName | awk '{gsub(/ /,"\\ ");print}')
echo "Volume selected: ${destinationVolume}"

###########################################
#### Check if Destination was selected ####
###########################################

if [ "$destinationVolume" = "" ] ; then
echo "No destination selected. Operation aborted."
exit 3
fi

##################################################
#### Warn user that the volume will be erased ####
##################################################



############################
#### Setting Exclusions ####
############################

## Ask to set exclusions or perform a full backup.
optionSelect=$(osascript -e 'display dialog "Please select a backup option below.\n\nFull backup: This option will create a complete backup of the entire volume. Includes Applications, Hidden OS folders, User Data, etc.\n\nLite Backup: This option will exclude OS and Applications folders. It will backup mainly the user home folders." with title "Time Machine Backup Tool" with text buttons {"Lite Backup", " Full Backup"} default button 2
set optionSelect to the (button returned of the result)' )
if [ "$optionSelect" == "Lite Backup" ]; then
echo "Time Machine restore starting..."
setExclusions
fi


#########################
#### Start TM Backup ####
#########################

echo "Setting new destination."
sudo tmutil setdestination -a $destinationVolume
echo "Disabling Time Machine Throttling."
sudo sysctl debug.lowpri_throttle_enabled=0
echo "Starting Time Machine Backup..."
sudo tmutil startbackup

sleep 3

#jamfHelperThinningPreBackup
thinningPreBackup

sleep 3

#jamfHelperPreparing
preparing

sleep 3

#jamfHelperInProgress
getStatus

sleep 3

removeTMConfig

echo "Time Machine restore completed."
}

## Execution ##

if [ "$initSelect" == "Restore" ]; then
echo "Time Machine restore starting..."
restore
elif [ "$initSelect" == "Backup" ]; then
echo "Time Machine backup starting..."
backup
fi