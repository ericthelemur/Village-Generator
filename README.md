# Village Generator
This project creates roads by following a tensor-like vector field, with houses and branches placed at random intervals. Contours and the river are marked with marching squares, and names by a Markov Chain.

![image](https://user-images.githubusercontent.com/8903016/110025132-dd4d6c00-7d26-11eb-8b8b-5051dc598488.png)

In my previous projects, I had focused on generated an entire island/continent, in this project, I wanted to focus on techniques for generating villages/towns instead. 

## Generation

### Terrain
The first step in generation is constructing the base terrain. This is a random gradient distorted by a layer of noise, with a chance of a lake/sea generating at a random (but low) height. There is a further chance the terrain gets folded up on the far side to form a river. Currently, it is impossible the village to reach the far side of the river, though I would like to implement the chance for a river/ferry/ford to generate and have the village span the river.

Due to my experience with noise layers in my previous projects, I decided to make my own modular system of customisable noise layers and combinations/transformations for them, allowing easy customisation. The choice of layers are Perlin noise, standard gradient, radial gradient, or a constant. These can be transformed by either being ridged (taking $1 - |v|$), raising to a power, adding a constant, remapped to a different range, to name a few; and combined by adding, multiplying, taking the min/max, or by using a third layer to interpolate between 2 layers. All these options inherit from a shared interface, so can all be passed into each other, in whatever configuration is wanted.

### Roads
This was originally a tensor based solution, however, since I was specifically targeting heightmaps, some of the tensor math was entirely unnecessary, and so was removed.

Road generation starts by picking a start point, which is chosen randomly, however restricted to a middling height value. From this point the main road is traced, with possible branch points randomly marked. These possible branch points are sampled from randomly, weighted towards picking central points, and (assuming valid roads) are traced also. When a road is created, it is either running along the major or minor direction (this terminology is borrowed from tensors and eigenvectors) along the gradient (perpendicular or parallel), and each step is taken in this direction, with a random chance of ending the further from the centre it gets. This is repeated until a full network of roads are generated (either all candidates eliminated or random limit is reached).

Roads are rejected or ended if they are too close to another parallel road, so buildings can always fit between them, and if they get too close to water. 

### Buildings
Building generation is simple, pick a random point on the road network (weighted towards the centre), and attempt to place a randomly sized building there. Building collision check is done with SAT on a slightly inflated rectangle, which is not the simplest/most efficient for rectangles only, but can be extended to other shapes (as I hope to do sometime). This continues until most candidate points have been attempted. The paths up to the buildings are a short line that is randomly perturbed with midpoint displacement to created a smooth shape.

### Name and Population
The name is generated from a Markov chain trained on Welsh place names (very similar to my map generator), and population is approximately proportional to the number of houses.

### Example

![image](https://user-images.githubusercontent.com/8903016/110023434-1b499080-7d25-11eb-9fc5-cddce06247a5.png)|![image](https://user-images.githubusercontent.com/8903016/110023483-243a6200-7d25-11eb-94ee-d16fa89a9e69.png)|
:-:|:-:
|Terrain generated|Main road generated|
|![image](https://user-images.githubusercontent.com/8903016/110023598-40d69a00-7d25-11eb-90da-3036269f8336.png)|![image](https://user-images.githubusercontent.com/8903016/110023612-4502b780-7d25-11eb-9e91-98db97893cb3.png)|
|A few branching roads generated|Full road structure generated, with building markings|
|![image](https://user-images.githubusercontent.com/8903016/110023632-4cc25c00-7d25-11eb-99fa-def1f80b56c3.png)|![image](https://user-images.githubusercontent.com/8903016/110023643-5055e300-7d25-11eb-9678-3bbaea2f3654.png)|
|A few houses placed|Most houses placed|

![image](https://user-images.githubusercontent.com/8903016/110023664-55b32d80-7d25-11eb-85f8-53cb76a88eef.png)

## Further Examples
I have constructed my settings in such a way that I can change out parameters easily, for example to create a denser town. Given the aim of this generator is for villages, the building generation does not work so well for dense buildings, however, results are still reasonable. In the future, I would like to make the settings load from a JSON file, as this would allow for easier customisation, to allow denser buildings and to allow roads to travel at other angles to the gradient.

![image](https://user-images.githubusercontent.com/8903016/110025076-d161aa00-7d26-11eb-89e5-bc3cdd10f390.png)
