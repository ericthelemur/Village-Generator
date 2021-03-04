// Represents a point, this is effectively the same as PVector, but with a bit more QoL
public static class Point implements IDrawable {
    float x, y;
    
    // Constructors
    public Point() {
        x = 0;
        y = 0;
    }
    
    public Point(Point p) {
        this(p.x, p.y);
    }
    
    public Point(float x, float y) {
        this.x = x;
        this.y = y;
    }
    
    // Constructs from an angle and magnitude
    public static Point fromAngle(float angle, float mag) {
        return new Point(cos(angle) * mag, sin(angle) * mag);
    }
    
    // Constructs from an angle, with magnitude 1
    public static Point fromAngle(float angle) {
        return fromAngle(angle, 1);
    }
    
    // Returns the angle of the vector, from +ve x
    public float heading() {
        return atan2(y, x);
    }
    
    
    // Returns a new point that is the sum of p1 and p2
    public static Point add(Point p1, Point p2) {
        return new Point(p1.x + p2.x, p1.y + p2.y);
    }
    
    // Returns a new point that is the sum of all points in points
    public static Point add(Point... points) {
        Point p = new Point(points[0]);
        for (int i = 1; i < points.length; i++)
            p.add(points[i]);
        return p;
    }
    
    // Returns a new point that is the sum of p1 and (ox, oy)
    public static Point add(Point p1, float ox, float oy) {
        return new Point(p1.x + ox, p1.y + oy);
    }
    
    // Adds (ox, oy) to this point
    public void add(float ox, float oy) {
        x += ox;
        y += oy;
    }
    
    // Adds p to this point
    public void add(Point p) {
        add(p.x, p.y);
    }
    
    // Returns the average point of all points in points
    public static Point midpoint(Point... points) {
        return Point.div(Point.add(points), points.length);
    }
    
    
    // Returns a new point that is p1 - p2
    public static Point sub(Point p1, Point p2) {
        return new Point(p1.x - p2.x, p1.y - p2.y);
    }
    
    // Returns a new point that is p1 - (ox, oy)
    public static Point sub(Point p1, float ox, float oy) {
        return new Point(p1.x - ox, p1.y - oy);
    }
    
    // Subtracts (ox, oy) from this point
    public void sub(float ox, float oy) {
        x -= ox;
        y -= oy;
    }
    
    // Subtracts p from this point
    public void sub(Point p) {
        sub(p.x, p.y);
    }
    
    
    // Returns a new point that is this point multiplied by factor f
    public static Point mult(Point p1, float f) {
        return new Point(p1.x * f, p1.y * f);
    }
    
    // Multiplies this point by factor f
    public void mult(float f) {
        x *= f;
        y *= f;
    }
    
    // Returns a new point that is this point divided by factor f
    public static Point div(Point p1, float f) {
        return new Point(p1.x / f, p1.y / f);
    }
    
    // Divides this point by factor f
    public void div(float f) {
        x /= f;
        y /= f;
    }
    
    
    // Calculates the magnitude of vector (x, y) squared: more efficient that the magnitude
    public static float magSq(float x, float y) {
        return x*x + y*y;
    }
    
    // Calculates the magnitude of this vector squared: more efficient that the magnitude
    public float magSq() {
        return magSq(x, y);
    }
    
    // Calculates the magnitude of vector (x, y)
    public static float mag(float x, float y) {
        return sqrt(magSq(x, y));
    }
    
    // Calculates the magnitude of this vector
    public float mag() {
        return sqrt(magSq());
    }
    
    // Normalizes this point, so it has a magnitude of 1
    public void normalize() {
        this.div(mag());
    }
    
    // Returns a copy of p normalized
    public static Point normalize(Point p) {
        return Point.div(p, p.mag());
    }
    
    // Sets the magnitude of this vector to be m
    public void setMag(float m) {
        normalize();
        mult(m);
    }
    
    
    // Calculates the distance between this vector and (ox, oy) squared: more efficient that the magnitude
    public float distSq(float ox, float oy) {
        return Point.sub(this, ox, oy).magSq();
    }
    
    // Calculates the distance between this vector and p squared: more efficient that the magnitude
    public float distSq(Point p) {
        return Point.sub(this, p).magSq();
    }
    
    // Calculates the distance between this vector and (ox, oy)
    public float dist(float ox, float oy) {
        return sqrt(distSq(ox, oy));
    }
    
    // Calculates the distance between this vector and p
    public float dist(Point p) {
        return dist(p.x, p.y);
    }
    
    
    // Calculates the dot product of this vector and (ox, oy)
    public float dot(float ox, float oy) {
        return x * ox + y * oy;
    }
    
    // Calculates the dot product of this vector and point p
    public float dot(Point p) {
        return dot(p.x, p.y);
    }
    
    
    // Returns whether this point is contained in rectangle r
    public boolean in(Rect r) { 
        return r.x < x && x < r.x2 && r.y < y && y < r.y2;
    }
    
    
    public static Point perp(float x, float y) {
        return new Point(y, -x);
    }
    
    public Point perp() {
        return new Point(y, -x);
    }
    
    
    String toString() {
        return "Point (" + x + ", " + y + ")";
    }
    
    public void draw(float delta, PGraphics pg) {
        pg.circle(x, y, 2);
    }
}
