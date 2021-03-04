// Class to represent a building
class Building implements IDrawable {
    // Stores the path to the road
    public JitterLine path;
    
    // Stores the house's corners
    public Point[] corners = new Point[4];
    
    // Construct based on the 4 corners, but no verification of whether it is rectangular or not, it is assumed it is
    public Building(Point c1, Point c2, Point c3, Point c4) {
        corners = new Point[] {c1, c2, c3, c4};
        path = new JitterLine(c1, c1);
    }
    
    // Construct based on road angle, distance from the road, and the dimensions of the building, corners is ordered clockwise from the front door
    public Building(Point fromCentre, float angle, float roadDist, float buildingWidth, float buildingHeight) {
        // Calculate path and front centre pos
        Point roadPoint = fromCentre;
        Point frontDoor = Point.add(fromCentre, Point.fromAngle(angle, roadDist));
        path = new JitterLine(roadPoint, frontDoor);
        
        Point halfFront = new Point(-buildingWidth/2 * sin(angle), buildingWidth/2 * cos(angle));
        corners[0] = Point.add(frontDoor, halfFront);
        corners[3] = Point.sub(frontDoor, halfFront);
        
        Point side = new Point(buildingHeight * cos(angle), buildingHeight * sin(angle));
        corners[1] = Point.add(corners[0], side);
        corners[2] = Point.add(corners[3], side);
    }
    
    // Construct based on centre angle and dimensions
    public Building(Point centre, float angle, float bW, float bH) {
        path = new JitterLine(centre, centre);
        
        Point fb = Point.fromAngle(angle);
        Point lr = Point.fromAngle(angle + PI);
        
        Point halfFront = Point.mult(fb, bH/2), halfSide = Point.mult(lr, bW/2);
        corners[0] = Point.add(Point.add(centre, halfFront), halfSide);
        corners[3] = Point.sub(Point.add(centre, halfFront), halfSide);
        
        corners[1] = Point.add(Point.sub(centre, halfFront), halfSide);
        corners[2] = Point.sub(Point.sub(centre, halfFront), halfSide);
    }
    
    // Inflate the building by boundary number of pixels, used for collision checking
     public Building addBoundary(float boundary) {
         // Calculate the offset vectors, assuming 0 -> 1 and 2 -> 3 are parallel, and 1 -> 2 and 3 -> 4
        Point fb = Point.sub(corners[0], corners[1]);
        fb.setMag(boundary);
        Point lr = Point.sub(corners[1], corners[2]);
        lr.setMag(boundary);
        
        // Add and subtract the vector to each point
        Building boundBuilding = new Building(Point.add(corners[0], fb, lr), 
                                              Point.sub(Point.add(corners[1], lr), fb), 
                                              Point.sub(Point.sub(corners[2], lr), fb), 
                                              Point.add(Point.sub(corners[3], lr), fb));
        return boundBuilding;
    }
    
    public void draw(float delta, PGraphics pg) {
        // Draws the path
        pg.stroke(#333333);
        pg.fill(#333333);
        pg.strokeWeight(1.5);
        path.draw(delta, pg);
        
        // Draws the rectangle
        pg.strokeWeight(2);
        pg.stroke(#333333);
        pg.fill(#333333);
        pg.beginShape();
        for (Point c : corners)
            pg.vertex(c.x, c.y);
        pg.endShape(CLOSE);
        
    }
    
    // Returns the normals of the rectangle (along each side)
    public Point[] getNormals() {
        Point[] normals = new Point[2];
        normals[0] = getNormal(corners[0], corners[1]);
        normals[1] = getNormal(corners[1], corners[2]);
        
        return normals;
    }
    
    // Adapted from: http://www.dyn4j.org/2010/01/sat/ and https://gamedev.stackexchange.com/a/60225
    // Intersection checking works by projecting both shapes onto the normal vectors of both, and if there is an overlap in all normals, they intersect (Separating Axis Theorem)
    public boolean intersects(Building b) {
        return this.intersects_(b) && b.intersects_(this);
    }
    
    public boolean intersects_(Building b) {
        Point[] normals = getNormals();
                
        for (Point normal : normals) {    // For all of this shapes normals
            Range thisProj = this.project(normal);
            Range otherProj = b.project(normal);    // Check for overlap in projection
            
            if (thisProj.overlaps(otherProj)) 
                return false;
        }
        return true;
    }
    
    // Calculates the max and min values of projecting this shape onto a vector
    public Range project(Point normal) {
        float m = normal.dot(corners[0]);
        float min = m, max = m;
        
        for (int i = 1; i < corners.length; i++) {    // Project each point, as shape is convex, and has no curves, the outermost point is always a corner
            float p = normal.dot(corners[i]);
            if (p < min) min = p;
            if (p > max) max = p;
        }
        return new Range(min, max);
    }
    
    // Intersection with line is the same as intersecting with a rectangle of no width
    public boolean intersects(Point p1, Point p2) {
        return intersects(new Building(p1, p2, p1, p2));
    }
    
    // Intersection with line is the same as intersecting with a rectangle of no width
    public boolean intersects(Line l) {
        return intersects(l.p1, l.p2);
    }
    
    // Intersection with streamline requires checking all lines
    public boolean intersects(StreamLine sl) {
        for (Line l : sl.getLines()) {
            if (intersects(l)) return true;
        }
        return false;
    }
}
