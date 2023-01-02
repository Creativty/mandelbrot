package main

import "core:c"
import "core:os"
import "core:fmt"
import "core:mem"
import "core:time"
import "core:slice"
import "core:math/rand"
import "vendor:sdl2"
import "mandelbrot"

VIEWER_TITLE :: cstring("MANDLEBROT VIEWER")
VIEWER_WIDTH :: 512
VIEWER_HEIGHT :: 512
VIEWER_TARGET_FPS :: 60
VIEWER_TARGET_MS :: 1000 / VIEWER_TARGET_FPS

Viewer :: struct {
	zoom:        f64,
	handle:      ^sdl2.Window,
	texture:     ^sdl2.Texture,
	renderer:    ^sdl2.Renderer,
	invalidated: bool,
}

viewer_init :: proc(viewer: ^Viewer) {
	using sdl2
	if Init(INIT_EVERYTHING) < 0 {
		report_failure("ERROR: could not initialize SDL: %s\n", GetError())
	}
	viewer.handle = CreateWindow(
		VIEWER_TITLE,
		WINDOWPOS_CENTERED,
		WINDOWPOS_CENTERED,
		VIEWER_WIDTH,
		VIEWER_HEIGHT,
		WINDOW_SHOWN,
	)
	if (viewer.handle == nil) {
		report_failure("ERROR: could not create SDL_Window: %s\n", GetError())
	}
	viewer.renderer = CreateRenderer(viewer.handle, -1, RENDERER_ACCELERATED)
	if (viewer.renderer == nil) {
		report_failure(
			"ERROR: could not create SDL_Renderer: %s\n",
			GetError(),
		)
	}

	viewer.texture = CreateTexture(
		viewer.renderer,
		u32(PixelFormatEnum.RGBX8888),
		TextureAccess.STREAMING,
		VIEWER_WIDTH,
		VIEWER_HEIGHT,
	)

    viewer.zoom = 1.00
	viewer.invalidated = true
}

viewer_cleanup :: proc(viewer: ^Viewer) {
	using sdl2
	DestroyTexture(viewer.texture)
	DestroyRenderer(viewer.renderer)
	DestroyWindow(viewer.handle)
}

viewer_loop :: proc(viewer: ^Viewer) {
	using sdl2
	using time

	should_quit := false
	frame_stopwatch: Stopwatch
	stopwatch_start(&frame_stopwatch)

	for !should_quit {
		/* INPUT */
		event: Event
		for PollEvent(&event) {
            #partial switch event.type {
                case .QUIT:
                    should_quit = true
                case .KEYUP:
                    should_quit = viewer_keyup(viewer, event.key)
            }
		}

		if (viewer.invalidated) {
			viewer_update(viewer)
			viewer.invalidated = false
		}

		frame_duration := stopwatch_duration(frame_stopwatch)
		if (duration_milliseconds(frame_duration) > VIEWER_TARGET_MS) {
			stopwatch_reset(&frame_stopwatch)
			viewer_render(viewer)
			stopwatch_start(&frame_stopwatch)
		}
	}
}

viewer_keyup :: proc(viewer: ^Viewer, key_event: sdl2.KeyboardEvent) -> (should_quit: bool) {
    ZOOM_FACTOR :: 0.25
    if key_event.keysym.sym == .ESCAPE {
        fmt.println("Emitted [QUIT]")
        return true
    }
    if key_event.keysym.sym == .I {
        viewer.invalidated = true
        fmt.println("Emitted [REDRAW]")
    }
    if key_event.keysym.sym == .J {
        viewer.zoom += ZOOM_FACTOR * 4
        viewer.invalidated = true
        fmt.printf("Emitted [ZOOM+]: x%f\n", viewer.zoom)
    }
    if key_event.keysym.sym == .H {
        viewer.zoom += ZOOM_FACTOR
        viewer.invalidated = true
        fmt.printf("Emitted [ZOOM+]: x%f\n", viewer.zoom)
    }
    if key_event.keysym.sym == .G {
        viewer.zoom -= ZOOM_FACTOR
        if (viewer.zoom < 0.10) {
            viewer.zoom = 0.10
        }
        viewer.invalidated = true
        fmt.printf("Emitted [ZOOM-]: x%f\n", viewer.zoom)
    }
    if key_event.keysym.sym == .F {
        viewer.zoom -= ZOOM_FACTOR * 4
        if (viewer.zoom < 0.10) {
            viewer.zoom = 0.10
        }
        viewer.invalidated = true
        fmt.printf("Emitted [ZOOM-]: x%f\n", viewer.zoom)
    }
    return false
}

viewer_update :: proc(viewer: ^Viewer) {
	using sdl2
    ITERATIONS_MAX :: mandelbrot.ITERATIONS_MAX
	palette: [ITERATIONS_MAX]u32
	for i := 0; i < ITERATIONS_MAX; i += 1 {
		h := u32(f32(i) / f32(ITERATIONS_MAX) * 255.00)
		pixel: u32 =
			((h & 0xFF) << 24) + ((h & 0xFF) << 16) + ((h & 0xFF) << 8) + 0xFF
		palette[i] = pixel
	}

	viewer_update_texture(viewer.texture, palette[:], viewer.zoom)
}

viewer_update_texture :: proc(texture: ^sdl2.Texture, palette: []u32, zoom: f64) {
	using sdl2
	data: rawptr
	pitch: c.int
	LockTexture(texture, nil, &data, &pitch)

	mem.set(data, 19, int(pitch) * VIEWER_HEIGHT)
	mandlebrot: for py in 0 ..< VIEWER_HEIGHT {
		for px in 0 ..< VIEWER_WIDTH {
			iteration := mandelbrot.get_iteration(
				f64(px),
				f64(py),
				f64(VIEWER_WIDTH),
				f64(VIEWER_HEIGHT),
                zoom,
			)
			data_slice: []u32 = slice.from_ptr(
				cast([^]u32)data,
				VIEWER_WIDTH * VIEWER_HEIGHT,
			)
			index := (py * VIEWER_WIDTH) + px
			data_slice[index] = palette[iteration % mandelbrot.ITERATIONS_MAX]
		}
	}
	UnlockTexture(texture)
}

viewer_render :: proc(viewer: ^Viewer) {
	using sdl2
	rect := Rect {
		x = 0,
		y = 0,
		w = VIEWER_WIDTH,
		h = VIEWER_HEIGHT,
	}
	SetRenderDrawColor(viewer.renderer, 0xFF, 0xFF, 0xFF, 0xFF)
	RenderClear(viewer.renderer)
	RenderCopy(viewer.renderer, viewer.texture, &rect, &rect)
	RenderPresent(viewer.renderer)
}

main :: proc() {
	viewer: Viewer
	viewer_init(&viewer)
	defer viewer_cleanup(&viewer)

	viewer_loop(&viewer)
}

report_failure :: proc(message: string, specifiers: ..any) {
	fmt.eprintf(message, ..specifiers)
	os.exit(1)
}
