# Klipper Controler
Simple software to control a 3D printer controlled with Klipper software.

I am using an "Ender3 PRO" 3D printer controlled from a Raspberry PI2 via Klipper software (see https://www.klipper3d.org/).
PI2 is not powerful enough to handle octoprint well in the printer room and I don't have access to a computer so editing the klipper.cfg configuration file is problematic.

I decided to write my own software to control the printer. This software is divided into 2 parts:

* A server written in C that runs on a raspberry PI2 (RPC).

* Software written in flutter for an Android/iOS cell phone to control the 3D printer.

NOTE: The project is not yet finished. Still working on it.

![alt tag](https://github.com/BubuHub/KlipperController/blob/main/blob/assets/main_screen.jpg)

# Building server on PI
* install git and gcc compiler on pi (sudo apt install git gcc)
* log in to PI
* git clone https://github.com/BubuHub/KlipperController.git
* cd KlipperController/print-server-c
* make
* sudo make install
* edit configuration file in /etc/default/print-server
type:
  sudo systemctl stop print-server
  sudo mcedit /etc/default/print-server
change paths:
UPLOAD_DIR= - type path tu virtual SD card (as configured in klipper.cfg)
KLIPPER_CFG= - type path to klipper config file
KLIPPER_LOG= - type path to klipper log file
  save (F2) and exit (F10)
  sudo systemctl start print-server

# Building application for Android/iOS
* install flutter - follow instrictions from https://flutter.dev/docs/get-started/install
* git clone https://github.com/BubuHub/KlipperController.git
* cd myocto
* flutter pub get
* flutter build apk --split-per-abi

<div>Icons made by <a href="https://www.freepik.com" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a></div>


Enjoy :-)
