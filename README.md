# Hydrogen Diffusion Pipeline

Pipeline for turning raw transmission images into concentration profiles and diffusion coefficients D(c), using Stenlund's method.

This isn't a "run it and get an answer" kind of tool. You have to look at your data at a couple of points along the way and make some calls yourself — which rectangle to use, which time window, where to cut off the integral. The workflow below is the order I actually use it in.

## Setup

Add `helpers/` to your MATLAB path (`addpath('helpers')`, or right-click → Add to Path in the file browser). Everything in there — image loading, the transmission/concentration conversion, the calibration data — is called by name from the scripts in the root folder, so without it on the path nothing will run.

## 1. Add your run

Everything starts in `run_catalogue.m`. Each run is a struct with the file path, temperature, pressure, the region of interest, and which frames to sample:

```matlab
runs.N3A_abs150_1st = struct( ...
    'fname',        '20250416_N3A/Alpha/150C at 327mbar/Absorption/2026.04.09 at 12.53.58', ...
    'temperature',  150, ...
    'pressure',     327, ...
    'rect',         [100 300 50 170], ...   % [xstart xstop ystart ystop]
    'flip',         false, ...
    'p_start',      250, ...
    'p_count',      80, ...
    'p_stride',     5);
```

Easiest way to add a new one: copy an existing run and change the fields. You don't need to get `rect`, `p_start`, `p_count` etc. right on the first try — put in something reasonable, you'll tune all of it in the next step anyway.

## 2. Inspect it and find a good window

Set `active_run` in `init_everything.m` to your run and run it. This reads the images, builds the transmission/concentration matrices, and dumps everything into the base workspace (`xx`, `T`, `TRM`, `C`, `C_dx`, `C_dt`, ...). It stays there until you run `init_everything` again — so if you switch to a different run, re-run it, otherwise you're still looking at the previous sample's data.

Then:

```matlab
quick_inspection
```

Step through time with Enter, or jump to an index, and look at what you get. What you're actually checking:

* the rectangle covers the diffusion front and not junk outside the sample
* at the far end of the profile (the side furthest from where hydrogen enters), `dC/dx` should be flat around 0
* `C` itself should also be close to 0 there — that's how you know nothing has diffused in from the other side yet

If that's not the case, go back to `run_catalogue.m`, adjust `rect`, `p_start`, `p_count`, `p_stride`, and re-run `init_everything` + `quick_inspection` until it does. This step matters — if the profiles are off here, everything downstream is built on bad data.

## 3. Sanity-check Stenlund at one time step

```matlab
stenlund_inspection
```

Pick a time step, step through x. This shows exactly what's happening at each point — the cutoff, the integral, the resulting D_c — so you can catch anything obviously broken before computing the full D(c) curve.

## 4. Compute D(c)

```matlab
calculate_diffusion_adaptive_xmax
```

Check that the cutoff looks sane for a few time steps (it prints/plots where it's cutting off). If it looks wrong, adjust `grad_cutoff` / `window` / `threshold_hits` at the top of the script.

## 5. Save it

```matlab
save_diffusion_result
```

Saves whatever's currently in `Dc_results` — i.e. whatever you last computed — as a CSV in `diffusions/`:

```
diffusions/Dc_<run>_<temp>C_<pressure>mbar_<type>.csv
```

## 6. Next sample

Change `active_run` in `init_everything.m`, run it again, repeat steps 2-5. Each run gets you one CSV in `diffusions/`.

## 7. Compare everything

```matlab
plot_all_diffusion
```

plots every CSV in `diffusions/` together.

Once you've got runs at a few different temperatures, you can also do:

```matlab
plot_arrhenius
compute_mobility
```

`compute_mobility` needs `helpers/f_therm_struct.mat` (the thermodynamic factor per temperature) to convert D(c) into mobility — it loads that file itself, so as long as `helpers/` is on your path it just works.

---

## The Stenlund equation

$$
D(c) =
\frac{- \int_{x^{\ast}}^{x_{\text{cut}}} \frac{\partial C}{\partial t}  dx}
{\frac{\partial C}{\partial x}\Big|_{x=x^{\ast}}}
$$

* **denominator** — local gradient at the point
* **numerator** — how much concentration is still piling up ahead of that point, integrated up to the cutoff

You don't integrate all the way to the edge of the profile — you stop where `dC/dx ≈ 0`, since past that point there's nothing left to diffuse. In practice this cutoff is found with a window: check several points around each x, and if enough of them are close to 0, that's the cutoff.

```matlab
grad_cutoff    ≈ 0.2-0.5
window         ≈ 5-9
threshold_hits ≈ 4-6
```

You'll usually have to adjust these by hand per sample.

## A couple of things worth knowing

Smooth the concentration first, take derivatives second — not the other way around. `dC/dx` feeds straight into the denominator of the equation above, so a small smoothing mistake turns into a big error in D.

Getting the cutoff wrong is the most common way to get garbage results — wrong cutoff, wrong integral, wrong D(c). That's the whole reason the window-based method exists instead of just checking for exact zero or a single threshold crossing.

If something looks off, it's usually one of:

* smoothing too aggressive or too weak → weird-looking derivatives
* `dC/dx` too close to 0 → D(c) blows up
* bad cutoff → too much scatter in D(c)
* wrong rectangle → the physics just doesn't make sense

## TODO

* better cutoff visualization
* automatically filter outliers

## Acknowledgments

This builds on work from the following people:

* **Gunnar Karl Pálsson** supervised the thesis and gave valuable insights regarding the physics and data analysis.
* **Ola Hartmann** wrote the helper functions in `helpers/` — image loading, the transmission/concentration conversion, everything the rest of the pipeline calls into.
* **Lennart Spode** provided the calibration data (`helpers/cubic_calibration.mat`, `helpers/f_therm_struct.mat`).

## License

MIT — see [LICENSE](LICENSE).
