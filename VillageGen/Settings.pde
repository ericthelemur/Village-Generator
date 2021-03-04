class Settings {
    public boolean useSetSeed = false;
    public Long setSeed = -8747457531219207153L;
    // Seed of all the randomness, same seed will generate the same map every time
    public Long seed = useSetSeed ? setSeed : new Random().nextLong();
    public Random mainRandom = new Random(seed);
    
    // Noise used to offset jitter lines
    public INoise lineJitterNoise = new Noise(mainRandom.nextLong());
    // Water level
    public float waterLevel = 0.3;
    
    
    
    // Wait time between each step of animation
    public float animStepTime = 500;
    
    // Settings for heightmap generation
    class HeightMapSettings {
        // Heightmap random (so each section is independant of each other)
        public Random hmRandom = new Random(mainRandom.nextLong());
        // Main noise for heightmap: is a combination of noise and gradient
        public INoise mainNoise = new NoiseMask(NoiseTriFuncs.MASK, 
                                      new Noise(hmRandom.nextLong()).setScale(0.06).setOctaves(8).setRoughness(1.6), 
                                      new NoiseGradient(hmRandom.nextFloat()*TWO_PI, w, h),
                                      new NoiseConstant(0.75));
        
        // Chance of river/sea/lake
        public float waterChance = 0.6;
        // If there is water, chance of river instead of sea/lake
        public float riverChance = 0.5;
        
        // Min distance between neighbouring points in a contour to draw that point
        public float contourDuplicatePointRadius = 5;
        // Maximum distance between 2 neighbouring lines, such that they are considered the same point. This accounts for floating point rounding error
        public float marchingSquaresFloatEpsilon = 1e-8;
        // Distance between each gridpoint of the marching squares sampling. Too close points lead to poor visual quality and excessive computation
        public int marchingSquaresSampleDist = 10;
    }
    
    //Settings for the road generation
    class RoadSettings {
        // Road random (so each section is independant of each other)
        public Random roadRandom = new Random(mainRandom.nextLong());
        // Noise layer to determine density of the buildings and roads - is a sharp radial gradient
        public INoise roadDensityNoise = new NoiseMap(0, 1, 0.2, 1, new NoisePow(4, new NoiseRadialGradient(new Point(w/2, h/2), w, h)));
        // Noise layer to determine how much roads branch - same as road density noise
        public INoise branchChanceNoise = roadDensityNoise;
        // Min and max heights to start the generation at, so does not start too close to lake or edge
        public float minStartHeight = 0.45, maxStartHeight = 0.7;
        
        // Distance of each road step
        public float stepDist = 5;
        // Separation of roads at the start of each road
        public float roadStartSepMin = 30, roadStartSepMax = 250;
        // Separation of roads during each road, different from starts, so roads can drift closer than they started
        public float roadSepMin = 50, roadSepMax = 200;
        // Chance a road is ended at a node, multiplied by the density
        public float roadEndChance = 0.04;
        // Chance a new road starts as a crossroad instead of a T-junction
        public float crossRoadChance = 0.7;
        
        // Number of roads to place per frame
        public int placePerFrame = 1;
    }
    
        //Settings for the building generation
    class BuildingsSettings {
        // Min and max for the building width, length and path length
        public float buildWidthMin = 10, buildWidthMax = 30;
        public float buildLengthMin = 10, buildLengthMax = 30;
        public float buildPathMin = 3, buildPathMax = 10;
        // Boundary around each building to keep clear, in pixels.
        public float boundary = 5;
        
        // Ends building placement when random number is less than endP, endCount times
        public float endP = 0.04;
        public int endCount = 5;
        
        // Number of roads to place per frame
        public int placePerFrame = 3;
    }
    
    
    public int w, h;
        
    public HeightMapSettings heightmapSettings;
    public RoadSettings roadSettings;
    public BuildingsSettings buildingsSettings;
    
    public Settings(int w, int h) {
        this.w = w;
        this.h = h;
        
        heightmapSettings = new HeightMapSettings();
        roadSettings = new RoadSettings();
        buildingsSettings = new BuildingsSettings();
        println("Seed:", seed);
    }
}


// Settings aimed at generating a larger, more dense settlement
class TownSettings extends Settings {
    public TownSettings(int w, int h) {
        super(w, h);
        animStepTime = 500;
        
        roadSettings.roadDensityNoise = new NoiseMap(0, 1, 0.1, 1, new NoisePow(1, new NoiseRadialGradient(new Point(w/2, h/2), w, h)));
        roadSettings.branchChanceNoise = roadSettings.roadDensityNoise;
        roadSettings.roadEndChance = 0.001;
        roadSettings.placePerFrame = 3;
        
        roadSettings.roadSepMin = 15;
        roadSettings.roadSepMax = 100;
        
        roadSettings.roadStartSepMin = 25;
        roadSettings.roadStartSepMax = 150;
        
        buildingsSettings.placePerFrame = 5;
        buildingsSettings.endP = 0.0005;
        buildingsSettings.endCount = 50;
        buildingsSettings.boundary = 2;
    }
}

// Settings aimed at creating a modern style grid city (only kind of works)
class CitySettings extends Settings {
    
    public CitySettings(int w, int h) {
        super(w, h);
        waterLevel = 0;
        heightmapSettings.mainNoise = new NoiseMask(NoiseTriFuncs.MASK, 
                                          new Noise(mainRandom.nextLong()).setScale(0.06).setOctaves(8).setRoughness(1.6), 
                                          new NoiseGradient(mainRandom.nextFloat()*TWO_PI, w, h),
                                          new NoiseConstant(0.95));
        heightmapSettings.waterChance = 0;
        lineJitterNoise = new NoiseConstant(0.5);
        
        roadSettings.roadDensityNoise = new NoiseConstant(1);
        roadSettings.branchChanceNoise = roadSettings.roadDensityNoise;
        roadSettings.minStartHeight = 0;
        roadSettings.maxStartHeight = 1;
        
        roadSettings.roadSepMin = 50;
        roadSettings.roadSepMax = 50;
        
        roadSettings.roadStartSepMin = 50;
        roadSettings.roadStartSepMax = 50;
        
        roadSettings.roadEndChance = 0;
        roadSettings.crossRoadChance = 1;
        
        roadSettings.placePerFrame = 10;
        
        buildingsSettings.endP = 0.0001;
        
        buildingsSettings.buildWidthMin = 20;
        buildingsSettings.buildWidthMax = 35;
        buildingsSettings.buildLengthMin = 20;
        buildingsSettings.buildLengthMax = 35;
        buildingsSettings.buildPathMin = 1;
        buildingsSettings.buildPathMax = 5;
        buildingsSettings.boundary = 2;
        buildingsSettings.placePerFrame = 20;
    }
}
