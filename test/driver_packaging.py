"""
Check what drivers are bundled
"""
import sys
import os
import tempfile
import traceback
import argparse



def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("-v", "--vid", help="vendor id", type=str, required=True)
    ap.add_argument("-p", "--pid", help="product id", type=str, required=True)

    args, extras = ap.parse_known_args(argv)

    vid = int(args.vid[2:], base=16) if args.vid.startswith('0x') else int(args.vid)
    pid = int(args.pid[2:], base=16) if args.pid.startswith('0x') else int(args.pid)

    try:
        import pylibwdi
    except ImportError as e:
        raise e
    
    from pylibwdi import DeviceList, WDICreateListOptions, wdi_prepare_driver, WDIDriverType, WDIPrepareDriverOptions

    devices = DeviceList(WDICreateListOptions(True, False, True))
    sample_device = None
    for device in devices:
        if device.vid == vid and device.pid == pid:
            sample_device = device
            break

    if sample_device is None:
        print(f"Could not locate a device to prepare a driver for with parameters {vid}:{pid}")
        exit(-1)

    name_tbl = {
        WDIDriverType.WDI_LIBUSB0: "libusb0",
        WDIDriverType.WDI_LIBUSBK: "libusbk",
        WDIDriverType.WDI_WINUSB: "winusb",
        WDIDriverType.WDI_CDC: "usbser.sys",
        WDIDriverType.WDI_USER: "",
    }
    all_keys = set(name_tbl.keys())

    any_install_errors = False

    for dtype in all_keys:
        dopt = WDIPrepareDriverOptions(
            dtype,
            "Pylibwdi test device",
            disable_signing=True,
        )
        with tempfile.TemporaryDirectory() as td:
            try:
                wdi_prepare_driver(sample_device, td, "usb_device.inf", dopt)
                # ~~ win b  l  o   w   s ~~
                with open(os.path.join(td, "usb_device.inf"), 'r', encoding='utf-16') as f:
                    if dtype == WDIDriverType.WDI_USER:
                        other_keywords = {name_tbl[x] for x in all_keys}
                    else:
                        other_keywords = {name_tbl[x] for x in all_keys - {dtype} - {WDIDriverType.WDI_USER}}

                    inf_contents = f.read()
                    inf_contents = inf_contents.lower()
                    if any(map(inf_contents.__contains__, other_keywords)):
                        any_install_errors = True
                        if dtype == WDIDriverType.WDI_USER:
                            print(f"Keywords for standard drivers found while attempting to prepare a custom driver. A custom driver is not bundled or may be incorrectly bundled.")
                        else:
                            print(f"Found keywords for drivers not matching {name_tbl[dtype]}. Packaging for {name_tbl[dtype]} may be incorrect.")

            except Exception as e:
                print(f"libwdi failed to prepare driver for driver type: {name_tbl[dtype]}. Either it is not packaged, or improperly configured. Check options in pyproject.toml.")
                traceback.print_exception(e)

    if any_install_errors:
        print("""
Attempted to unpack all driver types and detected potentially missing drivers
(see messages above). This is expected behavior almost all of the time,
including the default configuration. It is only necessary to heed warnings
printed above regarding drivers which you intend to install.
""")


if __name__ == '__main__':
    sys.exit(main(sys.argv))
