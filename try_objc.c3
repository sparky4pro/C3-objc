// try_objc.c3
module try_objc;

import std::io;
import objc_runtime;

// Define nil
//const void* NIL = null;

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
/*
// Define rect structure for window initialization
struct NSRect {
    double x;      // Changed to double for CGFloat compatibility
    double y;
    double width;
    double height;
}
*/
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
    //NSRect windowRect = {100.0, 100.0, 400.0, 300.0};

    // Main window creation part
    NSRect windowRect;
    windowRect.origin = NSPoint{200.0, 200.0};
    windowRect.size = NSSize{400.0, 300.0};

    // Create window with proper style mask
    ulong window_style = WindowStyleMask.TITLED.val | WindowStyleMask.CLOSABLE.val |
                    WindowStyleMask.MINIATURIZABLE.val | WindowStyleMask.RESIZABLE.val;
    ulong backing_store = 2; // NSBackingStoreBuffered


    // Set up window style mask
    // Window style mask constants
    //const int NSWINDOW_STYLE_MASK_BORDERLESS     = 0;
    //const int NSWINDOW_STYLE_MASK_TITLED         = 1;
    //const int NSWINDOW_STYLE_MASK_CLOSABLE       = 2;
    //const int NSWINDOW_STYLE_MASK_MINIATURIZABLE = 4;
    //const int NSWINDOW_STYLE_MASK_RESIZABLE      = 8;

    //long styleMask = (NSWINDOW_STYLE_MASK_TITLED | NSWINDOW_STYLE_MASK_CLOSABLE | NSWINDOW_STYLE_MASK_MINIATURIZABLE | NSWINDOW_STYLE_MASK_RESIZABLE);
    //ulong styleMask = WindowStyleMask.CLOSABLE.val | WindowStyleMask.MINIATURIZABLE.val | WindowStyleMask.TITLED.val | WindowStyleMask.RESIZABLE.val;

    // Create a window
//    void* windowClass = objc_runtime::objc_GetClass(objc_runtime::nsWindowClassName);
//    void* window = objc_runtime::objc_Alloc(windowClass);

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

//    int styleMask = NSWindowStyle.TITLED | NSWindowStyle.CLOSABLE |
//                NSWindowStyle.MINIATURIZABLE | NSWindowStyle.RESIZABLE;

    // Initialize with borderless style
    //int styleMask = NSWINDOW_STYLE_MASK_BORDERLESS;
    io::printfn("Using style mask: %d", window_style);//styleMask);
/*
    objc_runtime::objc_SendMsg4(window, "initWithContentRect:styleMask:backing:defer:",
    //objc_runtime::objc_SendMsg(window, "initWithContentRect:styleMask:backing:defer:",
        &windowRect,
        (void*)(ulong)styleMask,  // Cast to void* after ulong
        (void*)(ulong)2,          // NSBackingStoreBuffered
        (void*)(ulong)0);         // Don't defer
*/
    objc_runtime::objc_SendMsg4(window, "initWithContentRect:styleMask:backing:defer:",
        &windowRect,
        (void*)window_style,    // Pass style directly
        (void*)backing_store,   // Pass backing store directly
        (void*)0);              // Don't defer

    // Initialize window with correct parameters
//    objc_runtime::objc_SendMsg4(window, "initWithContentRect:styleMask:backing:defer:", &windowRect, (void*)styleMask, (void*)2, (void*)0);

    // Create an NSString for the title
//    void* nsStringClass = objc_runtime::objc_GetClass("NSString");
//    void* titleStr = objc_runtime::objc_SendMsg1(nsStringClass, "stringWithUTF8String:", "C3 Window");
/*
    void* titleStr = objc_runtime::createNSString("C3 Window");

    if (titleStr == null) {
        io::printn("Failed to create window title string");
        return;
    }
*/
    // Set window title using NSString
    //objc_runtime::objc_SendMsg1(window, "setTitle:", titleStr);

    // Show the window
    objc_runtime::objc_SendMsg1(window, "makeKeyAndOrderFront:", null);
    objc_runtime::objc_SendMsg1(window, "show:", null);

    // Activate the application
    objc_runtime::objc_SendMsg1(app, "activateIgnoringOtherApps:", (void*)1);

    io::printn("About to run the application!");
    // Run the application
    objc_runtime::objc_SendMsg0(app, "run");
    io::printn("main function after run, ending!");
}
