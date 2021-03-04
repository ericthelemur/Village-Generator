class BuildingGenerator implements IGeneratorStep {
    Settings.BuildingsSettings buildingsSettings = settings.buildingsSettings;
    
    // Stores the possible positions of roads
    WeightedPicker<RoadPos> buildingPoints;
    
    int c = 10000;    // Total iteration max
    int endCount;     // Counts how many times a random value has fallen below buildingsSettings.endP each time a building is placed. This evens the distribution, while still keeping it random
    boolean end = false;
    
    // Random to use
    Random r;
    
    public BuildingGenerator(Random r) {
        this.r = r;
    }
    
    public void initGen() {
        // Add road points to buildingPoints, reject randomly based on roadDensity (distance to centre)
        endCount = buildingsSettings.endCount;
        buildingPoints = new WeightedPicker<RoadPos>(r.nextLong());
        for (StreamLine road : roads) {
            for (Point sp : road.points) {        // For every point on every road, reject randomly based on density distribution
                float d = settings.roadSettings.roadDensityNoise.eval(sp.x, sp.y)/2;
                if (r.nextFloat() < d) {
                    RoadPos rp = new RoadPos(sp.x, sp.y, heightmap.getFieldGrad(sp.x, sp.y, road.field));
                    buildingGenerator.buildingPoints.add(rp, sqrt(d));
                }
            }
        }
    }
    
    // Run every frame while on this generator step
    public void run() {
        if (c-- <= 0 || buildingPoints.isEmpty()) {    // If run too many iterations, end. Very unlikely to happen, but not entirely impossible
            end = true;
            return;
        }
        
        int toPlace = buildingsSettings.placePerFrame;    // Place buildingsSettings.placePerFrame buildings per draw iteration
        while (toPlace > 0 && !buildingPoints.isEmpty()) {
            RoadPos point = buildingPoints.pickRemove();    // Select location, weighted towards centre
            if (point.gradient == null) continue;
            
            // Create building with random parameters
            float bw = random(r, buildingsSettings.buildWidthMin, buildingsSettings.buildWidthMax);
            float bh = random(r, buildingsSettings.buildLengthMin, buildingsSettings.buildLengthMax);
            
            float bAngle = point.gradient.heading() + (r.nextFloat() < 0.5 ? -HALF_PI : +HALF_PI);
            float pathLength = random(r, buildingsSettings.buildPathMin, buildingsSettings.buildPathMax);
            Building b = new Building(point, bAngle, pathLength, bw, bh);
            
            // If can place this building, add to lists
            if (canPlaceBuilding(b)) {
                buildings.add(b);
                toPlace--;    // Decrement counter for this frame
                if (r.nextFloat() < buildingsSettings.endP) 
                    endCount--;
            }
            
            // If enough random checks have been hit, end the stage here.
            if (endCount <= 0) {
                end = true;
                return;
            }
        }
    }
    
    // Checks local constraints of a building
    boolean canPlaceBuilding(Building b) {
        // Calculate the expanded building to include a boundary
        Building withBound = b.addBoundary(buildingsSettings.boundary);
        
        // If too close to a builing, cannot place
        for (Building other : buildings) {
            if (withBound.intersects(other)) return false;
        }
        
        // If too close to a road, cannot place
        for (StreamLine sl : roads) {
            if (withBound.intersects(sl)) return false;
        }
        
        // If over water, cannot place
        for (Point c : withBound.corners) {
            if (heightmap.get(c) < settings.waterLevel) return false;
        }
        return true;
    }
    
    // Clear any remaining candidate points when ending
    public void endGen() {
        buildingPoints.clear();
        println("Placed", buildings.size(), "buildings");
    }
    
    public boolean ended() {
        return end;
    }
}

// Stores a possible position to place a house, stores the location on the road, and the vector on the road
// The building is attempted to be placed between buildingsSettings.buildPathMin and buildingsSettings.buildPathMax distnace perpendicular to gradient
class RoadPos extends Point {
    public Gradient gradient;
    
    public RoadPos(float x, float y, Gradient g) {
        super(x, y);
        gradient = g;
    }
    
    public String toString() {
        return "RoadPos (" + x + ", " + y + ") grad:" + gradient;
    }
}
