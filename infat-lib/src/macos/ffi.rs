// infat-lib/src/macos/ffi.rs
//! Raw FFI bindings to macOS Launch Services and related APIs

use core_foundation::{
    array::CFArrayRef,
    base::OSStatus,
    string::CFStringRef,
    url::CFURLRef,
};

pub type LSRolesMask = u32;
pub const K_LS_ROLES_VIEWER: LSRolesMask = 2;
pub const K_LS_ROLES_ALL: LSRolesMask = 0xFFFFFFFF;

// Launch Services error codes
pub const K_LS_APPLICATION_NOT_FOUND_ERR: OSStatus = -10814;
pub const K_LS_UNKNOWN_ERR: OSStatus = -10810;

#[link(name = "CoreServices", kind = "framework")]
extern "C" {
    pub fn LSSetDefaultHandlerForURLScheme(
        inURLScheme: CFStringRef,
        inHandlerBundleID: CFStringRef,
    ) -> OSStatus;

    pub fn LSSetDefaultRoleHandlerForContentType(
        inContentType: CFStringRef,
        inRole: LSRolesMask,
        inHandlerBundleID: CFStringRef,
    ) -> OSStatus;

    pub fn LSCopyDefaultHandlerForURLScheme(inURLScheme: CFStringRef) -> CFStringRef;

    pub fn LSCopyDefaultRoleHandlerForContentType(
        inContentType: CFStringRef,
        inRole: LSRolesMask,
    ) -> CFStringRef;

    pub fn LSCopyAllHandlersForURLScheme(inURLScheme: CFStringRef) -> CFArrayRef;

    pub fn LSCopyAllRoleHandlersForContentType(
        inContentType: CFStringRef,
        inRole: LSRolesMask,
    ) -> CFArrayRef;

    pub fn LSRegisterURL(inURL: CFURLRef, inUpdate: bool) -> OSStatus;

    pub fn UTTypeCreatePreferredIdentifierForTag(
        inTagClass: CFStringRef,
        inTag: CFStringRef,
        inConformingToUTI: CFStringRef,
    ) -> CFStringRef;

    pub fn UTTypeCopyPreferredTagWithClass(
        inUTI: CFStringRef,
        inTagClass: CFStringRef,
    ) -> CFStringRef;
}

// UTI tag classes
pub const K_UT_TAG_CLASS_FILENAME_EXTENSION: &str = "public.filename-extension";
pub const K_UT_TAG_CLASS_MIME_TYPE: &str = "public.mime-type";
