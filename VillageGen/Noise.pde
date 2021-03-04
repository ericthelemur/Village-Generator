interface INoise {
    public float eval(float x, float y);
}

class Noise implements INoise {
    // Each noise layer to be summed
    private OpenSimplex2S[] octaveLayers;
    
    // Noise settings
    private int octaves = 8;            // Number of noise layers to add, each in increasing frequency and decreasing amplitude
    private float scale = 0.1;           // General scaling parameter of x, y coords
    private float zoom = 64;             // Zooms into noise
    private float roughness = 1.92;      // Multiplier for frequency per octave, almost doubles, however value of exactly 2 can lead to artifacts
    private float gain = 0.5;           // Multiplier for amplitude
    protected Random r;
    
    // Default contructor - randomizes seed
    public Noise() {
        this((long) random(Long.MAX_VALUE));
    }
    
    // Constructor - creates each octave with a random seed
    public Noise(long seed) {        
        r = new Random(seed);
        
        octaveLayers = new OpenSimplex2S[octaves];
        for (int i = 0; i < octaves; i++)
            octaveLayers[i] = new OpenSimplex2S(r.nextLong());
    }
    
    // Evaluates the noise at point (x, y)
    public float eval(float x, float y) {
        float maxAmp = 0;    // Total maximum possible amplitude, used to scale down noise at end
        float amp = 1;       // Tracks amplitude of each layer, multiplied by gain for each successive octave
        float freq = scale;  // Tracks frequency of each layer, multiplied by roughness for each successive octave
        float val = 0;       // Return value for this point

        // Scale coords by zoom
        float dx = x / zoom;
        float dy = y / zoom;

        for (OpenSimplex2S layer : octaveLayers) {                // For each octave...
            float res = (float) (layer.noise2(dx*freq, dy*freq)+1)/2f;   // Calculate base noise value, scaling for frequency
            val += res * amp;                                     // Add (transformed) base noise value, scaled down to amp, to val
            maxAmp += amp;                                        // Sum maximum possible amplitude
            amp *= gain;                                          // Reduce amplitude for next octave
            freq *= roughness;                                    // Increase frequency for next octave
        }
        val /= maxAmp;                                            // Scale noise down so max amplitude is 1

        return val;
    }
    
    // Getters and Setters
    
    public Noise setOctaves(int o) {
        octaves = o;
        return this;
    }
    
    public Noise setScale(float s) {
        scale = s;
        return this;
    }
    
    public Noise setZoom(float z) {
        zoom = z;
        return this;
    }
    
    public Noise setRoughness(float r) {
        roughness = r;
        return this;
    }
    
    public Noise setGain(float g) {
        gain = g;
        return this;
    }
}
