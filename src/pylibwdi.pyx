# do not change this. cython depfile generation does not work with a full import.
# instead, tell cython to search next to this file with a -I option.
# without the pxd listed in the depfile, a build system without cython knowledge 
cimport libwdi
import cython
from cython.cimports.libc.stdlib cimport malloc, free
from typing import Optional
from tempfile import TemporaryDirectory
from enum import IntEnum

cdef safe_decode(buf: cython.pointer(cython.char), enc='utf-8'):
    return buf.decode(enc) if buf != cython.NULL else None

class WDIDriverType(IntEnum):
    WDI_WINUSB = libwdi.wdi_driver_type.WDI_WINUSB
    WDI_LIBUSB0 = libwdi.wdi_driver_type.WDI_LIBUSB0
    WDI_LIBUSBK = libwdi.wdi_driver_type.WDI_LIBUSBK
    WDI_CDC = libwdi.wdi_driver_type.WDI_CDC
    WDI_USER = libwdi.wdi_driver_type.WDI_USER
    WDI_NB_DRIVERS = libwdi.wdi_driver_type.WDI_NB_DRIVERS	# Total number of drivers in the enum

@cython.cclass
class WDICreateListOptions:
    _self: cython.pointer(libwdi.wdi_options_create_list)

    def __cinit__(self):
        self._self = cython.cast(cython.pointer(libwdi.wdi_options_create_list), malloc(cython.sizeof(libwdi.wdi_options_create_list)))
        if not self._self:
            raise MemoryError()

    def __dealloc__(self):
        if self._self:
            free(self._self)

    def __init__(self, list_all = False, list_hubs = False, trim_whitespace = True):
        self._self.list_all = list_all
        self._self.list_hubs = list_hubs
        self._self.trim_whitespaces = trim_whitespace


@cython.cclass
class WDIPrepareDriverOptions:
    _self: cython.pointer(libwdi.wdi_options_prepare_driver)

    def __cinit__(self):
        self._self = cython.cast(cython.pointer(libwdi.wdi_options_prepare_driver), malloc(cython.sizeof(libwdi.wdi_options_prepare_driver)))
        if not self._self:
            raise MemoryError()

    def __dealloc__(self):
        if self._self:
            free(self._self)

    def __init__(self, driver_type, vendor_name = "Generic USB Device", device_guid = None, disable_cat = False, disable_signing = False, cert_subject = None, use_wcid_driver = False, external_inf = False):
        # no match statement in cython >:(
        if not isinstance(vendor_name, (bytes, bytearray)):
            # ensure a reference is kept to the encoded result
            v = vendor_name.encode('utf-8')
            self._self.vendor_name = v

        else:
            self._self.vendor_name = vendor_name

        if not device_guid:
            self._self.device_guid = cython.NULL
        
        elif not isinstance(device_guid, (bytes, bytearray)):
            v = device_guid.encode('utf-8')
            self._self.device_guid = v

        else:
            self._self.device_guid = device_guid

        if not cert_subject:
            self._self.cert_subject = cython.NULL

        elif not isinstance(cert_subject, (bytes, bytearray)):
            v = cert_subject.encode('utf-8')
            self._self.cert_subject = v

        else:
            self._self.cert_subject = cert_subject

        self._self.driver_type = driver_type
        self._self.disable_cat = disable_cat
        self._self.disable_signing = disable_signing
        self._self.use_wcid_driver = use_wcid_driver
        self._self.external_inf = external_inf


@cython.cclass
class WDIInstallDriverOptions:
    _self: cython.pointer(libwdi.wdi_options_install_driver)

    def __cinit__(self):
        self._self = cython.cast(cython.pointer(libwdi.wdi_options_install_driver), malloc(cython.sizeof(libwdi.wdi_options_install_driver)))
        if not self._self:
            raise MemoryError()

    def __dealloc__(self):
        if self._self:
            free(self._self)

    def __init__(self, hwnd = None, install_filter_driver = False, pending_install_timeout = 120):
        if hwnd:
            self._self.hWnd = cython.cast(cython.pointer(void), hwnd)

        else:
            self._self.hWnd = cython.NULL

        self._self.install_filter_driver = install_filter_driver
        self._self.pending_install_timeout = pending_install_timeout


@cython.cclass
class WDIDeviceInfo:
    _self: cython.pointer(libwdi.wdi_device_info)

    def __init__(self):
        raise Exception("do not instantiate WDIDeviceInfo, obtain from DeviceList")

    @staticmethod
    @cython.cfunc
    def from_ptr(other: cython.pointer(libwdi.wdi_device_info)):
        r: WDIDeviceInfo = WDIDeviceInfo.__new__(WDIDeviceInfo)
        r._self = other
        return r

    @property
    def vid(self):
        return self._self.vid
    
    @property
    def pid(self):
        return self._self.pid
    
    @property
    def description(self):
        return safe_decode(self._self.desc, 'utf-8')

    @property
    def is_composite(self):
        return self._self.is_composite

    @property
    def device_id(self):
        return safe_decode(self._self.device_id, 'utf-8')
    
    @property
    def hardware_id(self):
        return self._self.hardware_id

#     @property
#     def parent_id(self):
#         return safe_decode(self._self.parent_id, 'utf-8')


# TODO: does this actually need to be a cclass? We don't need to pass this to C or call its methods from C.
@cython.cclass
class DeviceList:
    _start: cython.pointer(libwdi.wdi_device_info)
    __dict__: dict

    def __init__(self, options: WDICreateListOptions = None):
        ...
        if options is not None:
            status = libwdi.wdi_create_list(&self._start, options._self)
        else:
            status = libwdi.wdi_create_list(&self._start, cython.NULL)

        if status != libwdi.wdi_error.WDI_SUCCESS:
            raise Exception(libwdi.wdi_strerror(status).decode('utf-8'))
        
        ptr = self._start
        self.device_list = list()
        while ptr != cython.NULL:
            self.device_list.append(WDIDeviceInfo.from_ptr(ptr))
            ptr = ptr.next

    def __dealloc__(self):
        if self._start is not cython.NULL:
            libwdi.wdi_destroy_list(self._start)


    def __iter__(self):
        return iter(self.device_list)


def wdi_prepare_driver(device: WDIDeviceInfo, where: str, name: str, options: WDIPrepareDriverOptions = None) -> int:
        status = libwdi.wdi_prepare_driver(device._self, where.encode('utf-8'), name.encode('utf-8'), options._self if options else cython.NULL)
        if status != libwdi.wdi_error.WDI_SUCCESS:
            raise Exception(libwdi.wdi_strerror(status).decode('utf-8'))
        
        return True


def wdi_install_driver(device: WDIDeviceInfo, where: str, name: str, options: WDIInstallDriverOptions = None):
    status = libwdi.wdi_install_driver(device._self, where.encode('utf-8'), name.encode('utf-8'), options._self if options else cython.NULL)
    if status != libwdi.wdi_error.WDI_SUCCESS:
        raise Exception(libwdi.wdi_strerror(status).decode('utf-8'))
    
    return True
