# Cross-Compiler for Micropython ESP32 Firmware as a Docker Image for AMD64

## Inheritance and added packages
- Docker Image **tsle/os-ubuntu-bionic-amd64:18.04**
	- gcc
	- git
	- make
	- Python 2 + 3
	- Xtensa ESP32 Toolchain (from tarball)
	- Espressif IDF (from Github repository)
	- MicroPython (from Github repository)

## Docker Container usage

See the related GitHub repository [https://github.com/tsitle/dockercontainer-mpy-esp32-cc](https://github.com/tsitle/dockercontainer-mpy-esp32-cc)
