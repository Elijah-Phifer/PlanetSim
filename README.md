# PlanetSim
# User Manual for the Planet Orbit Simulator


This user manual will guide you through setting up and running the Planet Orbit Simulator using the provided files. We’ll cover the necessary package installation, usage, and examples from `sim.jl` and `3dGifAnimation.jl`.  ---  

## 1. Prerequisites and Setup  Before running the simulator, you need to have Julia installed. Follow these steps to install Julia and set up your environment.  

### Step 1: Install Julia - Download Julia from [https://julialang.org/downloads](https://julialang.org/downloads). - Follow the installation instructions for your operating system.  

### Step 2: Install Required Packages Open your terminal or Julia REPL and enter the following commands to install the necessary packages: 

```
julia using Pkg  

Pkg.add("Plots")            # For plotting and visualization 
Pkg.add("OrdinaryDiffEq")    # For solving differential equations 
Pkg.add("ModelingToolkit")   # For modeling physical systems
```

Alternatively, you can run the `Package_Setup.jl` file and the packages will install.  
These packages are essential for simulating planetary motion and creating visualizations.

### Step 3: Place File in Directory

Place the `PlanetSim` folder in your home directory. The path to that directory should look similar to this:


`~/PlanetSim`

---

## 2. How to Run the Planet Orbit Simulator

This simulator allows you to create a planetary system, simulate motion, and visualize orbits in 2D and 3D. Follow the instructions below to use the provided files.

### File Overview

- **PlanetOrbitSimulator.jl** – Core logic for defining planets, simulations, and running the orbital calculations.
- **sim.jl** – Example usage of the simulator with a pre-configured solar system.
- **3dGifAnimation.jl** – Generates an animated 3D orbit visualization as a GIF.

---

## 3. Using `PlanetOrbitSimulator.jl`

This file defines:

- **Planet**: A struct representing a planet with a name, mass, position, and velocity.
- **Simulation**: A struct that holds planets, gravitational constant, and simulation parameters.

Several functions, such as:

- `add_planet!()`: Add a planet to the simulation.
- `run_simulation!()`: Run the simulation for all planets.
- `number_of_planets()`: Get the number of planets in the simulation.

---

## 4. Example Simulation using `sim.jl`

To use the simulator with predefined planets (e.g., Sun, Jupiter, Saturn), follow these steps:

1. Open the Terminal or Julia REPL.
2. Navigate to the directory where the files are located:
    
    
    `cd ~/PlanetSim/PlanetSim/src`
    
3. Run the `sim.jl` script:
    
    
    `julia sim.jl`
    

### What happens in `sim.jl`:

A new simulation is created:

`simu = set_Simulation(30_000.0, 2.95912208286e-4)  # 30,000 units of time, G constant`

Several planets are added to the simulation:


`add_planet!(simu, Planet("Sun", 1.00000597682, [0.0, 0.0, 0.0], [0.0, 0.0, 0.0])) 
add_planet!(simu, Planet("Jupiter", 0.000954786, [-3.502, -3.816, -1.550], [0.0056, -0.0041, -0.0019]))`

The simulation is run:

`sol, u = run_simulation!(simu)`

Orbits are plotted and the plot is saved:


```
for i in 1:number_of_planets(simu)     
plot!(plt, sol, idxs = (u[:, i]...), lab = simu.planets[i].name) 
end  

plot!(plt; xlab = "x", ylab = "y", zlab = "z", title = "Outer solar system") savefig(plt, "outer_solar_system.png")
```

---

## 5. Creating 3D Animated Orbits using `3dGifAnimation.jl`

To generate 3D animations, use the `3dGifAnimation.jl` file. This example builds on the previous setup to create engaging 3D visualizations.

1. Open the Terminal or Julia REPL.
2. Navigate to the directory where the files are located:
    
    
    `cd ~/PlanetSim/PlanetSim/src`
    
3. Run the `3dGifAnimation.jl` script:

    
    `julia 3dGifAnimation.jl`
    

### Example Snippet from the Animation Code:


```
anim = Animation()  
for t in 1:length(sol.t)     
	plt = plot()     
	for i in 1:number_of_planets(simu)         
	x_path = [sol[u[1, i], k] for k in 1:t]         
	y_path = [sol[u[2, i], k] for k in 1:t]         
	z_path = [sol[u[3, i], k] for k in 1:t]          
	plot!(plt, x_path, y_path, z_path, label=simu.planets[i].name)         
	scatter!(plt, [x_path[end]], [y_path[end]], [z_path[end]], marker=:circle)     
	end     
	frame(anim) 
	end  
	
	gif(anim, "3d_planetary_orbits.gif", fps=15)
```

This script creates a GIF showing the orbits in 3D space. Adjust the frame rate or visualization options to your liking.

---

## 6. Troubleshooting

- **Missing Packages**: Ensure you installed all required packages using `Pkg.add()`.
- **File Not Found**: Verify that all scripts are in the correct directory.
- **Plot Not Displaying**: Check if `Plots.jl` is configured correctly by running the following in the Julia terminal:

    
    `using Plots gr()`
    

---

## 7. Conclusion

This simulator provides a flexible framework for creating and visualizing planetary systems. Using `sim.jl` and `3dGifAnimation.jl`, you can simulate both 3D planetary orbital paths and animations. With these examples, you now have the tools to modify or extend the simulator to create your own celestial systems.

Enjoy your journey into planetary motion and simulation!
