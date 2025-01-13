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

// Function to handle application launch
fn void applicationDidFinishLaunching(AppDelegate* delegate, void* notification) {
    io::printn("Application has launched!");
}

// Function to create and initialize delegate
fn AppDelegate createAppDelegate() {
    AppDelegate delegate = {null};
    return delegate;
}

// Main function
fn void main() {
    io::printn("main function has launched!");

    // Initialize the Objective-C runtime
    objc_runtime::initializeObjectiveCRuntime();

    // Get shared application instance
    void* app = objc_runtime::nsApp_sharedApplication();
    if (app == null) {
        io::printn("Failed to get shared application!");
        return;
    }

    // Create an instance of AppDelegate
    AppDelegate delegate = createAppDelegate();
    void* delegateClass = objc_runtime::objc_GetClass(objc_runtime::nsApplicationDelegateClassName);
    delegate.delegate_instance = objc_runtime::objc_Alloc(delegateClass);
    objc_runtime::objc_Init(delegate.delegate_instance);

    // Set the delegate for the application
    objc_runtime::objc_SetProperty(app, "delegate", delegate.delegate_instance);

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

    io::printfn("Using style mask: %d", window_style);//styleMask);

    void* sel = objc_runtime::sel_registerName("initWithContentRect:styleMask:backing:defer:");
    ((CallInit)&objc_runtime::objc_msgSend)(window, sel, windowRect, (int)window_style, (int)backing_store, (char)false);

    // Set window title using NSString
    //objc_runtime::objc_SendMsg1(window, "setTitle:", titleStr);

    // Show the window
    objc_runtime::objc_SendMsg1(window, "makeKeyAndOrderFront:", null);
 
    // Activate the application
    objc_runtime::objc_SendMsg1(app, "activateIgnoringOtherApps:", (void*)1);

    io::printn("About to run the application!");
    // Run the application
    objc_runtime::objc_SendMsg0(app, "run");
    io::printn("main function after run, ending!");
}
