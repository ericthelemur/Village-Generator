
/* 
   0 Noise params
*/

// A constant value
class NoiseConstant implements INoise {
    private float val;

    public NoiseConstant(float c) {
        val = c;
    }

    public float eval(float x, float y) {
        return val;
    }
}

// Returns a random value for each point
class NoiseRandom implements INoise {
    private Random r;

    public NoiseRandom(Long seed) {
        r = new Random(seed);
    }

    public float eval(float x, float y) {
        return r.nextFloat();
    }
}

// A flat gradient with angle angle, such that 1 is the largest value in the rectangle w x h, and 0 is the smallest
class NoiseGradient implements INoise {
    private Point vector;
    private float minVal, maxVal;
    private Point centre;
    
    public NoiseGradient(float angle, float w, float h) {
        vector = Point.fromAngle(angle);
        float hw = w/2, hh = h/2;
        centre = new Point(hw, hh);
        // max value is one of the corners, but only needs to consider 2, as the others are symmetrical through the centre
        maxVal = max(abs(vector.dot(new Point(-hw, -hh))), abs(vector.dot(new Point(-hw, hh))));
        minVal = -maxVal;
    }
    
    // Get dot product of vector with the vector from (x, y) to the centre
    public float eval(float x, float y) {
        return map(vector.dot(x - centre.x, y - centre.y), minVal, maxVal, 0, 1);
    }
}

// A radial gradient with centre centre, such that 1 is the largest value in the rectangle w x h, and 0 is the smallest
class NoiseRadialGradient implements INoise {
    private Point centre;
    private float minDist, maxDist;
    
    public NoiseRadialGradient(Point centre, float w, float h) {
        this.centre = centre;
        
        // Calculate min and max, is going to be a corner, if the centre is outside the screen
        Range minMax = minAndMax(centre.dist(new Point(0, 0)), centre.dist(new Point(0, h)), centre.dist(new Point(w, 0)), centre.dist(new Point(w, h)));
        minDist = minMax.first();
        maxDist = minMax.last();
        
        if (0 < centre.x && centre.x < w && 0 < centre.y && centre.y < h) {
            minDist = 0;
        }
    }
    
    // Take dist and smoothstep (cubic interpolate) it
    public float eval(float x, float y) {
        return 1-smoothstep(map(centre.dist(new Point(x, y)), minDist, maxDist, 0, 1));
    }
}

/* 
   1 Noise param
*/

// Base class for transformations that take a function, which is applied to a single noise input
class NoiseTransform implements INoise {
    private Function<Float, Float> f;
    private INoise input;

    public NoiseTransform(Function<Float, Float> f, INoise input) {
        this.f = f;
        this.input = input;
    }
    
    public NoiseTransform(NoiseFuncs f, INoise input) {
        this(f.getFunc(), input);
    }

    public float eval(float x, float y) {
        return f.apply(input.eval(x, y));
    }
}

// Common noise transformations, squaring, billow (makes large areas of high values, with smaller gaps of low values), and ridged (opposite to billow, good for mountains)
enum NoiseFuncs {
    SQUARED(new Function<Float, Float>() {Float apply(Float f) {
            return f*f;
        }}),
    // Turns noise mountainous, with sharp peaks and flatter valleys
    RIDGED(new Function<Float, Float>() {Float apply(Float f) {
            return abs(f*2-1);
        }}),
    // Opposite of ridged
    BILLOW(new Function<Float, Float>() {Float apply(Float f) {
            return abs(f*2-1);
        }});

        private Function<Float, Float> f;

    private NoiseFuncs(Function<Float, Float> f) {
        this.f = f;
    }
    
    public Function<Float, Float> getFunc() {
        return f;
    }
}

// Multiplies input by constant c
class NoiseMult extends NoiseTransform {
    public NoiseMult(final float c, INoise input) {
        super(new Function<Float, Float>() {Float apply(Float f) {
            return f*c;
        }}, input);
    }
}

// Maps input from range [oldMin, oldMax] to [newMin, newMax]
class NoiseMap extends NoiseTransform {
    public NoiseMap(final float oldMin, final float oldMax, final float newMin, final float newMax, INoise input) {
        super(new Function<Float, Float>() {Float apply(Float f) {
            return map(f, oldMin, oldMax, newMin, newMax);
        }}, input);
    }
}

// Adds constant c to input
class NoiseAdd extends NoiseTransform {
    public NoiseAdd(final float c, INoise input) {
        super(new Function<Float, Float>() {Float apply(Float f) {
            return f+c;
        }}, input);
    }
}

// Raises input to c
class NoisePow extends NoiseTransform {
    public NoisePow(final float c, INoise input) {
        super(new Function<Float, Float>() {Float apply(Float f) {
            return pow(f, c);
        }}, input);
    }
}

// Raises input to c
class NoiseFold extends NoiseTransform {
    public NoiseFold(final float c, INoise input) {
        super(new Function<Float, Float>() {Float apply(Float f) {
            return f > c ? f : 2 * c - f;
        }}, input);
    }
}

/* 
   2 Noise params
*/

// Base class for combinations that take a function, which is applied to 2 noise inputs
class NoiseCombine implements INoise {
    private BiFunction<Float, Float, Float> f;
    private INoise input1;
    private INoise input2;

    public NoiseCombine(BiFunction<Float, Float, Float> f, INoise input1, INoise input2) {
        this.f = f;
        this.input1 = input1;
        this.input2 = input2;
    }
    
    public NoiseCombine(NoiseBiFuncs f, INoise input1, INoise input2) {
        this(f.getFunc(), input1, input2);
    }

    public float eval(float x, float y) {
        return f.apply(input1.eval(x, y), input2.eval(x, y));
    }
}

// Common noise combination functions
enum NoiseBiFuncs {
    // Multiply
    MULT(new BiFunction<Float, Float, Float>() {Float apply(Float v1, Float v2) {
            return v1*v2;
        }}), 
    // Add
    ADD(new BiFunction<Float, Float, Float>() {Float apply(Float v1, Float v2) {
            return v1+v2;
        }}), 
    // Subtract
    SUB(new BiFunction<Float, Float, Float>() {Float apply(Float v1, Float v2) {
            return v1-v2;
        }}), 
    // Min value
    MIN(new BiFunction<Float, Float, Float>() {Float apply(Float v1, Float v2) {
            return min(v1, v2);
        }}), 
    // Max value
    MAX(new BiFunction<Float, Float, Float>() {Float apply(Float v1, Float v2) {
            return max(v1, v2);
        }}), 
    AVG(new BiFunction<Float, Float, Float>() {Float apply(Float v1, Float v2) {
            return (v1+v2)/2f;
        }});

    private BiFunction<Float, Float, Float> f;

    private NoiseBiFuncs(BiFunction<Float, Float, Float> f) {
        this.f = f;
    }
    
    public BiFunction<Float, Float, Float> getFunc() {
        return f;
    }
}

/* 
   3 Noise params
*/

// Base class for masks that take a function, which is applied to 3 noise inputs
class NoiseMask implements INoise {
    private TriFunction<Float, Float, Float, Float> f;
    private INoise input1;
    private INoise input2;
    private INoise input3;

    public NoiseMask(TriFunction<Float, Float, Float, Float> f, INoise input1, INoise input2, INoise input3) {
        this.f = f;
        this.input1 = input1;
        this.input2 = input2;
        this.input3 = input3;
    }
    
    public NoiseMask(NoiseTriFuncs f, INoise input1, INoise input2, INoise input3) {
        this(f.getFunc(), input1, input2, input3);
    }

    public float eval(float x, float y) {
        return f.apply(input1.eval(x, y), input2.eval(x, y), input3.eval(x, y));
    }
}

// Common noise masking functions: lerps between the first 2 layers based on the value in the 3rd
enum NoiseTriFuncs {
    MASK(new TriFunction<Float, Float, Float, Float>() {Float apply(Float v1, Float v2, Float v3) {
        return lerp(v1, v2, v3);
    }});
    
    private TriFunction<Float, Float, Float, Float> f;

    private NoiseTriFuncs(TriFunction<Float, Float, Float, Float> f) {
        this.f = f;
    }
    
    public TriFunction<Float, Float, Float, Float> getFunc() {
        return f;
    }
}
