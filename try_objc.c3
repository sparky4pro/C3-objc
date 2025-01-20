// try_objc.c3
// compile with:
// c3c compile --target macos-aarch64 try_objc.c3 objc_runtime.c3
module try_objc;

import std::io;
import std::os::macos::objc;
import objc_runtime;

// One cannot just call msgSend...
// Need to make a function prototype:
def CallInit = fn void(void*, void*, NSRect, int, int, char);

enum WindowStyleMask : (ulong val)
{
    BORDERLESS                = 0,
    TITLED                    = 1 << 0,
    CLOSABLE                  = 1 << 1,
	MINIATURIZABLE            = 1 << 2,
	RESIZABLE                 = 1 << 3,
	TEXTURED_BACKGROUND       = 1 << 8,
	UNIFIED_TITLE_AND_TOOLBAR = 1 << 12,
	FULL_SCREEN               = 1 << 14,
	FULL_SIZE_CONTENT_VIEW    = 1 << 15,
	UTILITY_WINDOW            = 1 << 4,
	DOC_MODAL_WINDOW          = 1 << 6,
	NONACTIVATING_PANEL       = 1 << 7,
	HUD_WINDOW                = 1 << 13
}

// Define rect structure for window initialization
struct NSRect {
    NSPoint origin;
    NSSize size;
}

struct NSPoint {
    double x;
    double y;
}

struct NSSize {
    double width;
    double height;
}

// Delegate structure and functions to handle application events
struct AppDelegate {
    void* delegate_instance;
}

// Function types for delegate methods
def AppShouldTerminate = fn char(void*, void*, void*);
def AppDidFinishLaunching = fn void(void*, void*, void*);

// Delegate method implementations
fn char appDelegate_applicationShouldTerminateAfterLastWindowClosed(void* self, void* sel, void* app) {
    io::printn("Window closed - should terminate app");
    return 1;  // YES in Objective-C
}

fn void appDelegate_applicationDidFinishLaunching(void* self, void* sel, void* notification) {
    io::printn("Application launched successfully!");
}

// Function to create and initialize delegate
fn void* createAppDelegate() {
    // Define our delegate methods
    Method[2] methods;
    methods[0] = Method {
        .name = objc_runtime::APPLICATION_SHOULD_TERMINATE_AFTER_LAST_WINDOW_CLOSED_SEL,
        .types = "c@:@",  // BOOL (id self, SEL _cmd, id app)
        .imp = &appDelegate_applicationShouldTerminateAfterLastWindowClosed
    };
    methods[1] = Method {
        .name = objc_runtime::APPLICATION_DID_FINISH_LAUNCHING_SEL,
        .types = "v@:@",  // void (id self, SEL _cmd, id notification)
        .imp = &appDelegate_applicationDidFinishLaunching
    };

    // Register our custom delegate class
    char* delegateClassName = "CustomAppDelegate";
    if (!objc_runtime::registerDelegateClass(delegateClassName, &methods[0], 2)) {
        io::printn("Failed to register delegate class!");
        return null;
    }

    // Create an instance of our delegate
    void* delegateClass = objc_runtime::objc_GetClass(delegateClassName);
    if (delegateClass == null) {
        io::printn("Failed to get delegate class!");
        return null;
    }

    void* delegate = objc_runtime::objc_Alloc(delegateClass);
    return objc_runtime::objc_Init(delegate);
}

// Main function
fn void main() {
    io::printn("main function has launched!");

    // Initialize the Objective-C runtime
    if (objc_runtime::initializeObjectiveCRuntime() != objc_runtime::OBJC_RUNTIME_SUCCESS) {
        io::printn("Failed to initialize Objective-C runtime!");
        return;
    }

    // Create an autorelease pool
    void* pool = objc_runtime::createAutoreleasePool();
    if (pool == null) {
        io::printn("Failed to create autorelease pool!");
        return;
    }

    // Get shared application instance
    void* app = objc_runtime::nsApp_sharedApplication();
    if (app == null) {
        io::printn("Failed to create shared application!");
        return;
    }

    // Create an instance of AppDelegate
    void* delegate = createAppDelegate();
    if (delegate == null) {
        io::printn("Failed to create delegate!");
        return;
    }

    // Set the delegate for the application using our helper function
    objc_runtime::setAppDelegate(app, delegate);
    
    // Make sure the application is activated
    objc_runtime::objc_SendMsg1(app, "activateIgnoringOtherApps:", (void*)1);

    // Create window rect (using CGFloat compatible values)
    NSRect windowRect;
    windowRect.origin = NSPoint{200.0, 200.0};
    windowRect.size   = NSSize{400.0, 300.0};

    // Create window with proper style mask
    ulong window_style = WindowStyleMask.TITLED.val | WindowStyleMask.CLOSABLE.val |
                    WindowStyleMask.MINIATURIZABLE.val | WindowStyleMask.RESIZABLE.val;
    ulong backing_store = 2; // NSBackingStoreBuffered

    // Create a window with basic style
    void* windowClass = objc_runtime::objc_GetClass(objc_runtime::nsWindowClassName);
    if (windowClass == null) {
        io::printn("Failed to get NSWindow class");
        return;
    }

    // Create with borderless style first
    void* window = objc_runtime::objc_Alloc(windowClass);
    if (window == null) {
        io::printn("Failed to allocate window");
        return;
    }

    io::printfn("Using style mask: %d", window_style);

    void* sel = objc_runtime::sel_registerName("initWithContentRect:styleMask:backing:defer:");
    ((CallInit)&objc_runtime::objc_msgSend)(window, sel, windowRect, (int)window_style, (int)backing_store, (char)false);

    // Create window title
    void* titleStr = objc_runtime::createNSString("C3 Window");
    if (titleStr == null) {
        io::printn("Failed to create window title!");
        return;
    }
    
    // Set window title
    objc_runtime::objc_SendMsg1(window, "setTitle:", titleStr);

    // Release the title string since the window retains it
    objc_runtime::objc_release(titleStr);

    // Show the window
    objc_runtime::objc_SendMsg1(window, "makeKeyAndOrderFront:", null);

    io::printn("About to run the application!");
    // Run the application
    objc_runtime::objc_SendMsg(app, "run");
    io::printn("main function after run, ending!");

    // Clean up
    if (pool != null) {
        objc_runtime::objc_release(pool);
    }
}
