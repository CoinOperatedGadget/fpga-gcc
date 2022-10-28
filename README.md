# fpga-gcc
A FPGA Powered Gamecube Controller

This project is about using an FPGA in order to create a gamecube controller.  Most commonly microcontrollers are currently used for this purpose, so why use and FPGA?  Well there isn't a good reason other than I thought it would be a fun weekend project.  

I ended up building up a full controller:
![Controller Version 1](/images/ControllerV1.jpg)

## Features
- WASD style directional input on the left with 3 modifier keys, one for pinky use, 2 for thumb use
- Dedicated start button
- 8 button right cluster
- 5 button cluster for right thumb
- Per key addressable RGB
- Hot swap Mx style switches

The controller utilizes a Sipeed Tang Nano 4K board for control.  The top level for the instantiation can be found in the directory of the same name. 

GCC emulator code based on information found here:
- https://simplecontrollers.bigcartel.com/gamecube-protocol
- http://www.int03.co.uk/crema/hardware/gamecube/gc-control.html
