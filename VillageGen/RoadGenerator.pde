class RoadGenerator implements IGeneratorStep {
    // Queue of road ends to expand
    PriorityQueue<StreamPQElem> pq;
    // List of possible road starting points
    WeightedPicker<StreamPossStart> starts;
    Random r;
    boolean end = false;
    
    // Settings
    public Settings.RoadSettings roadSettings = settings.roadSettings;
    
    public RoadGenerator(Random r) {
        this.r = r;
    }
    
    public void initGen() {
        pq = new PriorityQueue<StreamPQElem>();
        starts = new WeightedPicker<StreamPossStart>(r.nextLong());
        
        // Pick initial starting position: not too near water and not too high, as that is where anomalous results happen the most
        int x, y;
        float v;
        do {
            x = r.nextInt(settings.w);
            y = r.nextInt(settings.h);
            v = heightmap.get(x, y);
        } while(v < roadSettings.minStartHeight || roadSettings.maxStartHeight < v);
        println("Starting at ("+x+", " + y+")");
        
        // Construct initial position, point to trace from, the road (streamline) it traces along, and add to structures
        Point p = new Point(x, y);
        StreamLine initial = new StreamLine(Field.MINOR, p);
        
        roads.add(initial);
        
        pq.add(new StreamPQElem(0f, initial, FDir.POS));
        pq.add(new StreamPQElem(0f, initial, FDir.NEG));
        float d = roadSettings.roadDensityNoise.eval(p.x, p.y);
        starts.add(new StreamPossStart(p, initial, FieldDir.MAJORPOS, 0), d);
        starts.add(new StreamPossStart(p, initial, FieldDir.MAJORNEG, 0), d);
    }
    
    
    public void run() {    // Called every draw cycle (or more if on fast mode)
        int toPlace = roadSettings.placePerFrame;
        while (toPlace > 0) {            // Keep placing until enough roads have been placed for the frame
            if (starts.isEmpty()) {    // If not more road start candidates, end here
                end = true;
                return;
            }
            
            while (!pq.isEmpty()) {        // Trace road until no more remaining
                StreamPQElem elem = pq.remove();    // Get next candidate position
                
                if (elem.weight > 10000) continue;    // If waaay too many iterations have happened
                StreamLine line = elem.line;
                Point loc = line.getPoint(elem.dir);    // Get point at correct end of line, for the dir
                
                // Once the first road has been placed, randomly end a road based on roadSettings.roadEndChance
                if (roads.size() > 1 && r.nextFloat() < roadSettings.roadEndChance * (1-map(roadSettings.roadDensityNoise.eval(loc.x, loc.y), 0.1, 1, 0, 1)))
                    continue;
                
                // Get direction
                FDir dir = elem.dir;
                FieldDir fd = toFieldDir(line.field, dir);
                
                // Get gradient and scale to step dist (this value could be )
                Gradient gradient = heightmap.rk4FieldVector(loc, fd);
                gradient.setMag(roadSettings.stepDist);
                
                // Calculate new point based on 
                Point newPoint = new Point(loc.x + gradient.x, loc.y + gradient.y);
                
                // If new point is able to be placed
                if (localCheck(newPoint, line, line.getField(), roadSettings.roadSepMin, roadSettings.roadSepMax)) {
                    // Add to road and as new end point in queue
                    line.addPoint(newPoint, dir);
                    pq.add(new StreamPQElem(elem.weight+1, line, dir));
                    
                    // Randomly create a start point perpendicular to this point
                    float b = roadSettings.branchChanceNoise.eval(loc.x, loc.y);
                    if (r.nextFloat() < b)
                        starts.add(new StreamPossStart(loc, line, fd.getCWFieldDir(), elem.weight+1), b);
                    
                    if (r.nextFloat() < b)
                        starts.add(new StreamPossStart(loc, line, fd.getCCWFieldDir(), elem.weight+1), b);
                    
                    toPlace--;
                }
            }
            
            StreamPossStart picked;
            boolean valid = false;
            
            // Repeat until a valid location is picked
            do {
                picked = starts.pickRemove();    // Pick start position
                if (picked == null) {
                    end = true;
                    return;
                }
                
                // Calculate next point
                Gradient gradient = heightmap.rk4FieldVector(picked.sp, picked.fd);
                gradient.setMag(roadSettings.stepDist);
                
                Point newPoint = new Point(picked.sp.x + gradient.x, picked.sp.y + gradient.y);
                
                // Randomly reject if a random number squared is less than v, squaring makes it a bit more likely reject
                float v = map(roadSettings.roadDensityNoise.eval(picked.sp.x, picked.sp.y), 0.1, 1, 0, 1);
                float rv = r.nextFloat();
                if (rv*rv > v) continue;
                // Check point
                valid = localCheck(newPoint, picked.sl, picked.sl.getField().getAlt(), roadSettings.roadStartSepMin, roadSettings.roadStartSepMax);
            } while (!valid && !starts.isEmpty());
            
            // If picked position is valid (loop could have exited because no more positions)
            if (valid ) {
                StreamLine sl = new StreamLine(picked.sl.getField().getAlt(), picked.sp);
                pq.add(new StreamPQElem(picked.weight, sl, picked.fd.getDir()));
                
                // Add crossroad if chance passes
                float d = roadSettings.roadDensityNoise.eval(picked.sp.x, picked.sp.y);
                if (r.nextFloat() < roadSettings.crossRoadChance * (1-d))
                    pq.add(new StreamPQElem(picked.weight, sl, picked.fd.getDir().getOpposite()));
                roads.add(sl);
                
            } else {    // No remaining possible start positions, so move on
                end = true;
                return;
            }
        }
    }
    
    // Check the local conditions for a point:
    //     - Inside map
    //     - Not water
    //     - Does not get too close to parallel lines
    //     - Does not get too close to itself
    boolean localCheck(Point p, StreamLine line, Field f, float minSep, float maxSep) {
        // If on map
        if (p.x < 0 || settings.w < p.x || p.y < 0 || settings.h < p.y) return false;
        
        // If water
        if (heightmap.get(p) < settings.waterLevel + 0.05)
            return false;
        
        for (StreamLine other : roads) {
            // If too close to parallel line, dictated by roadDensityNoise
            if (other.field == f && other != line) {
                float d = map(roadSettings.roadDensityNoise.eval(p.x, p.y), 0.1, 1, minSep, maxSep);
                if (other.pointDist(p) < d) 
                    return false;
            // If too close to itself
            } else if (other == line) {
                if (other.pointDist(p) < roadSettings.stepDist * 0.75)
                    return false;
            }
        }
        return true;
    }
    
    public void endGen() {
        println("Placed", roads.size(), "roads");
    }
    
    public boolean ended() {
        return end;
    }

}

// Class to store the data of a position in the point queue:
//     - The weighting of the point
//     - The line that is being traced
//     - and which end of the line is being traced (+ve or -ve)
class StreamPQElem implements Comparable<StreamPQElem> {
    float weight;
    StreamLine line;
    FDir dir;
    
    public StreamPQElem(float w, StreamLine l, FDir d) {
        weight = w;
        line = l;
        dir = d;
    }
    
    public int compareTo(StreamPQElem other) {
        return Float.compare(weight, other.weight);
    }
    
    public boolean equals(StreamPQElem other) {
        return compareTo(other) == 0;
    }
    
    public String toString() {
        return "StreamPQElem (w: " + weight + ", dir: " + dir + ", line: " +  line + ")";
    }
}

// Class to store the data of a possible start position:
//     - The position being considered
//     - The line it is on
//     - which field and which end of the line is being traced (+ve or -ve)
//     - The weighting of the point
class StreamPossStart {
    Point sp;
    StreamLine sl;
    FieldDir fd;
    float weight;
    
    public StreamPossStart(Point sp, StreamLine sl, FieldDir fd, float weight) {
        this.sp = sp;
        this.sl = sl;
        this.fd = fd;
        this.weight = weight;
    }
    
    String toString() {
        return "StreamPossStart point=" + sp + " dir: " + fd;
    }
}
