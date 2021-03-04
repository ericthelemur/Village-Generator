// Calculates the contour- and coast- lines
void contourAndCoast() {
    ArrayList<Line> coastLines = new ArrayList<Line>();
    // Draw coastline with marching squares
    marchingSquares(coastLines, settings.waterLevel, settings.heightmapSettings.marchingSquaresSampleDist);
    coastLine = connectLineSegments(coastLines);
    
    ArrayList<Line> contourLinesLines = new ArrayList<Line>();
    for (float i = settings.waterLevel + 0.1; i < 1; i += 0.1) {
        marchingSquares(contourLinesLines, i, settings.heightmapSettings.marchingSquaresSampleDist);
    }
    contourLines = connectLineSegments(contourLinesLines);
    
     //LinkedList<Line> waterLines = new LinkedList<Line>();
    for (float i = 1; i <= 6; i++) {
        LinkedList<Line> levelLine = new LinkedList<Line>();
        marchingSquares(levelLine, settings.waterLevel - 0.01 * i, settings.heightmapSettings.marchingSquaresSampleDist);
        
        Iterator<Line> it = levelLine.iterator();
        while (it.hasNext()) {
            Line l = it.next();
            Point mp = l.midpoint();
            float h = heightmap.get(mp.x, mp.y);
            if (settings.heightmapSettings.hmRandom.nextFloat() > pow(0.9f, (float) pow(i, 2))) {
                it.remove();
            }
            
        }
        
        contourLines.addAll(connectLineSegments(levelLine));
    }
    
    
    
}

// Based on:
// http://jamie-wong.com/2014/08/19/metaballs-and-marching-squares/
// and https://www.cse.wustl.edu/~taoju/cse554/lectures/lect04_Contouring_I.pdf slide 20
// https://web.cse.ohio-state.edu/~wenger.4/publications/isosurface_book_preview.pdf

void marchingSquares(ArrayList<Line> lines, float level) {
    marchingSquares(lines, level, 1);
}

// Carry out marching squares on all squares
void marchingSquares(List<Line> lines, float level, int scale) {
    for (int x = -2 * scale; x < settings.w + 2 * scale; x += scale)        // For each square in the grid
        for (int y = -2 * scale; y < settings.h + 2 * scale; y += scale)
            marchingSquare(x, y, lines, level, scale);
}

// Calculates approximately the line to draw across this cell to mark a contourLine at a certain level
// This first calculates the sides of the square to join
void marchingSquare(int x, int y, List<Line> lines, float level, float scale) {
    // Get values
    // v00 -- v10
    //  |      |
    // v01 -- v11
    float v00 = heightmap.get(x, y), v10 = heightmap.get(x+scale, y);
    float v01 = heightmap.get(x, y+scale), v11 = heightmap.get(x+scale, y+scale);
    
    // Calculate binary values for >/< than the level
    int b00 = v00 > level ? 1 : 0, b10 = v10 > level ? 1 : 0; 
    int b01 = v01 > level ? 1 : 0, b11 = v11 > level ? 1 : 0;
    
    // Calculate index in the lookup table, bits in clockwise order from top left
    int index = 8 * b00 + 4 * b10 + 2 * b11 + b01;
    
    if (index > 0 && index < 15) {                    // Lookup line locations for this combination
        for (MSLine l : linesLookup[index]) {
            Line line = new Line(getPointOnEdge(l.p1, x, y, v00, v10, v01, v11, level, scale),     // Interpolate points along edges, for more accurate line in cell.
                                 getPointOnEdge(l.p2, x, y, v00, v10, v01, v11, level, scale)
            );
            // Add line to lists
            lines.add(line);
        }
    }
    
}

// Calculates a point for the line, based on the values at either end of that side, and how far along the contour level (approximately) is
Point getPointOnEdge(byte edge, int x, int y, float v00, float v10, float v01, float v11, float level, float s) {
    if (edge == TOP) return new Point(x + s * lerpVals(v00, v10, level), y);                    // If along top edge, interpolate between v00 and v10
    else if (edge == RIGHT) return new Point(x + s, y + s * lerpVals(v10, v11, level));         // If along right edge, interpolate between v10 and v11
    else if (edge == BOTTOM) return new Point(x + s * lerpVals(v01, v11, level), y + s);        // If along bottom edge, interpolate between v01 and v11
    else /*if (edge == LEFT)*/ return new Point(x, y + s * lerpVals(v00, v01, level));          // If along left edge, interpolate between v00 and v01
}

// Approximates the distance between v1 and v2 (as a float [0,1]) which the contour level should be
float lerpVals(float v1, float v2, float level) {
    return (level-v1) / (v2-v1);
}

// Stores where the lines go for a certain index

byte TOP = 0, RIGHT = 1, BOTTOM = 2, LEFT = 3;

MSLine[][] linesLookup = new MSLine[][] {
    /* 0*/ {},
    /* 1*/ {new MSLine(LEFT, BOTTOM)},
    /* 2*/ {new MSLine(BOTTOM, RIGHT)},
    /* 3*/ {new MSLine(LEFT, RIGHT)},
    /* 4*/ {new MSLine(RIGHT, TOP)},
    /* 5*/ {new MSLine(TOP, LEFT), new MSLine(BOTTOM, RIGHT)},
    /* 6*/ {new MSLine(BOTTOM, TOP)},
    /* 7*/ {new MSLine(TOP, LEFT)},
    /* 8*/ {new MSLine(TOP, LEFT)},
    /* 9*/ {new MSLine(BOTTOM, TOP)},
    /*10*/ {new MSLine(LEFT, BOTTOM), new MSLine(RIGHT, TOP)},
    /*11*/ {new MSLine(RIGHT, TOP)},
    /*12*/ {new MSLine(LEFT, RIGHT)},
    /*13*/ {new MSLine(BOTTOM, RIGHT)},
    /*14*/ {new MSLine(LEFT, BOTTOM)},
    /*15*/ {},
};


class MSLine {
    byte p1, p2;
    
    MSLine(byte p1, byte p2) {
        this.p1 = p1;
        this.p2 = p2;
    }
}

// Connects adjacent lines into polylines
LinkedList<PolyLine> connectLineSegments(List<Line> lines) {
    LinkedList<PolyLine> polylines = new LinkedList<PolyLine>();
    for (Line l : lines) {
        //polylines.add(new PolyLine(l.p1, l.p2));
        PolyLine p1End = null, p2End = null;
        boolean isEnd1 = false, isEnd2 = false;    // true = end, false = start
        // Check each line against all existing polylines
        for (PolyLine pl : polylines) {
            // If p1 of the line equals the end/start of the polyline, record it
            Point e = pl.getPoint(true), s = pl.getPoint(false);
            if (epsilonEquals(e, l.p1)) {
                p1End = pl; 
                isEnd1 = true;
            } else if (epsilonEquals(s, l.p1)) {
                p1End = pl; 
                isEnd1 = false;
            }
            
            // If p2 of the line equals the end/start of the polyline, record it
            if (epsilonEquals(e, l.p2)) {
                p2End  = pl; 
                isEnd2 = true;
            } else if (epsilonEquals(s, l.p2)) {
                p2End  = pl; 
                isEnd2 = false;
            }
            // If both ends have been met, end here
            if (p1End != null && p2End != null) 
                break;
        }
        
        if (p1End == null && p2End == null) {    // IF not connecting polylines, create a new one
            polylines.add(new PolyLine(l.p1, l.p2));
        } else if (p1End != null && p2End != null) {    // If both exist:
            if (p1End == p2End) {    // If part of same line, must be ring, so complete the ring
                p2End.addPoint(l.p2, isEnd1);
            } else {    // Otherwise, merge the polylines
            LinkedList<Point> ps = new LinkedList<Point>(p2End.points);
            if (isEnd2)    // If on different ends, reverse first
                Collections.reverse(ps);
            
            p1End.addAllPoints(ps, isEnd1);    // Add all onto the correct end
            polylines.remove(p2End);
            }
            
        // If only 1 end matched, add this point to that polyline
        } else if (p1End != null && p2End == null) {
            p1End.addPoint(l.p2, isEnd1);
        } else if (p1End == null && p2End != null) {    // else
            p2End.addPoint(l.p1, isEnd2);
        } 
    }
    return polylines;
}

// Checks equality of floats with a threshold of MSFloatEpsilon
boolean epsilonEquals(float f1, float f2) {
    return epsilonEquals(f1, f2, settings.heightmapSettings.marchingSquaresFloatEpsilon);
}

// Checks equality of floats with a threshold of epsilon
boolean epsilonEquals(float f1, float f2, float epsilon) {
    return abs(f1 - f2) < epsilon;
}

// Checks equality of points with a threshold of MSFloatEpsilon
boolean epsilonEquals(Point p1, Point p2) {
    return epsilonEquals(p1, p2, settings.heightmapSettings.marchingSquaresFloatEpsilon);
}

// Checks equality of points with a threshold of epsilon
boolean epsilonEquals(Point p1, Point p2, float epsilon) {
    if (p1 == null || p2 == null) return false;
    return p1.distSq(p2) < epsilon * epsilon;
}
