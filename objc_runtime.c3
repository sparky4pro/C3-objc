// objc_runtime.c3
module objc_runtime @if(env::DARWIN) @link(env::DARWIN, "CoreFoundation.framework", "AppKit.framework", "Cocoa.framework");
import std::io;

// Constants for runtime initialization
const int OBJC_RUNTIME_SUCCESS = 0;
const int OBJC_RUNTIME_FAILURE = -1;

// Structure to hold runtime state
struct ObjCRuntimeState {
    bool initialized;
    void* autorelease_pool;
    void* main_thread;
}

// Define rect structure for window initialization
struct NSRect {
    double x;      // Changed to double for CGFloat compatibility
    double y;
    double width;
    double height;
}
NSRect heapRect = {0,0,0,0};

// Global runtime state
ObjCRuntimeState runtime_state = {false, null, null};

// Constants
char* nsApplicationClassName = "NSApplication";
char* nsWindowClassName = "NSWindow";
char* nsApplicationDelegateClassName = "NSApplicationDelegate";

// External function declarations
extern fn void* objc_getClass(char* className);
extern fn void* sel_registerName(char* selectorName);
extern fn void* objc_msgSend(void* receiver, void* selector, ...);
extern fn void* objc_msgSend_stret(void* ret, void* receiver, void* selector, ...);

fn void* objc_GetClass(char* className) {
    return objc_getClass(className);
}

fn void* objc_Alloc(void* class) {
    void* selector = sel_registerName("alloc");
    return objc_msgSend(class, selector);
}

fn void* objc_Init(void* object) {
    void* selector = sel_registerName("init");
    return objc_msgSend(object, selector);
}

// Replace the current objc_SendMsg with these specific functions:

fn void* objc_SendMsg0(void* receiver, char* selector) {
    void* sel = sel_registerName(selector);
    return objc_msgSend(receiver, sel);
}

fn void* objc_SendMsg1(void* receiver, char* selector, void* arg1) {
    void* sel = sel_registerName(selector);
    return objc_msgSend(receiver, sel, arg1);
}
/*
fn void* objc_SendMsg4(void* receiver, char* selector, void* arg1, void* arg2, void* arg3, void* arg4) {
    void* sel = sel_registerName(selector);
    if (sel == null) {
        io::printfn("Failed to register selector: %s", selector);
        return null;
    }
    // Debug print to see what's happening with the parameters
    io::printfn("Sending message: %s with args: %p, %p, %p, %p", selector, arg1, arg2, arg3, arg4);
    return objc_msgSend(receiver, sel, arg1, arg2, arg3, arg4);
}
*/
fn void* objc_SendMsg4(void* receiver, char* selector, void* arg1, void* arg2, void* arg3, void* arg4) {
    void* sel = sel_registerName(selector);
    if (sel == null) {
        io::printfn("Failed to register selector: %s", selector);
        return null;
    }
    
    // Debug print the actual values being passed
    io::printfn("Sending message: %s", selector);
    io::printfn("  arg1 (rect): %p", arg1);
    io::printfn("  arg2 (style): %d", (int)(ulong)arg2);
    io::printfn("  arg3 (backing): %d", (int)(ulong)arg3);
    io::printfn("  arg4 (defer): %d", (int)(ulong)arg4);
    
    return objc_msgSend(receiver, sel, arg1, arg2, arg3, arg4);
}

fn void objc_SetProperty(void* instance, char* propertyName, void* value) {
    void* selector = sel_registerName(propertyName);
    objc_msgSend(instance, selector, value);
}

// Helper function to create autorelease pool
fn void* createAutoreleasePool() {
    void* poolClass = objc_GetClass("NSAutoreleasePool");
    if (poolClass == null) return null;
    
    void* pool = objc_Alloc(poolClass);
    return objc_Init(pool);
}

fn int initializeObjectiveCRuntime() {
    if (runtime_state.initialized) {
        io::printn("OBJC_RUNTIME_SUCCESS");
        return OBJC_RUNTIME_SUCCESS;
    }

    runtime_state.autorelease_pool = createAutoreleasePool();
    if (runtime_state.autorelease_pool == null) {
        io::printn("OBJC_RUNTIME_FAILURE");
        return OBJC_RUNTIME_FAILURE;
    }

    runtime_state.initialized = true;
    io::printn("OBJC_RUNTIME_SUCCESS");
    return OBJC_RUNTIME_SUCCESS;
}

fn void* nsApp_sharedApplication() {
    void* appClass = objc_GetClass("NSApplication");
    void* selector = sel_registerName("sharedApplication");
    return objc_msgSend(appClass, selector);
}
/*
// Helper function to create NSString from C string
fn void* createNSString(char* cString) {
    void* nsStringClass = objc_GetClass("NSString");
    if (nsStringClass == null) {
        io::printn("Failed to get NSString class");
        return null;
    }
    void* sel = sel_registerName("stringWithCString:encoding:");
    const int NSUTF8_STRING_ENCODING = 4;
    return objc_msgSend(nsStringClass, sel, cString, (void*)NSUTF8_STRING_ENCODING);
}

*/

// Helper to determine if we need stret version
fn bool needsStret(char* selector) {
    // Add selectors that return large structs (like NSRect)
    return selector == "frame" || 
           selector == "bounds" || 
           selector == "visibleFrame";
}

fn void* objc_SendMsg(void* receiver, char* selector, void* arg1, void* arg2, void* arg3, void* arg4) {
    void* sel = sel_registerName(selector);
    if (sel == null) {
        io::printfn("Failed to register selector: %s", selector);
        return null;
    }
    
    if (needsStret(selector)) {
        // For methods returning large structs
        
        objc_msgSend_stret(&heapRect, receiver, sel, arg1, arg2, arg3, arg4);
        return &heapRect;
    } else {
        // For normal methods
        return objc_msgSend(receiver, sel, arg1, arg2, arg3, arg4);
    }
}