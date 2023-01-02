# Mandelbrot Viewer
A simple monochromatic Mandelbrot set viewer implemented in Odin

<img src="/assets/default.png" width="40%"></img> <img src="/assets/zoom_in.png" width="40%"></img>

### References
[Mandelbrot set (Wikipedia Article)](https://en.wikipedia.org/wiki/Mandelbrot_set)

## Installation
#### Linux
```bash
$ ./build.sh
$ ./build/viewer
```
#### Windows
```batch
> ./build.bat
> ./build/viewer.exe
```

## Controls
**zoom in**  using (`H` x0.25) or (`J` x1.00)<br>
**zoom out** using (`G` x0.25) or (`F` x1.00)<br>
**quit**     using `<ESC>`<br>
**force re-render** using `I` <br>

*NOTE: The viewer is incredibly slow at zoom +8.0 so be mindful of that.*
