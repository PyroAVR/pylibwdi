from libc.stdint cimport uint32_t

cdef extern from "Windows.h":
    ctypedef void* HWND

cdef extern from "libwdi.h":
    cdef struct wdi_device_info:
        wdi_device_info *next
        unsigned short vid
        unsigned short pid
        bint is_composite
        unsigned char mi
        char *desc
        char *driver
        char *device_id
        char *hardware_id
        char *compatible_id
        char *upper_filter
        #char *parent_id
        long unsigned int driver_version

    cdef struct wdi_options_prepare_driver:
        wdi_driver_type driver_type
        char *vendor_name
        char *device_guid
        bint disable_cat
        bint disable_signing
        char *cert_subject
        bint use_wcid_driver
        bint external_inf

    cdef struct wdi_options_install_driver:
        HWND hWnd
        bint install_filter_driver
        uint32_t pending_install_timeout

    cdef struct wdi_options_create_list:
        bint list_all
        bint list_hubs
        bint trim_whitespaces

    cdef enum wdi_error:
        #  Success (no error) 
        WDI_SUCCESS = 0,

        #  Input/output error 
        WDI_ERROR_IO = -1,

        #  Invalid parameter 
        WDI_ERROR_INVALID_PARAM = -2,

        #  Access denied (insufficient permissions) 
        WDI_ERROR_ACCESS = -3,

        #  No such device (it may have been disconnected) 
        WDI_ERROR_NO_DEVICE = -4,

        #  Entity not found 
        WDI_ERROR_NOT_FOUND = -5,

        #  Resource busy, or API call already running 
        WDI_ERROR_BUSY = -6,

        #  Operation timed out 
        WDI_ERROR_TIMEOUT = -7,

        #  Overflow 
        WDI_ERROR_OVERFLOW = -8,

        #  Another installation is pending 
        WDI_ERROR_PENDING_INSTALLATION = -9,

        #  System call interrupted (perhaps due to signal) 
        WDI_ERROR_INTERRUPTED = -10,

        #  Could not acquire resource (Insufficient memory, etc) 
        WDI_ERROR_RESOURCE = -11,

        #  Operation not supported or unimplemented on this platform 
        WDI_ERROR_NOT_SUPPORTED = -12,

        #  Entity already exists 
        WDI_ERROR_EXISTS = -13,

        #  Cancelled by user 
        WDI_ERROR_USER_CANCEL = -14,

        #  Couldn't run installer with required privileges 
        WDI_ERROR_NEEDS_ADMIN = -15,

        #  Attempted to run the 32 bit installer on 64 bit 
        WDI_ERROR_WOW64 = -16,

        #  Bad inf syntax 
        WDI_ERROR_INF_SYNTAX = -17,

        #  Missing cat file 
        WDI_ERROR_CAT_MISSING = -18,

        #  System policy prevents the installation of unsigned drivers 
        WDI_ERROR_UNSIGNED = -19,

        #  Other error 
        WDI_ERROR_OTHER = -99

    cdef enum wdi_driver_type:
        WDI_WINUSB
        WDI_LIBUSB0
        WDI_LIBUSBK
        WDI_CDC
        WDI_USER
        WDI_NB_DRIVERS	# Total number of drivers in the enum

    wdi_error wdi_create_list(wdi_device_info **lst, wdi_options_create_list *options)
    wdi_error wdi_destroy_list(wdi_device_info *lst)
    const char *wdi_strerror(wdi_error errcode)
    wdi_error wdi_prepare_driver(wdi_device_info* device_info, const char* path,
                                      const char* inf_name, wdi_options_prepare_driver* options)

    wdi_error wdi_install_driver(wdi_device_info* device_info, const char* path,
                                      const char* inf_name, wdi_options_install_driver* options)
