# PlanetSim
# User Manual for the Planet Orbit Simulator


This user manual will guide you through setting up and running the Planet Orbit Simulator using the provided files. We’ll cover the necessary package installation, usage, and examples. 
---  

## 1. Prerequisites and Setup  Before running the simulator, you need to have Julia installed. Follow these steps to install Julia and set up your environment.  

### Step 1: Install Julia - Download Julia from [https://julialang.org/downloads](https://julialang.org/downloads). - Follow the installation instructions for your operating system.  

### Step 2: Install Required Packages Open your terminal or Julia REPL and enter the following commands to install the necessary packages: 

## PlanetSim Documentation

Welcome to the `PlanetSim` simulation environment! This guide walks you through setting up, customizing, running, and visualizing planetary simulations using the `PlanetSim` package. This package allows users to simulate orbital mechanics by adding, removing, and configuring planetary bodies within a 3D simulation environment.

### Prerequisites
Make sure the `PlanetSim` package is accessible. In your Julia REPL, activate the package by running:

```julia
using Pkg
Pkg.activate("/path/to/PlanetSim")
Pkg.instantiate()
```

Alternatively, you can add `PlanetSim` as a local package by running the following:

```julia
using Pkg
Pkg.develop(path="/path/to/PlanetSim")
```

### Quick Start Example
Here’s a quick start to get you familiar with creating a simulation, adding and removing planets, running the simulation, and visualizing the results.

```julia
using PlanetSim
```

### Step 1: Create a Simulation Environment

To start a new simulation, initialize the environment using `initialize_simulation(gravity_constant, time_step)`. 

- `gravity_constant`: A scaling factor for gravitational force.
- `time_step`: The time increment per simulation step.

#### Example
```julia
sim = initialize_simulation(500.0, 2.95912208286e-4)
```

### Step 2: Define Planets

Each planet is defined by:
- `name`: The planet’s name (e.g., `"Earth"`)
- `mass`: Relative mass of the planet (scaled as necessary).
- `position`: Initial 3D position of the planet as `[x, y, z]`.
- `velocity`: Initial 3D velocity of the planet as `[vx, vy, vz]`.

Define planets with the `Planet` constructor.

#### Example
```julia
Sun = Planet("Sun", 1.00000597682, [0.0, 0.0, 0.0], [0.0, 0.0, 0.0])
Earth = Planet("Earth", 0.000003003, [0.999723, -0.002897, 0.0], [0.000503, 0.017201, 0.0])
```

### Step 3: Add Planets to the Simulation

Use `add_planet!(sim, planet)` to add each defined planet to your simulation environment. This function modifies `sim` by adding the specified planet.

#### Example
```julia
add_planet!(sim, Sun)
add_planet!(sim, Earth)
```

### Step 4: Remove Planets from the Simulation (Optional)

If you need to remove a planet, use `remove_planet!(sim, planet)`, where `planet` is the instance to be removed.

#### Example
```julia
remove_planet!(sim, Earth)
```

### Step 5: Run the Simulation

Run the simulation with `run_algorithm(algorithm, sim)`, where `algorithm` specifies the calculation method. For example, use `:direct_pairwise` for a basic gravitational pairwise force calculation. Alternatively `:Barnes_Hut` can be used. The differences are explained further along. 

#### Example
```julia
data = run_algorithm(:direct_pairwise, sim)
```

### Step 6: Visualize the Results

`PlanetSim` provides various visualization functions to help you understand planetary motion. You can generate both static and animated plots.

#### 1. Static 3D Plot

The `Plot_Static(data)` function creates a static 3D plot of the planetary orbits.

```julia
plt1 = Plot_Static(data)
display(plt1)
```
#### 2. Static interactive

The `Static_interactive(:direct_pairwise, data, sim, sun_mass)` function produces a simple gui that allows the user to change the mass of the sun. Simply move the slider to the desired value and press the `simulate` button to rerun the simulation

```julia
plt2 = Static_interactive(:direct_pairwise, data, sim,sun_mass)
display(plt2)
```

#### 3. Interactive 3D Animation

The `Animate3D_interactive(data)` function produces an interactive 3D animation, allowing you to navigate and explore planetary orbits.

```julia
plt3 = Animate3D_interactive(data)
display(plt3)
```

#### 3. Save as Animated GIF

To save an animation as a GIF, use `Animate3D_GIF(data)` and `save_gif`:

```julia
plt3 = Animate3D_GIF(data)
save_gif(plt3, "path/to/planetary_orbits.gif")
```

### Full Example Code
Here’s a complete example to simulate the solar system:
*Note* The user can choose between the Barnes_Hut_test.jl and direct_pairwise_test.jl. The only difference being that Barnes_Hut_test is less accurate but compensates with faster run times. 


```julia
#direct_pairwise_test.jl
using PlanetSim

# Initialize the simulation
sim = initialize_simulation(500.0, 2.95912208286e-4)

# Define planets
Sun = Planet("Sun", 1.00000597682, [0.0, 0.0, 0.0], [0.0, 0.0, 0.0])
Mercury = Planet("Mercury", 0.0000001653, [0.3871, 0.0, 0.0], [0.0, 0.0175, 0.0])
Venus = Planet("Venus", 0.0000024478383, [0.7233, 0.0, 0.0], [0.0, 0.0130, 0.0])
Earth = Planet("Earth", 0.000003003, [0.999723, -0.002897, 0.0], [0.000503, 0.017201, 0.0])
Mars = Planet("Mars", 0.000000323, [1.52366231, 0.0, 0.0], [0.0, 0.0126, 0.0])
Jupiter = Planet("Jupiter", 0.000954786104043, [-3.5023653, -3.8169847, -1.5507963], [0.00565429, -0.0041249, -0.00190589])
Saturn = Planet("Saturn", 0.000285583733151, [9.0755314, -3.0458353, -1.6483708], [0.00168318, 0.00483525, 0.00192462])
Uranus = Planet("Uranus", 0.0000437273164546, [8.310142, -16.2901086, -7.2521278], [0.00354178, 0.00137102, 0.00055029])
Neptune = Planet("Neptune", 0.0000517759138449, [11.4707666, -25.7294829, -10.8169456], [0.0028893, 0.00114527, 0.00039677])
Pluto = Planet("Pluto", 1 / 1.3e8, [-15.5387357, -25.2225594, -3.1902382], [0.00276725, -0.00170702, -0.00136504])

# Add planets to the simulation
add_planet!(sim, Sun)
add_planet!(sim, Jupiter)
add_planet!(sim, Saturn)
add_planet!(sim, Uranus)
add_planet!(sim, Neptune)
add_planet!(sim, Pluto)
add_planet!(sim, Earth)
add_planet!(sim, Mars)
add_planet!(sim, Venus)
add_planet!(sim, Mercury)

# Optionally, remove planets
remove_planet!(sim, Pluto)
remove_planet!(sim, Earth)

# Run the simulation
data = run_algorithm(:direct_pairwise, sim)

# Visualization
plt1 = Plot_Static(data)
display(plt1)

plt2 = Static_interactive(:direct_pairwise, data, sim,sun_mass)
display(plt2)

plt3 = Animate3D_interactive(data)
display(plt3)

plt4 = Animate3D_GIF(data)
save_gif(plt4, "test/graphs/planetary_orbits.gif")
```

### Function Reference

- **`initialize_simulation(gravity_constant, time_step)`**: Sets up the simulation environment.
- **`Planet(name, mass, position, velocity)`**: Defines a planetary body.
- **`add_planet!(sim, planet)`**: Adds a planet to the simulation.
- **`remove_planet!(sim, planet)`**: Removes a planet from the simulation.
- **`run_algorithm(algorithm, sim)`**: Runs the specified simulation algorithm.
- **`Plot_Static(data)`**: Creates a static 3D plot.
- **`Static_interactive(:direct_pairwise, data, sim,sun_mass)`**: Creates a gui that allows for the manipulation of the sun's mass. :direct_pairwise version
- **`Static_interactive(:Barnes_Hut, data, sim,sun_mass)`**: :Barnes_Hut version
- **`Animate3D_interactive(data)`**: Generates an interactive 3D animation.
- **`Animate3D_GIF(data)`**: Creates an animated GIF of the planetary orbits.

This documentation should give you a solid foundation to start exploring and customizing simulations in `PlanetSim`!

## 7. Conclusion

This simulator provides a flexible framework for creating and visualizing planetary systems. Using `PlanetSim`, you can simulate both 3D planetary orbital paths and animations. With these examples, you now have the tools to modify or extend the simulator to create your own celestial systems.

Enjoy your journey into planetary motion and simulation!
