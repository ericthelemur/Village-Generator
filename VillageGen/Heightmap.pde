class Heightmap implements IDrawable {
    float[][] heightmap;    // The grid heightmap values
    int w, h;               // The dimensions of the heightmap
    float maxVal, minVal;   // The max and min values of the noise, used to normalize later
    PGraphics hmpg;         // Graphics object that stores the image of the heightmap after generation
    
    public Settings.HeightMapSettings heightmapSettings = settings.heightmapSettings;

    Heightmap(int w, int h) {
        this.w = w;
        this.h = h;
        heightmap = new float[w][h];
    }
    
    void draw(float delta, PGraphics pg) {
        if (hmpg == null) {    // If graphics is null, create canvas and draw all values
            hmpg = createGraphics(width, height);
            hmpg.beginDraw();
            hmpg.noStroke();
            // Fill with ground colour
            hmpg.background(#CCCCCC);
            
            hmpg.fill(#AAAABB);
            // Draw all water points
            for (int x = 0; x < w; x++) {
                for (int y = 0; y < h; y++) {
                    float v = get(x, y);
                    if (v < settings.waterLevel) {
                        hmpg.rect(x-0.5, y-0.5, 1.5, 1.5);
                    }
                }
            }
            hmpg.endDraw();
        }
        // Draw image, once it has been created
        pg.image(hmpg, 0, 0);
        
        if (phase < generatorSteps.length && generatorSteps[phase] instanceof RoadGenerator)
            drawGrad(delta, pg);
    }
    
    // Draws crosses to illustrate the major and minor gridlines (gradient)
    void drawGrad(float delta, PGraphics pg) {
        float l = 5, c = 3;
        pg.stroke(#BBBBBB);
        for (int x = 12; x < w; x += 25) {
                for (int y = 12; y < h; y += 25) {
                    Gradient grad = getGradient(x, y);
                    grad.normalize();
                    Gradient perp = new Gradient(grad.y, -grad.x);
                    pg.line (x - grad.x * c, y - grad.y * c, x + grad.x * l, y + grad.y * l);
                    pg.line (x - perp.x * c, y - perp.y * c, x + perp.x * c, y + perp.y * c);
                }
        }
    }
    
    // Fills the heightmap with values from heightmapSettings.mainNoise, then normalizes to range from 0 to 1, and finally folds values if river is present
    public void fillHeightmap() {
        minVal = Float.MAX_VALUE;
        maxVal = Float.MIN_VALUE;
        // Calculate all values
        for (int x = 0; x < w; x++) {
            for (int y = 0; y < h; y++) {
                float v = heightmapSettings.mainNoise.eval(x, y);
                if (v < minVal) minVal = v;
                if (maxVal < v) maxVal = v;
                heightmap[x][y] = v;
            }
        }
        if (minVal == maxVal) return;
        
        // If no water, set water level to 0
        if (heightmapSettings.hmRandom.nextFloat() > heightmapSettings.waterChance)
            settings.waterLevel = 0;
            
        // If placing a river
        boolean river = settings.waterLevel > 0 && heightmapSettings.hmRandom.nextFloat() < heightmapSettings.riverChance;

        // River fold threshold
        float ft = settings.waterLevel * random(heightmapSettings.hmRandom, 0.9, 0.99);
        
        for (int x = 0; x < w; x++) {
            for (int y = 0; y < h; y++) {
                float v = map(heightmap[x][y], minVal, maxVal, 0, 1);    // Normalize cell value
                if (river && v < ft) {
                    v = 2 * ft - v;    // If river invert values below ft, so other bank appears
                }
                heightmap[x][y] = v;
            }
        }
        
        // For the precomputed values, the folding is already applied, but it also needs to be applied to future values
        if (river)
            heightmapSettings.mainNoise = new NoiseFold(ft, heightmapSettings.mainNoise);
        
    }
    
    // Calculates gradient based on the 4 neighbours
    Gradient getGradient(int x, int y) {
        float v = get(x, y);
        float ndx = get(x-1, y);
        float dx = get(x+1, y);
        float ndy = get(x, y-1);
        float dy = get(x, y+1);
        return new Gradient(((ndx - v) + (v - dx))/2, ((ndy - v) + (v - dy))/2);
    }
    
    // Calculates a value in the heightmap: if a point in the pregenerated grid, return that value, otherwise evaluate it
    float get(float x, float y) {
        //if (x == (int) x && y == (int) y && 0 <= x && x < w && 0 <= y && y < h)
        //    return heightmap[(int) x][(int) y];
        //else 
            return map(heightmapSettings.mainNoise.eval(x, y), minVal, maxVal, 0, 1);
    }
    
    // Gets the value at a point
    float get(Point p) {
        return get(p.x, p.y);
    }
    
    // Gets the gradient of a location
    Gradient getMajor(float x, float y) {
        Gradient g = getGradient((int) x, (int) y);
        return g;
    }
    
    // Gets the gradient of a point
    Gradient getMajor(Point p) {
        return getMajor(p.x, p.y);
    }
    
    // Gets the normal to the gradient at a point
    Gradient getMinor(float x, float y) {
        Gradient maj = getMajor(x, y);
        return new Gradient(maj.perp());
    }
    
    // Gets the normal to the gradient at a point
    Gradient getMinor(Point p) {
        return getMinor(p.x, p.y);
    }
    
    // Gets the gradient or gradient normal at a point, based on field (either major or minor)
    Gradient getFieldGrad(float x, float y, Field f) {
        switch (f) {
            case MAJOR: return getMajor(x, y);
            case MINOR: return getMinor(x, y);
            default:       return new Gradient();
        }
    }
    
    // Gets the gradient or gradient normal at a location, based on field (either major or minor), and negates if getting the negative value
    Gradient getFieldGrad(float x, float y, FieldDir f) {
        Gradient base = getFieldGrad(x, y, f.getField());
        base.mult(f.getDir() == FDir.POS ? 1 : -1);    // Negate if negative
        return base;
    }
    
    // Gets the gradient or gradient normal at a point, based on field (either major or minor), and negates if getting the negative value
    Gradient getFieldGrad(Point p, FieldDir f) {
        return getFieldGrad(p.x, p.y, f);
    }

    // From: https://martindevans.me/game-development/2015/12/11/Procedural-Generation-For-Dummies-Roads/ and https://gafferongames.com/post/integration_basics/
    // rk4 is a more accurate numerical integrator, that evens out local noise
    Gradient rk4FieldVector(Point p, FieldDir f) {
        Gradient k1 = getFieldGrad(p, f);
        Point p1 = Point.add(p, Point.div(k1, 2));
        Gradient k2 = getFieldGrad(p1, f);
        Point p2 = Point.add(p, Point.div(k2, 2));
        Gradient k3 = getFieldGrad(p2, f);
        Point p3 = Point.add(p, k3);
        Gradient k4 = getFieldGrad(p3, f);
        
        return new Gradient(Point.add(Point.div(k1, 6), Point.div(k2, 3), Point.div(k3, 3), Point.div(k4, 6)));
    }
}
