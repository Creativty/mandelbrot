package mandelbrot

import "core:math"

X_MANDLEBROT_SCALE :: 2.47
Y_MANDLEBROT_SCALE :: 2.24

BAILOUT :: 2 * 2
ITERATIONS_MAX :: 1024

get_iteration :: proc(px: f64, py: f64, pw: f64, ph: f64, zoom: f64) -> int {
    iter_max := ITERATIONS_MAX
    a := 1.00
    b := math.E * 2.00
    t := 0.50
	x_scaled := (((px / pw * X_MANDLEBROT_SCALE) - 2.00) / zoom) - math.min( (a * (zoom - 1.00) / b) , t)
	y_scaled := (((py / ph * Y_MANDLEBROT_SCALE) - 1.12) / zoom) - math.min( (a * (zoom - 1.00) / b) , t)
	x, y := 0.0, 0.0
	iteration: int
	escape_condition := x * x + y * y <= BAILOUT
	for iteration = 0;
	    (escape_condition && (iteration < iter_max - 1));
	    iteration += 1 {
		x_temp := (((x * x) - (y * y)) + x_scaled)
		y = ((2 * x * y) + y_scaled)
		x = x_temp
		escape_condition = x * x + y * y <= BAILOUT
	}
    return iteration
}
