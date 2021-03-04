// Stores a streamline (road)
class StreamLine extends PolyLine {
    private Field field;    // Field road is following: either major or minor
    
    // Constructs from list of points (can be empty)
    public StreamLine(Field field, Point... initial) {
        super(initial);
        this.field = field;
        removeDoubles = false;
    }
    
    // Adds a point to an end dictated by dir
    public void addPoint(Point point, FDir dir) {
        addPoint(point, dir == FDir.POS);
    }
    
    // Gets a point from an end dictated by dir
    public Point getPoint(FDir dir) {
        return getPoint(dir == FDir.POS);
    }
    
    // Returns the field of the streamline
    public Field getField() {
        return field;
    }
    
    String toString() {
        return "StreamLine " + field + ": " + points.toString();
    }
}


// Stores which field something is on: major is along the gradient, minor is perpendicular to the gradient
// terminology from tensors
enum Field {
    MAJOR, MINOR;
    
    private static Field[] vals = values();
    public Field getAlt() {
        return vals[floorMod(this.ordinal()+1, vals.length)];
    }
}

// Stores which field something is running along a field or against it
enum FDir {
    POS, NEG;
    
    public FDir getOpposite() {
        if (this == FDir.POS) return FDir.NEG;
        else return FDir.POS;
    }
}

// Stores the direction something is going, both field and direction
enum FieldDir {
    MAJORPOS(Field.MAJOR, FDir.POS), MINORPOS(Field.MINOR, FDir.POS), 
    MAJORNEG(Field.MAJOR, FDir.NEG), MINORNEG(Field.MINOR, FDir.NEG);
    
    private Field f; 
    private FDir dir;
    
    private FieldDir(Field f, FDir dir) {
        this.f = f;
        this.dir = dir;
    }
    
    // https://stackoverflow.com/a/17006263
    private static FieldDir[] vals = values();    // Next in array of values
    public FieldDir getCWFieldDir() {
        return vals[floorMod(this.ordinal()+1, vals.length)];
    }
    
    public FieldDir getCCWFieldDir() {        // Previous in array of values
        return vals[floorMod(this.ordinal()-1, vals.length)];
    }
    
    public FieldDir getOppositeFieldDir() {      // Opposite in array of values
        return vals[floorMod(this.ordinal()+2, vals.length)];
    }
    
    public Field getField() {
        return f;
    }
    
    public FDir getDir() {
        return dir;
    }
}

// Converts a field and direction into a FieldDir
FieldDir toFieldDir(Field f, FDir d) {
    return FieldDir.values()[f.ordinal() + d.ordinal()*2];
}

// Just a rename of Point for consistency in treatment
class Gradient extends Point {
    public Gradient() {}
    
    public Gradient(float x, float y) {
        super(x, y);
    }
    
    public Gradient(Point p) {
        this(p.x, p.y);
    }
}
