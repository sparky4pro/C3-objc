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

// Constants for delegate selectors
const char* APPLICATION_SHOULD_TERMINATE_AFTER_LAST_WINDOW_CLOSED_SEL = "applicationShouldTerminateAfterLastWindowClosed:";
const char* APPLICATION_DID_FINISH_LAUNCHING_SEL = "applicationDidFinishLaunching:";

// Structure for method definition
struct Method {
    char* name;
    char* types;
    void* imp;
}

// External function declarations
extern fn void* objc_getClass(char* className);
extern fn void* sel_registerName(char* selectorName);
extern fn void* objc_msgSend(void* receiver, void* selector, ...);
extern fn void* objc_msgSend_stret(void* ret, void* receiver, void* selector, ...);

// External function declarations for class and protocol handling
extern fn void* objc_allocateClassPair(void* superclass, char* name, ulong extraBytes);
extern fn void objc_registerClassPair(void* cls);
extern fn bool class_addMethod(void* cls, void* name, void* imp, char* types);
extern fn void* objc_getProtocol(char* name);
extern fn bool class_addProtocol(void* cls, void* protocol);

// External function declarations for memory management
extern fn void* objc_retain(void* obj);
extern fn void objc_release(void* obj);

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

// Function types for different message patterns
def MsgSend = fn void*(void*, void*);
def MsgSend1 = fn void*(void*, void*, void*);
def MsgSendBool = fn bool(void*, void*, void*);
def MsgSendRetain = fn void*(void*, void*, void*);

fn void* objc_SendMsg(void* receiver, char* selector) {
    if (receiver == null) return null;
    void* sel = sel_registerName(selector);
    return ((MsgSend)&objc_msgSend)(receiver, sel);
}

fn void* objc_SendMsg1(void* receiver, char* selector, void* arg1) {
    if (receiver == null) return null;
    void* sel = sel_registerName(selector);
    return ((MsgSend1)&objc_msgSend)(receiver, sel, arg1);
}

fn void objc_SetProperty(void* instance, char* propertyName, void* value) {
    if (instance == null) return;
    // First retain the new value
    if (value != null) objc_retain(value);
    
    // Set the property
    void* selector = sel_registerName(propertyName);
    ((MsgSend1)&objc_msgSend)(instance, selector, value);
}

// Helper function to set delegate with proper retain
fn void setAppDelegate(void* app, void* delegate) {
    if (app == null || delegate == null) return;
    void* sel = sel_registerName("setDelegate:");
    ((MsgSend1)&objc_msgSend)(app, sel, delegate);
    // Retain the delegate to keep it alive
    objc_retain(delegate);
}

// Helper function to create NSString from C string
fn void* createNSString(char* str) {
    void* nsStringClass = objc_GetClass("NSString");
    if (nsStringClass == null) return null;
    
    void* sel = sel_registerName("stringWithUTF8String:");
    return ((MsgSendRetain)&objc_msgSend)(nsStringClass, sel, str);
}

// Helper function to create autorelease pool
fn void* createAutoreleasePool() {
    void* poolClass = objc_GetClass("NSAutoreleasePool");
    if (poolClass == null) { return null; }

    void* pool = objc_Alloc(poolClass);
    return objc_Init(pool);
}

// Helper function to register a new class with the runtime
fn bool registerDelegateClass(char* className, Method* methods, int methodCount) {
    void* superClass = objc_GetClass("NSObject");
    if (superClass == null) return false;
    
    void* newClass = objc_allocateClassPair(superClass, className, 0);
    if (newClass == null) return false;
    
    // Add NSApplicationDelegate protocol
    void* appDelegateProtocol = objc_getProtocol("NSApplicationDelegate");
    if (appDelegateProtocol != null) {
        class_addProtocol(newClass, appDelegateProtocol);
    }
    
    for (int i = 0; i < methodCount; i++) {
        void* selector = sel_registerName(methods[i].name);
        if (!class_addMethod(newClass, selector, methods[i].imp, methods[i].types)) {
            io::printfn("Failed to add method: %s", methods[i].name);
            return false;
        }
    }
    
    objc_registerClassPair(newClass);
    return true;
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
