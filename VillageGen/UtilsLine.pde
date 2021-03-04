// Gets the normalized normal vector of a line between c1 and c2
Point getNormal(Point c1, Point c2) {
    Point diff = Point.sub(c2, c1);
    diff.normalize();
    return new Point(-diff.y, diff.x);
}

// Represents  a line between point p1 and point p2
class Line implements IDrawable {
    Point p1, p2;
    
    public Line(Point p1, Point p2) {
        this.p1 = p1;
        this.p2 = p2;
    }
    
    void draw(float delta, PGraphics pg) {
        pg.line(p1.x, p1.y, p2.x, p2.y);
    }
    
    public Line translate(Point t) {
        return translate(t.x, t.y);
    }
    
    // Adds x to both x values and y to both y values
    public Line translate(float x, float y) {
        return new Line(new Point(p1.x + x, p1.y + y), 
                        new Point(p2.x + x, p2.y + y)
        );
    }
    
    public Point midpoint() {
        return new Point((p1.x + p2.x)/2, (p1.y + p2.y)/2);
    }
    
    public String toString() {
        return "Line from " + p1 + " to " + p2;
    }
    
    // Calculates how many multiples of one vector the intersection point along it. If this is between 0 and 1 for both vectors, they intersect
    public boolean intersects(Line other) {
        Point p3 = other.p1, p4 = other.p2;
        
        // https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection#Given_two_points_on_each_line
        Point p3ToP1 = Point.sub(p1, p3);
        Point p4ToP3 = Point.sub(p3, p4);
        Point p2ToP1 = Point.sub(p1, p2);
        
        Point T = new Point(p4ToP3.y, -p4ToP3.x);
        // t = (p3p1.x*p4p3.y - p3p1.y*p4p3.x) / (p2p1.x*p4p3.y - p2p1.y * p4p3.x);
        
        float t = T.dot(p3ToP1) / T.dot(p2ToP1);
        Point U = new Point(p2ToP1.y, -p2ToP1.x);
        // u = - (p2p1.x*p3p1.y - p2p1.y*p3p1.x) / (p2p1.x*p4p3.y - p2p1.y * p4p3.x);
        float u = - U.dot(p3ToP1) / U.dot(p4ToP3);
        
        return 0 < t && t < 1 && 0 < u && u < 1;
    }
}

// Line with a random offset along it's length, by offsetting the midpoint of the interval by a random amount, then offsetting the remaining interval's midpoints by a smaller random amount
class JitterLine extends Line {
    Point[] points;
    public JitterLine(Point p1, Point p2) {
        super(p1, p2);
        calculateSubDivs(3, 3);
    }
    
    // Calculates the offset points inside the line
    void calculateSubDivs(int level, float disp) {
        Point diff = Point.sub(p2, p1);    // Calculate difference vector
        Point perp = new Point(diff.y, -diff.x);    // Calculate the perpendicular vector
        perp.normalize();
        
        points = calculateSubDivs(new Point[] {p1, p2}, level, disp, perp);     // Recursively sub divide
    }
    
    // Subdivides each line in points, into 2^level pieces
    Point[] calculateSubDivs(Point[] points, int level, float disp, Point perp) {
        if (level <= 0) return points;
        
        // Create new array, and copies in the previous values, with 1 empty space between each
        Point[] newPoints = new Point[2 * points.length - 1];
        for (int i = 0; i < points.length; i++)
            newPoints[i*2] = points[i];
        
        // Calculates the mid points, and fills array
        for (int i = 1; i < newPoints.length-1; i += 2) {
            Point v1 = newPoints[i-1], v2 = newPoints[i+1];
            Point v3 = Point.add(v1, v2);
            v3.div(2);
            
            float dmag = settings.lineJitterNoise.eval(v3.x*10000, v3.y*10000)*2 - 1;    // Gets offset from noise, but very high frequency, so almost random, but still deterministic
            v3.add(Point.mult(perp, dmag * disp));    // Offset point perpendicular to normal of original line
            newPoints[i] = v3;
        }
        // Recursive call
        return calculateSubDivs(newPoints, level - 1, disp/2, perp);
    }

    // Draws the line
    void draw(float delta, PGraphics pg) {
        pg.beginShape();
        for (Point p : points) {
            pg.vertex(p.x, p.y);
        }
        
        pg.endShape();
    }
}

// Class representing a line made up of many points
class PolyLine implements IDrawable {
    LinkedList<Point> points = new LinkedList<Point>();    // Points in road
    boolean removeDoubles = true;
    
    // Constructs from list of points (can be empty)
    public PolyLine(Point... initial) {
        for (Point v : initial) {
            points.addLast(v);
        }
    }
    
    // Adds a point to an end dictated by dir
    public void addPoint(Point point, boolean toEnd) {
        if (toEnd)
            points.addLast(point);
        else
            points.addFirst(point);
    }
    
    // Adds all points in ps to 
    public void addAllPoints(List<Point> ps, boolean onEnd) {
        if (onEnd) {
            for (Point p : ps) 
                points.addLast(p);
        } else {
            for (Point p : ps) 
                points.addFirst(p);
        }
    }
    
    // Gets a point from an end dictated by dir
    public Point getPoint(boolean fromEnd) {
        if (fromEnd)
            return points.getLast();
        else
            return points.getFirst();
    }
    
    // Draws the lines
    public void draw(float delta, PGraphics pg) {
        if (points.size() <= 1) return;
        pg.noFill();
        pg.beginShape();
        
        Point prev = null;
        for (Point p : points) {    // Draw each point, if it is not too close to the previous point
            if (!(removeDoubles && epsilonEquals(p, prev, settings.heightmapSettings.contourDuplicatePointRadius))) {
                pg.vertex(p.x, p.y);
                prev = p;
            }
        }
        
        pg.endShape();
    }
    
    // Checks intersection with a line
    public boolean intersects(Line line) {
        for (Line l2 : getLines()) {
            if (line.intersects(l2))
                return true;
        }
        return false;
    }
    
    // Returns the closest point to a point on this streamline, approximately the closest point (since each point is so close together)
    public Point closestPoint(Point point) {
        float dst = Float.MAX_VALUE;
        Point closest = null;
        for (Point p : points) {
            float pd = p.dist(point);
            if (pd < dst) {
                dst = pd;
                closest = p;
            }
        }
        return closest;
    }
    
    // Returns the distance to the closest point to a point
    public float pointDist(Point point) {
        return closestPoint(point).dist(point);
    }
    
    // Returns the points as an array
    public Point[] getPoints() {
        return points.toArray(new Point[0]);
    }
    
    // Returns the lines that make up this streamline
    public Line[] getLines() {
        Line[] lines = new Line[points.size()-1];
        
        Iterator<Point> iterator = points.iterator();
        Point prev = iterator.next();    // Record the previous point
        
        int i = 0;
        while(iterator.hasNext()) {    // For each point, add a line between this point and the previous point
            Point v = iterator.next();
            lines[i++] = new Line(prev, v);
            prev = v;
        }
        
        return lines;
    }
    
    String toString() {
        return "StreamLine: " + points.toString();
    }
}
