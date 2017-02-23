@echo off
cd "%~dp0"
IF EXIST "%~dp0\pushed" SET PATH=%PATH%;"%~dp0\pushed"
IF EXIST "%~dp0\working" SET PATH=%PATH%;"%~dp0\working"
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Setlocal EnableDelayedExpansion
attrib +h "pushed" >nul
attrib +h "working" >nul
attrib +h "dirty-cow-log" >nul
attrib +h "adb.exe" >nul
attrib +h "fastboot.exe" >nul
attrib +h "AdbWinApi.dll" >nul
attrib +h "AdbWinUsbApi.dll" >nul
IF NOT EXIST "pushed\*.*" GOTO error 
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:main
cls
echo( 
echo 	***************************************************
echo 	*                                                 *
echo 	*      R1-HD Bootloader Unlock Tool               *
echo 	*                                                 *
echo 	***************************************************
echo(
echo 		 Choose what you need to work on.
echo(
echo 		][********************************][
echo 		][ 1. Push Files for Dirtycow     ][
echo 		][********************************][
echo 		][ 2. Run the Dirty-cow Part      ][
echo 		][********************************][
echo 		][ 3. Do Bootloader Unlock        ][
echo 		][********************************][
echo 		][ 4.  Flash TWRP                 ][
echo 		][********************************][
echo 		][ 5.  Extra Menu                 ][
echo 		][********************************][
echo 		][ 6.  SEE INSTRUCTIONS           ][
echo 		][********************************][
echo 		][ E.  EXIT                       ][
echo 		][********************************][
echo 		][ V.  VIEW LOG                   ][
echo 		][********************************][
echo 		][ C.  CLEAR LOG                  ][
echo 		][********************************][
echo(
set /p env=Type your option [1,2,3,4,5,6,E,V,C] then press ENTER: || set env="0"
if /I %env%==1 goto push
if /I %env%==2 goto dirty-cow
if /I %env%==3 goto unlock
if /I %env%==4 goto TWRP
if /I %env%==5 goto second
if /I %env%==6 goto instructions
if /I %env%==E goto end
if /I %env%==V goto log
if /I %env%==C goto clear
echo(
echo %env% is not a valid option. Please try again! 
PING -n 3 127.0.0.1>nul
goto main
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:adb_check
adb devices -l | find "device product:" >nul
if errorlevel 1 (
    echo No adb connected devices && echo %date% %time% [E] No adb device detected, check phone state, or drivers. >> "%~dp0\dirty-cow-log\log.txt"
	pause
	GOTO main
) else (
    echo Found ADB!)
:: (emulated "Return")
GOTO %RETURN%	
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:fastboot_check
adb devices -l | find "device product:" >nul
if errorlevel 1 (
    echo No adb connected devices
GOTO fastboot_check2
) else (
    echo Found ADB!
	adb reboot bootloader
	timeout 10)
GOTO fastboot_check2
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:fastboot_check2
	fastboot devices -l | find "fastboot" >nul
if errorlevel 1 (
    echo No connected devices && echo %date% %time% [E] No fastboot device detected. >> "%~dp0\dirty-cow-log\log.txt"
pause
goto main
) else (
    echo Found FASTBOOT!)
:: (emulated "Return")
GOTO %RETURN%
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:push
cls
SET RETURN=Label1
GOTO adb_check
:Label1
echo [*] clear tmp folder
adb shell rm -f /data/local/tmp/*
echo [*] copying dirtycow to /data/local/tmp/dirtycow
adb push pushed/dirtycow /data/local/tmp/dirtycow
timeout 3
echo [*] copying recowvery-app_process32 to /data/local/tmp/recowvery-app_process32
adb push pushed/recowvery-app_process32 /data/local/tmp/recowvery-app_process32
timeout 3
echo [*] copying frp.bin to /data/local/tmp/unlock
adb push pushed/frp.bin /data/local/tmp/unlock
timeout 3
echo [*] copying busybox to /data/local/tmp/busybox
adb push pushed/busybox /data/local/tmp/busybox
timeout 3
echo [*] copying cp_comands.txt to /data/local/tmp/cp_comands.txt
adb push pushed/cp_comands.txt /data/local/tmp/cp_comands.txt
timeout 3
echo [*] copying dd_comands.txt to /data/local/tmp/dd_comands.txt
adb push pushed/dd_comands.txt /data/local/tmp/dd_comands.txt
timeout 3
echo [*] changing permissions on copied files
adb shell chmod 0777 /data/local/tmp/*
timeout 3
echo [*] checking contents of phone folder
adb shell ls -l /data/local/tmp > "%~dp0\working\phone_file_check.txt" 
adb shell /data/local/tmp/busybox md5sum /data/local/tmp/unlock > "%~dp0\working\phone_file_md5.txt"
adb shell /data/local/tmp/busybox md5sum /data/local/tmp/recowvery-app_process32 >> "%~dp0\working\phone_file_md5.txt"
adb shell /data/local/tmp/busybox md5sum /data/local/tmp/dirtycow >> "%~dp0\working\phone_file_md5.txt"
adb shell /data/local/tmp/busybox md5sum /data/local/tmp/dd_comands.txt >> "%~dp0\working\phone_file_md5.txt"
adb shell /data/local/tmp/busybox md5sum /data/local/tmp/cp_comands.txt >> "%~dp0\working\phone_file_md5.txt"
adb shell /data/local/tmp/busybox md5sum /data/local/tmp/busybox >> "%~dp0\working\phone_file_md5.txt"
timeout 5
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::
::error checking    checks the contents of the tmp folder and compairs MD5 of what it should be
::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::
find "b5eec83df6dd57902a857f6c542e793e  /data/local/tmp/busybox" "%~dp0\working\phone_file_md5.txt"
if errorlevel 1 (
    echo busybox file does not match 
	echo need to push files again maybe need to download zip file again too && echo %date% %time% [W] Files pushed to phone do not match reference file. >> "%~dp0\dirty-cow-log\log.txt"
	pause
	GOTO main
) else (
    echo busybox matches md5)
find "df5cf88006478ad421028c58df5a55ad  /data/local/tmp/cp_comands.txt" "%~dp0\working\phone_file_md5.txt"
if errorlevel 1 (
    echo cp_comands.txt file does not match 
	echo need to push files again maybe need to download zip file again too && echo %date% %time% [W] Files pushed to phone do not match reference file. >> "%~dp0\dirty-cow-log\log.txt"
	pause
	GOTO main
) else (
    echo cp_comands.txt matches md5)
find "28443a967a9b39215b5102573ef1731b  /data/local/tmp/dd_comands.txt" "%~dp0\working\phone_file_md5.txt"
if errorlevel 1 (
    echo dd_comands.txt file does not match 
	echo need to push files again maybe need to download zip file again too && echo %date% %time% [W] Files pushed to phone do not match reference file. >> "%~dp0\dirty-cow-log\log.txt"
	pause
	GOTO main
) else (
    echo dd_comands.txt matches md5)
find "8259b595dbfa9cea131bd798ad4ef323  /data/local/tmp/dirtycow" "%~dp0\working\phone_file_md5.txt"
if errorlevel 1 (
    echo dirtycow file does not match 
	echo need to push files again maybe need to download zip file again too && echo %date% %time% [W] Files pushed to phone do not match reference file. >> "%~dp0\dirty-cow-log\log.txt"
	pause
	GOTO main
) else (
    echo dirtycow matches md5)
find "d201fb59330cc11343452479757f6c40  /data/local/tmp/recowvery-app_process32" "%~dp0\working\phone_file_md5.txt"
if errorlevel 1 (
    echo recowvery-app_process32 file does not match 
	echo need to push files again maybe need to download zip file again too && echo %date% %time% [W] Files pushed to phone do not match reference file. >> "%~dp0\dirty-cow-log\log.txt"
	pause
	GOTO main
) else (
    echo recowvery-app_process32 matches md5)
find "18ab1955384691a35b127a3eebd6ef72  /data/local/tmp/unlock" "%~dp0\working\phone_file_md5.txt"
if errorlevel 1 (
    echo unlock file does not match 
	echo need to push files again maybe need to download zip file again too && echo %date% %time% [W] Files pushed to phone do not match reference file. >> "%~dp0\dirty-cow-log\log.txt"
	pause
	GOTO main
) else (
    echo unlock matches md5)
echo       File compair matches
echo       Safe to continue to run Dirty-cow
pause
GOTO main
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:dirty-cow
cls
SET RETURN=Label2
GOTO adb_check
:Label2
::::::::::::::::::::::::::::::
adb shell /data/local/tmp/dirtycow /system/bin/app_process32 /data/local/tmp/recowvery-app_process32
echo.--------------------------------------------------------------------------------------------
echo.--------------------------------------------------------------------------------------------
echo.--------------------------------------------------------------------------------------------
echo [*]WAITING 60 SECONDS FOR ROOT SHELL TO SPAWN
echo [*] WHILE APP_PROCESS IS REPLACED PHONE WILL APPEAR TO BE UNRESPONSIVE BUT SHELL IS WORKING
timeout 60
pause
echo.--------------------------------------------------------------------------------------------
echo [*] OPENING A ROOT SHELL ON THE NEWLY CREATED SYSTEM_SERVER
echo [*] MAKING A DIRECTORY ON PHONE TO COPY FRP PARTION TO 
echo [*] CHANGING PERMISSIONS ON NEW DIRECTORY
echo [*] COPYING FRP PARTION TO NEW DIRECTORY AS ROOT
echo [*] CHANGING PERMISSIONS ON COPIED FRP
adb shell "/data/local/tmp/busybox nc localhost 11112 < /data/local/tmp/cp_comands.txt"
echo [*] COPYING UNLOCK.IMG OVER TOP OF COPIED FRP IN /data/local/test NOT AS ROOT WITH DIRTYCOW
echo [*]
adb shell /data/local/tmp/dirtycow /data/local/test/frp /data/local/tmp/unlock
timeout 5
echo checking md5 of new frp before copying to mmcblk0p17
adb shell /data/local/tmp/busybox md5sum /data/local/test/frp > "%~dp0\working\new_frp_md5.txt"
find "18ab1955384691a35b127a3eebd6ef72  /data/local/test/frp" "%~dp0\working\new_frp_md5.txt"
if errorlevel 1 (
    echo new_frp_md5 does not match 
	echo Something Went Wrong Restarting phone and try again && echo %date% %time% [W] Final stage of dirty-cow has failed md5 error checking. >> "%~dp0\dirty-cow-log\log.txt"
	pause
	adb reboot
	GOTO main
) else (
    echo new_frp matches md5)
echo [*] WAITING 5 SECONDS BEFORE WRITING FRP TO EMMC
timeout 5
echo [*] DD COPY THE NEW (UNLOCK.IMG) FROM /data/local/test/frp TO PARTITION mmcblk0p17
adb shell "/data/local/tmp/busybox nc localhost 11112 < /data/local/tmp/dd_comands.txt"
echo coping new frp is done phone now, will reboot and script will return to start screen
pause 
adb reboot
GOTO main
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:unlock
cls
SET RETURN=Label3
GOTO fastboot_check
:Label3
:::::::::::::::::::::::::::::::::::
::checking the getvar output to verify if phone is unlocked aready
:::::::::::::::::::::::::::::::::::::
fastboot getvar all 2> "%~dp0\working\getvar.txt"
find "unlocked: yes" "%~dp0\working\getvar.txt"
if errorlevel 1 (
    echo Not Unlocked 
GOTO continue_unlock
) else (
    echo Already UNLOCKED)
	echo continue to TWRP option, you are alread unlocked
	pause
GOTO main
:continue_unlock
:::::::::::::::::::::::::::::::::::
::checking the get_unlock_ability output string to verify it is greater than "0" because "0" is unlockable
::::::::::::::::::::::::::::::::::::
fastboot flashing get_unlock_ability 2> "%~dp0\working\unlockability.txt"
for /f "tokens=4" %%i in ('findstr "^(bootloader) unlock_ability" %~dp0\working\unlockability.txt') do set unlock=%%i
echo output from find string = %unlock%
if %unlock% gtr 1 ( 
echo unlockable
GOTO Continue
) else (
echo Not-unlockable
echo must re-run dirty-cow && echo %date% %time% [W] Checking Unlock_ability failed. >> "%~dp0\dirty-cow-log\log.txt"
pause
GOTO main)
:Continue
echo [*] ON YOUR PHONE YOU WILL SEE 
echo [*] PRESS THE VOLUME UP/DOWN BUTTONS TO SELECT YES OR NO
echo [*] JUST PRESS VOLUME UP TO START THE UNLOCK PROCESS.
echo.-------------------------------------------------------------------------
echo.-------------------------------------------------------------------------
pause
fastboot oem unlock
timeout 5
fastboot format userdata
timeout 5
fastboot format cache
timeout 5
fastboot reboot
echo [*]         IF PHONE DID NOT REBOOT ON ITS OWN 
echo [*]         HOLD POWER BUTTON UNTILL IT TURNS OFF
echo [*]         THEN TURN IT BACK ON
echo [*]         EITHER WAY YOU SHOULD SEE ANDROID ON HIS BACK 
echo [*]         WHEN PHONE BOOTS, FOLLOWED BY STOCK RECOVERY 
echo [*]         DOING A FACTORY RESET
pause
GOTO main
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:TWRP
cls
SET RETURN=Label4
GOTO fastboot_check
:Label4
:::::::::::::::::::::::::::::::::::
::checking the getvar output to verify if phone is unlocked aready
:::::::::::::::::::::::::::::::::::::
fastboot getvar all 2> "%~dp0\working\getvar.txt"
find "unlocked: yes" "%~dp0\working\getvar.txt"
if errorlevel 1 (
    echo Not Unlocked 
	echo returning to unlocksection, then phone will wipe and tool will return to main window
	GOTO continue_unlock
) else (
    echo Already UNLOCKED)
	echo continue to TWRP option, you are alread unlocked
echo [*] DEFAULT CHOISE OF RECOVERY HAS BEEN SET TO VAMPIREFO'S 7.1
CHOICE  /C 12 /T 10 /D 1 /M "Do You Want To Install 1=Vampirfo or 2=lopestom recovery"
IF ERRORLEVEL 2 GOTO 20
IF ERRORLEVEL 1 GOTO 10

:10
echo you chose to instal Vampirefo 's V7.1 built recovery && echo %date% %time% [I] Vamirefo's v7.1 TWRP Recovery flashed . >> "%~dp0\dirty-cow-log\log.txt"
pause
fastboot flash recovery pushed/twrp_p6601_7.1_recovery.img
GOTO recovery
:20
echo you chose not to instal Lopestom Ported recovery && echo %date% %time% [I] Lopestom's ported TWRP Recovery flashed. >> "%~dp0\dirty-cow-log\log.txt"
pause
fastboot flash recovery pushed/recovery.img
:recovery
echo [*] ONCE THE FILE TRANSFER IS COMPLETE HOLD VOLUME UP AND PRESS ANY KEY ON PC 
echo [*]
echo [*] IF PHONE DOES NOT REBOOT THEN HOLD VOLUME UP AND POWER UNTILL IT DOES
pause
fastboot reboot
echo [*] ON PHONE SELECT RECOVERY FROM BOOT MENU WITH VOLUME KEY THEN SELECT WITH POWER
pause
GOTO main
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:instructions
cls
type "Instructions.txt"
pause
GOTO main
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:log
cls
type "%~dp0\dirty-cow-log\log.txt"
CHOICE  /C YN  /M "Do You Want To Copy Log to Clipboard to share issue with forum"
IF ERRORLEVEL 2 GOTO 20
IF ERRORLEVEL 1 GOTO 10

:10
echo log is now in clipboard You can right click and paste it to anywhere (Like in forrum post)
type "%~dp0\dirty-cow-log\log.txt" | clip
pause
goto main
:20
echo log not copied
pause
GOTO main
:clear
del "%~dp0\dirty-cow-log\log.txt"
GOTO main
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:second
cls
echo( 
echo 	***************************************************
echo 	*                                                 *
echo 	*      R1-HD Bootloader Unlock Tool               *
echo 	*                                                 *
echo 	***************************************************
echo(
echo 		 Choose what you need to work on.
echo(
echo 		][********************************][
echo 		][ 1.      Flash SuperSu          ][
echo 		][********************************][
echo 		][ 2. AMZ Full Debloat script v2  ][
echo 		][********************************][
echo 		][ 3. AMZ Part Debloat script v2  ][
echo 		][********************************][
echo 		][ 4.     Google Debloat v2       ][
echo 		][********************************][
echo 		][ 5.    MTK_BLU Debloat v2       ][
echo 		][********************************][
echo 		][ 6.       UNDO DE-BLOAT         ][
echo 		][********************************][
echo 		][ 7.       Add FM Radio          ][
echo 		][********************************][
echo 		][ 8.    ROLL Back Preloader      ][
echo 		][********************************][
echo 		][ R.      Return to Main         ][
echo 		][********************************][
echo(
set /p env=Type your option [1,2,3,4,5,6,7,8,R] then press ENTER: || set env="0"
if /I %env%==1 goto SuperSU
if /I %env%==2 goto debloatfull
if /I %env%==3 goto debloatpart
if /I %env%==4 goto debloatgoogle
if /I %env%==5 goto debloatmtkblu
if /I %env%==6 goto re-bloat
if /I %env%==7 goto radio
if /I %env%==8 goto preloader
if /I %env%==R goto main
echo(
echo %env% is not a valid option. Please try again! 
PING -n 3 127.0.0.1>nul
goto main
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:SuperSU
cls
SET RETURN=Label5
GOTO adb_check
:Label5
adb reboot recovery
adb wait-for-device
adb push pushed/UPDATE-SuperSU-v2.76-20160630161323.zip /sdcard/Download
adb shell "/sbin;recovery -- update_package=/sdcard/Download/UPDATE-SuperSU-v2.76-20160630161323.zip"
pause
goto main
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:debloatfull
cls
SET RETURN=Label6
GOTO adb_check
:Label6
adb reboot recovery
adb wait-for-device
adb push pushed/bluR1-AMZ-FULLdebloat-blockOTA_v2.zip /sdcard/Download
adb shell "/sbin;recovery -- update_package=/sdcard/Download/bluR1-AMZ-FULLdebloat-blockOTA_v2.zip"
echo debloat scripts curtesy of emc2cube
pause
goto main
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:debloatpart
cls
SET RETURN=Label7
GOTO adb_check
:Label7
adb reboot recovery
adb wait-for-device
adb push pushed/bluR1-AMZ-PARTIALdebloat-blockOTA_v2.zip /sdcard/Download
adb shell "/sbin;recovery -- update_package=/sdcard/Download/bluR1-AMZ-PARTIALdebloat-blockOTA_v2.zip"
echo debloat scripts curtesy of emc2cube
pause
goto main
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:debloatgoogle
cls
SET RETURN=Label8
GOTO adb_check
:Label8
adb reboot recovery
adb wait-for-device
adb push pushed/bluR1-GOOGLE-debloat_v2.zip /sdcard/Download
adb shell "/sbin;recovery -- update_package=/sdcard/Download/bluR1-GOOGLE-debloat_v2.zip"
echo debloat scripts curtesy of emc2cube
pause
goto main
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:debloatmtkblu
cls
SET RETURN=Label9
GOTO adb_check
:Label9
adb reboot recovery
adb wait-for-device
adb push pushed/bluR1-MTK_BLU-debloat_v2.zip /sdcard/Download
adb shell "/sbin;recovery -- update_package=/sdcard/Download/bluR1-MTK_BLU-debloat_v2.zip"
echo debloat scripts curtesy of emc2cube
pause
goto main
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:re-bloat
cls
SET RETURN=Label10
GOTO adb_check
:Label10
adb reboot recovery
adb wait-for-device
adb push pushed/bluR1-RestoreApps-OTA.zip /sdcard/Download
adb shell "/sbin;recovery -- update_package=/sdcard/Download/bluR1-RestoreApps-OTA.zip"
echo coming soon
pause
goto main
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:radio
cls
SET RETURN=Label11
GOTO adb_check
:Label11
adb reboot recovery
adb wait-for-device
adb push pushed/fm_Radio_WITHOUT_boot.zip /sdcard/Download
adb shell "sbin;recovery -- update_package=/sdcard/Download/fm_Radio_WITHOUT_boot.zip"
echo Also need to install A program called selinux mode changer
echo It is available from Either xda thread
echo https://forum.xda-developers.com/devdb/project/dl/?id=12506
echo  or also from F-Droid
pause
goto main
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:preloader
cls
SET RETURN=Label9
GOTO adb_check
:Label9
adb reboot recovery
adb wait-for-device
adb push pushed/after_bootloader_roll_back_5.zip /sdcard/Download
adb shell "/sbin;recovery -- update_package=/sdcard/Download/after_bootloader_roll_back_5.zip"
echo It is likely that at this point phone is Boot-looping 
echo At this point if looping Hold volume up during the boot-looping
echo you should be at the boot select menu now
echo Use volume keys to choose fastboot, then power button to enter
echo BOOTLOADER WILL NOW BE MADE "SECURE = NO" BY REDOING OEM UNLOCK
echo(
pause
goto continue_unlock
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:error
echo Image File not Found!! && echo(%date% %time% [W] No files found in the pushed folder, Or pushed folder not where expected. Expected location is "%~dp0\pushed")  >> "%~dp0\dirty-cow-log\log.txt"
echo Check that you have unzipped the 
echo whole Tool Package
pause
goto end
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:error1
echo Boot.img not Found!!
echo Check that you have unzipped the 
echo whole Tool Package
pause
goto end
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:error2
echo Recovery.img not Found!!
echo Check that you have unzipped the 
echo whole Tool Package
pause
goto end
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:error3
echo File not Found!!
echo Check that you have unzipped the 
echo whole Tool Package
pause
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:end
echo(
del "%~dp0\working\*.txt"
PING -n 1 127.0.0.1>nul
