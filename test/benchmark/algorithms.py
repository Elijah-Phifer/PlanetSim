import numpy as np
import pandas as pd
from scipy.integrate import solve_ivp
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import timeit
import time
from typing import Optional, List, Union
import sympy as sp

MAX_DEPTH = 40  # Maximum tree depth to prevent stack overflow

class Simulation_env:
    def __init__(self, G, planets = [], t_end = 100):
        self.G = G
        self.planets = planets
        self.t_end = t_end


    def list_vels(self, planets):
        """
        Returns a 3xN numpy array where each column represents the velocity (x, y, z components) 
        of a planet in the list.
        """
        vel_matrix = np.zeros((3, len(planets)))
        
        for i, planet in enumerate(planets):
            vel_matrix[:, i] = planet.velocity
        
        return vel_matrix


    def list_pos(self, planets):
        """
        Returns a 3xN numpy array where each column represents the position (x, y, z components) 
        of a planet in the list.
        """
        pos_matrix = np.zeros((3, len(planets)))
        
        for i, planet in enumerate(planets):
            pos_matrix[:, i] = planet.position
        
        return pos_matrix


    def list_masses(self, planets):
        """
        Returns a 1D numpy array where each element represents the mass of a planet in the list.
        """
        masses = np.zeros(len(planets))
        
        i=0
        for planet in planets:
            masses[i] = float(planet.mass)
            i = i+1
        
        return masses


class Planet:
    def __init__(self, name: str, mass, position, velocity, force=None):
        self.name = name
        self.mass = mass
        self.velocity = np.array(velocity)
        self.position = np.array(position)
        self.force = np.array(force)


def plot_static(df):
    """
    Visualize planetary orbits in 3D.
    Args:
        df (pandas.DataFrame): DataFrame with columns 'planet', 'x', 'y', and 'z'.

    Returns:
        None
    """
    # Group the data by planet
    grouped_planets = df.groupby("planet")

    # Initialize a 3D plot
    fig = plt.figure()
    ax = fig.add_subplot(111, projection='3d')
    ax.set_xlabel("x")
    ax.set_ylabel("y")
    ax.set_zlabel("z")
    ax.set_title("Planetary Orbits")

    # Plot each planet's orbit path
    for planet_name, planet_data in grouped_planets:
        ax.plot(
            planet_data['x'], planet_data['y'], planet_data['z'], label=planet_name
        )

    # Add a legend
    ax.legend(loc="upper right")

    # Show the plot
    plt.show()



def direct_pairwise_simulation(sim):
    # Extract simulation parameters
    G = sim.G
    planets = sim.planets
    vel = sim.list_vels(planets)
    pos = sim.list_pos(planets)
    masses = sim.list_masses(planets)
    t_end = sim.t_end
    N = len(planets)

    # Initialize data storage
    position_data = []

    # Define the differential equations
    def equations(t, y):
        positions = y[:3 * N].reshape((3, N))
        velocities = y[3 * N:].reshape((3, N))

        accelerations = np.zeros((3, N))
        for i in range(N):
            for j in range(N):
                if i != j:
                    distance_vector = positions[:, j] - positions[:, i]
                    distance = np.linalg.norm(distance_vector)
                    accelerations[:, i] += (
                        G * masses[j] * distance_vector / distance**3
                    )

        dydt = np.concatenate((velocities.flatten(), accelerations.flatten()))
        return dydt

    # Initial conditions
    initial_conditions = np.concatenate((pos.flatten(), vel.flatten()))

    # Solve the ODE system
    tspan = (0, t_end)
    sol = solve_ivp(
        equations, tspan, initial_conditions, method="RK45", t_eval=np.linspace(0, t_end, 1000)
    )

    # Store the results in a pandas DataFrame
    for t_idx, t in enumerate(sol.t):
        for i in range(N):
            x, y, z = sol.y[:3 * N, t_idx].reshape((3, N))[:, i]
            position_data.append({
                "time": t,
                "planet": planets[i].name,
                "x": x,
                "y": y,
                "z": z
            })

    position_df = pd.DataFrame(position_data)

    return position_df

class Region3D:
    """Represents a 3D region with a center and size."""
    def __init__(self, center: List[float], size: float):
        self.center = np.array(center)
        self.size = size


class OctreeNode3D:
    """Represents a node in a 3D octree."""
    def __init__(self, region: Region3D):
        self.region = region
        self.body = None  # Reference to a Planet object or None
        self.total_mass = 0.0
        self.com = np.zeros(3)  # Center of mass
        self.children = [None] * 8  # Eight children nodes




def get_system_bounds(positions):
    """Determine the bounding region for all bodies."""
    min_pos = np.min(positions, axis=1)
    max_pos = np.max(positions, axis=1)
    center = (min_pos + max_pos) / 2
    size = np.max(max_pos - min_pos) * 1.1  # Add 10% margin
    return Region3D(center=center.tolist(), size=size)


def create_root_node(bounds):
    """Create a root node for the octree."""
    return OctreeNode3D(bounds)


def get_octant(pos, center):
    """Determine the octant for a position relative to a center."""
    idx = 1
    if pos[0] >= center[0]:
        idx += 1
    if pos[1] >= center[1]:
        idx += 2
    if pos[2] >= center[2]:
        idx += 4
    return idx


def get_child_region(parent, octant):
    """Determine the region for a given octant of the parent region."""
    new_size = parent.size / 2
    new_center = parent.center.copy()
    offset = new_size / 2

    if (octant - 1) & 1:
        new_center[0] += offset
    else:
        new_center[0] -= offset

    if (octant - 1) & 2:
        new_center[1] += offset
    else:
        new_center[1] -= offset

    if (octant - 1) & 4:
        new_center[2] += offset
    else:
        new_center[2] -= offset

    return Region3D(center=new_center.tolist(), size=new_size)


def insert_body(node, body, depth):
    """Insert a body into the octree."""
    if depth > MAX_DEPTH:
        raise RuntimeError("Maximum tree depth exceeded")

    if node.body is None and all(child is None for child in node.children):
        node.body = body
        return

    if node.body is not None:
        old_body = node.body
        node.body = None
        subdivide(node)
        insert_body(node, old_body, depth + 1)

    child_idx = get_octant(body.position, node.region.center) - 1

    if node.children[child_idx] is None:
        new_region = get_child_region(node.region, child_idx + 1)
        node.children[child_idx] = OctreeNode3D(new_region)

    insert_body(node.children[child_idx], body, depth + 1)


def subdivide(node):
    """Subdivide a node into eight children."""
    for i in range(1, 9):
        region = get_child_region(node.region, i)
        node.children[i - 1] = OctreeNode3D(region)


def summarize_subtree(node, depth):
    """Summarize the subtree rooted at this node."""
    if depth > MAX_DEPTH:
        raise RuntimeError("Maximum tree depth exceeded")

    if node.body is not None:
        node.total_mass = node.body.mass
        node.com = node.body.position.copy()
        return

    node.total_mass = 0.0
    node.com = np.zeros(3)

    for child in node.children:
        if child is not None:
            summarize_subtree(child, depth + 1)
            node.total_mass += child.total_mass
            node.com += child.total_mass * child.com

    if node.total_mass > 0:
        node.com /= node.total_mass


def compute_force(node, body, G, theta, depth):
    """Compute the force on a body using the Barnes-Hut approximation."""
    if depth > MAX_DEPTH:
        return np.zeros(3)

    if node.total_mass == 0:
        return np.zeros(3)

    r = node.com - body.position
    r_mag = np.linalg.norm(r)

    if node.body is body:
        return np.zeros(3)

    if r_mag < 1e-10:
        return np.zeros(3)

    if node.body is not None or (node.region.size / r_mag < theta):
        return G * node.total_mass * body.mass * r / r_mag**3

    force = np.zeros(3)
    for child in node.children:
        if child is not None:
            force += compute_force(child, body, G, theta, depth + 1)

    return force


def barnes_hut(sim):
    """Simulate the gravitational dynamics using the Barnes-Hut algorithm."""
    position_data = []
    planets = sim.planets
    G = sim.G
    dt = 1
    num_steps = int(sim.t_end / dt)

    theta = 0.5

    vel = np.array([p.velocity for p in planets]).T
    pos = np.array([p.position for p in planets]).T

    for step in range(num_steps):
        bounds = get_system_bounds(pos)
        root = create_root_node(bounds)

        for planet in planets:
            planet.position = pos[:, planets.index(planet)]
            planet.velocity = vel[:, planets.index(planet)]
            insert_body(root, planet, 0)

        summarize_subtree(root, 0)

        accelerations = np.zeros_like(pos)
        for i, planet in enumerate(planets):
            force = compute_force(root, planet, G, theta, 0)
            accelerations[:, i] = force / planet.mass

        vel += 0.5 * dt * accelerations
        pos += dt * vel
        vel += 0.5 * dt * accelerations

        for i, planet in enumerate(planets):
            position_data.append({
                "time": step * dt,
                "planet": planet.name,
                "x": pos[0, i],
                "y": pos[1, i],
                "z": pos[2, i]
            })

    return pd.DataFrame(position_data)

def direct_pairwise_simulation_with_potential(sim):
    # Extract simulation parameters
    G = sim.G
    planets = sim.planets
    masses = sim.list_masses(planets)
    pos = sim.list_pos(planets)
    vel = sim.list_vels(planets)
    t_end = sim.t_end
    N = len(planets)

    # Initialize symbolic variables
    t = sp.symbols('t')
    u = sp.MatrixSymbol('u', 3, N)  # Positions (3D for N bodies)
    m = sp.Matrix(masses)

    # Compute potential energy
    potential = 0
    for i in range(N):
        for j in range(i):
            # Compute the distance vector and its magnitude
            distance_vector = sp.Matrix([u[k, i] - u[k, j] for k in range(3)])
            r_ij = sp.sqrt(sum(distance_vector[k]**2 for k in range(3)))
            potential -= G * m[i] * m[j] / r_ij

    # Compute the gradient of the potential energy
    gradient = sp.Matrix([sp.diff(potential, u[i, j]) for i in range(3) for j in range(N)])
    gradient = gradient.reshape(3, N)

    # Define the system of ODEs
    def equations(t, y):
        positions = y[:3 * N].reshape((3, N))
        velocities = y[3 * N:].reshape((3, N))
        
        # Convert symbolic gradient to numerical gradient
        grad_numeric = sp.lambdify(u, gradient, 'numpy')(positions)
        accelerations = -grad_numeric / masses

        dydt = np.concatenate((velocities.flatten(), accelerations.flatten()))
        return dydt

    # Initial conditions
    initial_conditions = np.concatenate((pos.flatten(), vel.flatten()))

    # Solve the ODE system
    tspan = (0, t_end)
    sol = solve_ivp(
        equations, tspan, initial_conditions, method="RK45", t_eval=np.linspace(0, t_end, 1000)
    )

    # Store the results in a pandas DataFrame
    position_data = []
    for t_idx, t in enumerate(sol.t):
        for i in range(N):
            x, y, z = sol.y[:3 * N, t_idx].reshape((3, N))[:, i]
            position_data.append({
                "time": t,
                "planet": planets[i].name,
                "x": x,
                "y": y,
                "z": z
            })

    position_df = pd.DataFrame(position_data)

    return position_df





def run(algo, sim):
    if(algo == "direct_pairwise"):
        direct_pairwise_simulation(sim)
    elif(algo == "barnes_hut"):
        barnes_hut(sim)
    elif(algo == "direct_p"):
        direct_pairwise_simulation_with_potential(sim)
    else:
        print("wrong")



def main():
    Sun = Planet("Sun", 1.00000597682, [0.0, 0.0, 0.0], [0.0, 0.0, 0.0])
    Jupiter = Planet("Jupiter", 0.000954786104043, [-3.5023653, -3.8169847, -1.5507963], [0.00565429, -0.0041249, -0.00190589])
    Saturn = Planet("Saturn", 0.000285583733151, [9.0755314, -3.0458353, -1.6483708], [0.00168318, 0.00483525, 0.00192462])
    Uranus = Planet("Uranus", 0.0000437273164546, [8.310142, -16.2901086, -7.2521278], [0.00354178, 0.00137102, 0.00055029])
    Neptune = Planet("Neptune", 0.0000517759138449, [11.4707666, -25.7294829, -10.8169456], [0.0028893, 0.00114527, 0.00039677])
    simulation = Simulation_env(G=2.95912208286e-4, planets=[Sun, Jupiter], t_end = 10000)


    times = []

    for i in range(100):

        start_time = time.time()

        run("barnes_hut", simulation)

        end_time = time.time()

        t = end_time - start_time

        times.append(t)

    
    ti = 0
    for t in times:
        ti = ti + t
    
    
    avg = (ti/len(times)) * 1000 
        

    print(avg, 'milliseconds')



if __name__ == '__main__':
    main()