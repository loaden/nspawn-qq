#include <X11/Xlib.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <X11/extensions/XShm.h>

__attribute__((visibility("default"))) Bool XShmQueryExtension(
    Display *display /* dpy */
)
{
    return 0;
}

__attribute__((visibility("default"))) Bool XShmQueryVersion(
    Display *display /* dpy */,
    int *major /* majorVersion */,
    int *minor /* minorVersion */,
    Bool *pixmaps /* sharedPixmaps */
)
{
    *major = 0;
    *minor = 0;
    *pixmaps = 0;
    return 0;
}

__attribute__((visibility("default"))) Bool XShmAttach(
    Display *display /* dpy */,
    XShmSegmentInfo *shminfo /* shminfo */
)
{
    return 0;
}

__attribute__((visibility("default"))) Bool XShmDetach(
    Display *display /* dpy */,
    XShmSegmentInfo *shminfo /* shminfo */
)
{
    return 0;
}
