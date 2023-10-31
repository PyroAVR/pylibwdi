# pylibwdi

`pylibwdi` is a basic Python wrapper around the core APIs of
[libwdi](https://github.com/pbatard/libwdi). It provides Python versions of the
following types:

 - `wdi_create_list_options` as `WDICreateListOptions`
 - `wdi_device_info` as `DeviceList` and `WDIDeviceInfo`
 - `wdi_driver_type` as `WDIDriverType`
 - `wdi_install_driver_options` as `WDIInstallDriverOptions`
 - `wdi_prepare_driver_options` as `WDIPrepareDriverOptions`

It also exposes the two critical functions necessary to perform a driver
install:

 - `wdi_install_driver`
 - `wdi_prepare_driver`


See `libwdi-simple` inside the `libwdi` project for how to use these functions.

If you only need to install a driver on a single machine, **this library is not
necessary**. Use Zadig, libwdi's default graphical interface for driver
installation, which is correctly configured. This library is only useful if
you are developing a Python application, which must run on Windows, and which
needs to change the driver associated with a USB device in order to operate
correctly.

## Installation from source

`pylibwdi` is built using meson-python, which
handles cython, python packaging, etc. MSVC redistributables and drivers are
not able to be included in this repository nor automatically downloaded - these
files will need to be provided at compile time via meson options. See file
`meson_options.txt` in [libwdi-meson](https://github.com/pyroavr/libwdi-meson)
for details. Arguments to `meson setup` should be placed in `pyproject.toml` so
that they are recognized by `meson-python` during installation.

`pylibwdi` uses `WinUSB` by default. To usb `libusbK` or `libusb0-win32`, edit
`pyproject.toml`, remove the line with `-Dlibwdi:winusb_path=...` and replace
it with `-Dlibwdi:libusb0_path`, etc.

### WDK / WinUSB

`WinUSB` is installed by default on Windows 10 and onward, so installation is
not strictly required. However, devices which have a default driver will need
to have their default driver de-associated, and have `WinUSB` associated as the
primary driver for the device. `libwdi` is structured such that the driver
files must be present - this is due to driver signing support. Therefore, the
actual driver files from WDK 8 are necessary. The WDK files can be obtained
directly from
[Microsoft](https://learn.microsoft.com/en-us/windows-hardware/drivers/other-wdk-downloads).

WDK 8 downloads as a setup exe, and by default it will install to:

        `C:\Program Files (x86)\Windows Kits\8.0`.

`pylibwdi` is preconfigured to search in this
location. If for some reason the files are located elsewhere (eg. in the case
of a cross-compile), edit `pyproject.toml` in section `tool.meson-python.args`
to have the correct path.

#### 32-bit builds

32 bit builds are entirely untested at this time. If you discover a bug, please
see the section "Filing bugs".

## Installation from PyPI:

TODO no wheel packages yet :(


## Filing bugs

If you discover a build or runtime problem that exists in
pylibwdi, **which you cannot reproduce with Zadig or libwdi-simple**, please
open a GitHub issue. Be sure to include all available environment information.
Strip any PII or corporate information from any logs, and if possible please
provide an MWE Python program which reproduces the issue in your environment.

## Tests

The provided tests serve only to check configuration of the python
bindings (`test/enumeration.py`) and which drivers are packaged in the wheel
(`test/driver_packaging.py`).

### `test/enumeration.py

Run this to check:
 - Python functions are able to call the libwdi C functions
 - USB devices can be seen by libwdi.

The test simply prints a list of connected USB devices when operating
correctly. Otherwise a traceback with more information will be provided.

### `test/driver_packaging.py`

Run this to check:
 - Which drivers are embedded into the wheel
 - Whether drivers can be unpacked successfully

A USB device's VID and PID must be provided to this test, as libwdi will create
INF files for driver installation based on it.

        `python test\driver_packaging.py -v <vid> -p <pid>`

Note that the configuration error messages printed from this test are both
**expected** and **speculative**. Libwdi does not directly expose a method to
determine which drivers are embedded, and in the spirit of minimally wrapping
the API, these bindings do not attempt to add that feature. Only a keyword
search is performed on the extracted files to check if there are matches for
drivers other than the intended one.

## Notes

### FTDI

`libwdi` directly recommends that composite devices not be the target
of driver installation and association, and this is normally a good idea.

However, for FTDI devices which have more than one COM port, they will
enumerate as a single composite device with two interfaces. FTDI's VCP driver
is bound to both interfaces, not the composite parent. In order to communicate
with the FTDI device without VCP interfereing, and to have it show up as "one
FTDI device with multiple interfaces", as is required for some programs, **the
driver must be associated with the composite parent**. This applies to devices
such as FT2232xx, but not necessarily FT232xx.
