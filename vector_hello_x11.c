#include <X11/Xlib.h>
#include <X11/keysym.h>
#include <stdio.h>
#include <stdint.h>

Display *display;
Window window;
Pixmap backbuf;
GC window_gc, back_gc;
unsigned long black, white;
unsigned long colors[8];
int screen;
unsigned int window_width;
unsigned int window_height;
int should_quit = 0;

int
init_window(unsigned int width, unsigned int height)
{
	XGCValues gcv;
	XColor x_color;
	display = XOpenDisplay(NULL);
	if(display == NULL) {
		fprintf(stderr, "unable to open X display\n");
		return -1;
	}
	screen = DefaultScreen(display);
	black = BlackPixel(display, screen);
	white = WhitePixel(display, screen);
	// 0 - black
	colors[0] = black;
	// 1 - red
	x_color.flags = DoRed | DoGreen | DoBlue;
	x_color.red = 65535;
	x_color.green = 0;
	x_color.blue = 0;
	XAllocColor(display, DefaultColormap(display, screen), &x_color);
	colors[1] = x_color.pixel;
	// 2 - yellow
	x_color.flags = DoRed | DoGreen | DoBlue;
	x_color.red = 65535;
	x_color.green = 65535;
	x_color.blue = 0;
	XAllocColor(display, DefaultColormap(display, screen), &x_color);
	colors[2] = x_color.pixel;
	// 3 - green
	x_color.flags = DoRed | DoGreen | DoBlue;
	x_color.red = 0;
	x_color.green = 65535;
	x_color.blue = 0;
	XAllocColor(display, DefaultColormap(display, screen), &x_color);
	colors[3] = x_color.pixel;
	// 4 - cyan
	x_color.flags = DoRed | DoGreen | DoBlue;
	x_color.red = 0;
	x_color.green = 65535;
	x_color.blue = 65535;
	XAllocColor(display, DefaultColormap(display, screen), &x_color);
	colors[4] = x_color.pixel;
	// 5 - blue
	x_color.flags = DoRed | DoGreen | DoBlue;
	x_color.red = 0;
	x_color.green = 0;
	x_color.blue = 65535;
	XAllocColor(display, DefaultColormap(display, screen), &x_color);
	colors[5] = x_color.pixel;
	// 6 - magenta
	x_color.flags = DoRed | DoGreen | DoBlue;
	x_color.red = 65535;
	x_color.green = 0;
	x_color.blue = 65535;
	XAllocColor(display, DefaultColormap(display, screen), &x_color);
	colors[6] = x_color.pixel;
	// 7 - white
	colors[7] = white;
	window = XCreateSimpleWindow(display,
				     RootWindow(display, screen),
				     0,
				     0,
				     width,
				     height,
				     0,
				     black,
				     black);
	if(window == None) {
		fprintf(stderr, "unable to create window\n");
		return -1;
	}
	window_width = width;
	window_height = height;
	XMapRaised(display, window);
	XSelectInput(display, window,
		     KeyPressMask |
		     KeyReleaseMask |
		     ExposureMask);
	gcv.function = GXcopy;
	gcv.fill_style = FillSolid;
	gcv.foreground = black;
	backbuf = XCreatePixmap(display,
				window,
				window_width,
				window_height,
				DefaultDepth(display, screen));
	if(backbuf == None) {
		fprintf(stderr, "unable to create backbuffer pixmap\n");
		return -1;
	}
	window_gc = XCreateGC(display,
			      window,
			      GCFunction | GCFillStyle | GCForeground,
			      &gcv);
	back_gc = XCreateGC(display,
			      backbuf,
			      GCFunction | GCFillStyle | GCForeground,
			      &gcv);
	return 0;
}

void
close_window()
{
	XCloseDisplay(display);
}

void
refresh_window()
{
	XCopyArea(display,
		  backbuf,
		  window,
		  window_gc,
		  0,
		  0,
		  window_width,
		  window_height,
		  0,
		  0);
	XFlush(display);
}

void
clear_display()
{
	XSetForeground(display, back_gc, black);
	XFillRectangle(display,
		       backbuf,
		       back_gc,
		       0,
		       0,
		       window_width,
		       window_height);
}

void
get_input_events()
{
	XEvent e;
	KeySym ks;
	while(XPending(display)) {
		XNextEvent(display, &e);
	}
	switch(e.type) {
	case KeyPress:
		ks = XLookupKeysym(&(e.xkey), 0);
		switch(ks) {
		case XK_Escape:
			should_quit = 1;
			break;
		}
	case Expose:
		refresh_window();
		break;
	}
}

void
draw_pline(unsigned int color_idx,
	   unsigned int length,
	   int16_t *coords)
{
	size_t i;
	unsigned long color = colors[color_idx % 8];
	XSetForeground(display, back_gc, color);
	if(length < 4) {
		return; // draw nothing unless we have 2 points to connect
	}
	for(i=2; i<length; i += 2) {
		XDrawLine(display,
			  backbuf,
			  back_gc,
			  (int)coords[i - 2],
			  (int)coords[i - 1],
			  (int)coords[i],
			  (int)coords[i + 1]);
	}
}
