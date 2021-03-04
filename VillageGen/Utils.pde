// Interface for objects that can be drawn
interface IDrawable {
    void draw(float delta, PGraphics pg);
}

// Function that takes 3 arguments: java.function only goes up to BiFunction
@FunctionalInterface
interface TriFunction<A,B,C,D> {
    public D apply(A a, B b, C c);
}

// Interface for a step of generation
interface IGeneratorStep extends Runnable {
    public boolean ended();
    public void initGen();
    public void endGen();
}

// https://en.wikipedia.org/wiki/Smoothstep
// Cubic interpolation
float smoothstep(float x) {
    if (x < 0) return 0;
    if (x > 1) return 1;
    // 3x^2 - 2x^3
    else return x*x*(3 - 2*x);
}

// Calculates the min and max of an array, and returns it in a pair
Range minAndMax(float... vals) {
    if (vals.length == 0) return null;
    float maxVal = vals[0], minVal = vals[0];
    for (int i = 1; i < vals.length; i++) {
        float v = vals[i];
        if (v < minVal) minVal = v;
        if (v > maxVal) maxVal = v;
    }
    return new Range(minVal, maxVal);
}

// Random value between min and max using r
float random(Random r, float min, float max) {
    return min + r.nextFloat() * (max - min);
}

public static String capitalize(String string) {
    StringBuilder capitalized = new StringBuilder();
    capitalized.append(Character.toUpperCase(string.charAt(0)));
    for (int i = 1; i < string.length(); i++) {
        if (!Character.isLetter(string.charAt(i-1))) capitalized.append(Character.toUpperCase(string.charAt(i)));
        else capitalized.append(Character.toLowerCase(string.charAt(i)));
    }
    return capitalized.toString();
}

// Class for an axis-aligned rectangle
class Rect implements IDrawable {
    // Properties
    float x, y, w, h, x2, y2, cx, cy;
    
    public Rect(float x, float y, float w, float h) {
        this.x = x;
        this.y = y;
        setWidth(w);
        setHeight(h);
    }
    
    public Rect(Point p1, Point p2) {
        this(p1.x, p1.y, p2.x - p1.x, p2.y - p1.y);
    }
    
    public boolean contains(Point p) {
        return p.in(this);
    }
    
    public boolean intersects(Rect p) {
        return x2 < p.x || p.x2 < x || y2 < p.y || p.y2 < y;
    }
    
    public void draw(float delta, PGraphics pg) {
        pg.rect(x, y, w, h);
    }
    
    // Sets width and updates relevant properties
    public void setWidth(float w) {
        this.w = w;
        x2 = x+w;
        cx = x + w/2;
    }
    
    // Sets height and updates relevant properties
    public void setHeight(float h) {
        this.h = h;
        y2 = y+h;
        cy = y + h/2;
    }
    
    // Sets x and updates relevant properties
    public void setX(float x) {
        this.x = x;
        x2 = x+w;
        cx = x + w/2;
    }
    
    // Sets y and updates relevant properties
    public void setY(float y) {
        this.y = y;
        y2 = y+h;
        cy = y + h/2;
    }
}

// Class representing a pair of values with type T and U
class Pair<T, U> {
    public T t;
    public U u;
    
    public Pair(T t, U u) {
        this.t = t;
        this.u = u;
    }
    
    public T first() {
        return t;
    }
    
    public U last() {
        return u;
    }
    
    // Equality is checked with the first value in the pair
    public boolean equals(Pair<T, U> p) {
        return t.equals(p.first());
    }
}

// Homogenous pair: both elements are of the same type
class HPair<T> extends Pair<T, T> {
    public HPair(T t1, T t2) {
        super(t1, t2);
    }
}

// Represents a range of values with a max and min
class Range extends HPair<Float> {
    public Range(float min, float max) {
        super(min, max);
    }
    
    public float min() {
        return t;
    }
    
    public float max() {
        return u;
    }
    
    public boolean overlaps(Range other) {
        return !(this.min() < other.max() && other.min() < this.max());
    }
}
