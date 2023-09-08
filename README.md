Important : if you intend to use this app, please first modify app settings in Garmin Connect depending on your euc.

This is a standalone application that currently only works with Begode wheels and is designed to run on a Garmin Venu.

I primarily did this for personal use (it works perfectly on my Tesla V2), please note that it should be considered as a beta as I only tested it on my wheel. I started with the Garmin WheelLog companion (developed by ggoraa) for the interface, and I coded the Bluetooth communication part (greatly simplified thanks to the developers of WheelLog, to Freestyl3r and to jim_m_58).

No public build is available yet, but you can build it using the version Garmin connect IQ sdk 4.2.4

In the current state of development, the app show the main screen when starting and automatically connect to the first unpaired begode wheel in range (no ideal in every situation, probably something I should work on at some point). Main screen currently display PWM (calculated as I have a begode that doesn't support custom firmware) on the top arc. The red zone in background correspond to PWM 80 to 100 (relatively speaking because I will add the formulas variable as app setting parameters accessible in Garmin Connect). Battery and temperature are shown on the two other arcs.

<img src="https://github.com/blkfribourg/EUC_GarminApp/blob/main/screenshot/Main.png" width="400">

Wheel settings are accessible using the menu button directly on the watch, for now calibration and speed units are missing.

<img src="https://github.com/blkfribourg/EUC_GarminApp/blob/main/screenshot/Menu.png" width="400">

When on the main screen, swiping up brings the activity recording view that allows to start recording/stoping & saving a riding session.

<img src="https://github.com/blkfribourg/EUC_GarminApp/blob/main/screenshot/ActivityRecord.png" width="400">
