"""
Very simple "does it work?" test for the python specifics of pylibwdi
"""
import sys


def main(argv):
    try:
        import pylibwdi
    except ImportError as e:
        raise e
    
    from pylibwdi import WDICreateListOptions, DeviceList
    opts = WDICreateListOptions(True, True, True)
    devices = DeviceList(opts)

    if len(devices.device_list):
        for device in devices:
            print(f"Found USB Device with VID:PID {device.vid}:{device.pid}\n\t{device.description}\n")
    else:
        print("No USB devices enumerated through libwdi. This is very likely a configuration issue in libwdi, check options in pyproject.toml.")
        exit(-1)


    print("All enumeration tests complete. This does not imply that driver packaging + install is working, please test installation locally before deploying.")


if __name__ == '__main__':
    sys.exit(main(sys.argv))
