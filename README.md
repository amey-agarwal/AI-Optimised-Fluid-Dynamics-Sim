# micromixer-opt: AI-optimised micromixer design

A 2D simulation of two miscible liquids flowing through a microchannel with
obstacles, coupled to Bayesian optimisation of the obstacle layout and to
explainability tools that show *why* some layouts mix better than others for
different liquid pairs. Everything is written in MATLAB. The core solver uses
base MATLAB only.

> Status: **Step 0 (scaffold)**. The sections marked *TODO* are filled in as
> the project is built.

## Physics in one paragraph

Two liquids enter a channel of width W = 1 side by side: liquid A (dye
concentration c = 1) in the lower stream and liquid B (c = 0) in the upper
stream. The steady incompressible Navier–Stokes equations with variable
viscosity μ(c) = μ_B^(1−c) μ_A^c are solved on a staggered MAC grid.
Obstacles are modelled by Brinkman penalisation. The concentration obeys an
advection–diffusion equation. Every quantity is dimensionless: W = 1, the
mean inlet velocity U = 1, pressure is scaled by μ_B U / W, and the physics
enters only through these parameters:

| Symbol | Meaning |
|---|---|
| Re = ρUW/μ_B | inertia vs. viscosity (defined with liquid B) |
| Pe = UW/D | advection vs. molecular diffusion |
| μ_A/μ_B | viscosity ratio |
| q = Q_A/Q_B | flow-rate ratio |

## Liquid pairs (fluid presets)

| Preset | Re | Pe | μ_A/μ_B | q | Note |
|---|---|---|---|---|---|
| waterDye | 0.5 | 500 | 1 | 1 | reference case |
| waterGlycerol | 0.1 | 500 | 20 | 1 | viscosity-coupled |
| slowDiffuser | 0.5 | 2000* | 1 | 1 | *Pe may be lowered after the refinement check |
| unequalFlow | 0.5 | 500 | 1 | 0.25 | thin stream A |
| moderateRe | 20 | 500 | 1 | 1 | extension: inertia |

## Setup (MATLAB Online + GitHub)

1. In MATLAB Online, clone the repository:
   `gitclone("https://github.com/<user>/micromixer-opt.git")`
2. Change into the project folder with `cd micromixer-opt`.
3. Run `startup`. This sets the path and prints a report of the release and toolboxes.
4. Run the tests with `results = runtests('tests')`.

Required: a recent MATLAB release (R2023b or later is recommended), the
Statistics and Machine Learning Toolbox, the Optimization Toolbox and the
Global Optimization Toolbox. The Parallel Computing Toolbox is optional: the
code falls back to serial execution without it.

## Folder layout

```
startup.m          path setup + environment report
src/config/        defaultParams, fluidPresets, projectRoot
src/geometry/      obstacle layouts, fluid-fraction masks, feasibility
src/solver/        flow + concentration solvers (base MATLAB only)
src/metrics/       mixing index, pressure drop, dead zones, evaluateDesign
src/optimisation/  bayesopt / surrogateopt / paretosearch runners
src/explain/       surrogate models + explainability
src/viz/           plots, animations, interactive app
tests/             matlab.unittest test classes
scripts/           runnable stage scripts + mainStory.m
results/           .mat outputs and checkpoints (gitignored)
figures/           png / gif / avi outputs (gitignored)
```

## How to run

*TODO (Steps 1–11).*

## Validation

*TODO (Steps 2–3): Poiseuille profile and pressure drop, divergence, flux
conservation, Brinkman leakage, Picard convergence, grid refinement.*

## Results

*TODO (Steps 5–9).*

## Limitations

*TODO. This section will cover the 2D assumption, the steady-flow
assumption, and the range of Pe the grid can resolve, taken from the
grid-refinement check.*
