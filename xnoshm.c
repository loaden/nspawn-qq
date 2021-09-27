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

__attribute__((visibility("default"))) int XShmGetEventBase(
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

__attribute__((visibility("default"))) int XShmPixmapFormat(
    Display *display /* dpy */
)
{
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

__attribute__((visibility("default"))) Bool XShmPutImage(
    Display *display /* dpy */,
    Drawable d /* d */,
    GC gc /* gc */,
    XImage *image /* image */,
    int src_x /* src_x */,
    int src_y /* src_y */,
    int dst_x /* dst_x */,
    int dst_y /* dst_y */,
    unsigned int src_width /* src_width */,
    unsigned intsrc_height /* src_height */,
    Bool send_event /* send_event */
)
{
    return 0;
}

__attribute__((visibility("default"))) Bool XShmGetImage(
    Display *display /* dpy */,
    Drawable d /* d */,
    XImage *image /* image */,
    int x /* x */,
    int y /* y */,
    unsigned long plane_mask /* plane_mask */
)
{
    return 0;
}

__attribute__((visibility("default"))) XImage *XShmCreateImage(
    Display *display /* dpy */,
    Visual *visual /* visual */,
    unsigned int depth /* depth */,
    int format /* format */,
    char *data /* data */,
    XShmSegmentInfo *shminfo /* shminfo */,
    unsigned int width /* width */,
    unsigned int height /* height */
)
{
    return 0;
}

__attribute__((visibility("default"))) Pixmap XShmCreatePixmap(
    Display *display /* dpy */,
    Drawable d /* d */,
    char *data /* data */,
    XShmSegmentInfo *shminfo /* shminfo */,
    unsigned int width /* width */,
    unsigned int height /* height */,
    unsigned int depth /* depth */
)
{
    return 0;
}
