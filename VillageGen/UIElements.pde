// Basic interface for UI elements: both a draw and a controls method
interface UI extends IDrawable {
    public void controls(float delta);
}

// Basic UIElement - just a rectangle with a colour
class UIElement extends Rect implements UI {
    color backgroundColour = #FFFFFF;
    boolean draw = true;
    
    // Blank contructor
    UIElement() {
        super(0, 0, 0, 0);
    }
    
    // Contructor for position and dimensions
    UIElement(float x, float y, float w, float h) {
        super(x, y, w, h);
    }
    
    // Constructor for the top left and bottom right corners
    UIElement(Point p1, Point p2) {
        super(p1, p2);
    }
    
    // Draws a rectangle with these dimensions
    @Override
    public void draw(float delta, PGraphics pg) {
        pg.fill(backgroundColour);
        pg.rectMode(CORNER);
        pg.rect(x,y,w,h);
    }
    
    // Where control handling happens
    public void controls(float delta) {}
}

// Button class, runs function when clicked. Only allows a single line as text 
class UIButton extends UIElement {
    String text;
    float fontSize = 10;
    Runnable function;    // Function that happens on button click
    color hoverColour = #AAAAAA, clickColour = #777777, backgroundColour = #DDDDDD;
    
    // Contructor with separate vars
    UIButton(String text, Runnable function, float x, float y, float w, float h) {
        super(x,y,w,h);
        this.text = text;
        this.function = function;
        
        checkSize(g);
    }
    
    // Contructor with corner points
    UIButton(String text, Runnable function, Point p1, Point p2) {
        this(text, function, p1.x, p1.y, p2.x - p1.x, p2.y - p1.y);
    }
    
    // Contructor with no width and height, inferred from text dimensions
    UIButton(String text, Runnable function, float x, float y) {
        this(text, function, x, y, 1, 1);
    }
    
    // Contructor with no width and height, inferred from text dimensions
    UIButton(String text, Runnable function, float x, float y, float fontSize) {
        this(text, function, x, y, 1, 1);
        this.fontSize = fontSize;
    }
    
    // Contructor with no width and height, inferred from text dimensions
    UIButton(String text, Runnable function, Point p1) {
        this(text, function, p1.x, p1.y);
    }
    
    // Constructor with default position and dimensions, only for use with UICollection
    UIButton(String text, Runnable function, float fontSize) {
        this(text, function, 0, 0, 1, 1);
        this.fontSize = fontSize;
    }
    
    
    public void setFontSize(float size) {
        fontSize = size;
        checkSize(g);
    }
    
    void draw(float delta, PGraphics pg) {
        pg.stroke(#999999);
        pg.strokeWeight(2);
        
        // Check size matches
        checkSize(g);
        
        // Sets fill to background, hover or click colour depending on mouse situation
        if (contains(new Point(mouseX, mouseY))) {
            if (mousePressed) pg.fill(clickColour);
            else pg.fill(hoverColour);
        } else pg.fill(backgroundColour);
        
        // Draws background
        pg.rectMode(CORNER);
        pg.rect(x,y,w,h);
        
        // Draws text
        pg.fill(#000000);
        pg.textAlign(CENTER, CENTER);
        pg.text(text, x+w/2, y+h/2-2);
    }
    
    // If button clicked, run function
    void controls(float delta) {
        if (contains(new Point(mouseX, mouseY)) && mouseClicked) 
            function.run();
    }
    
    // Checks whether the text can fit the current dimensions, if not, resize the button to fit
    void checkSize(PGraphics pg) {
        // Calculates current text dimensions, and resizes box to fit it
        pg.textSize(fontSize);
        float textW = pg.textWidth(text)+8;
        if (textW > w) setWidth(textW);
        float textH = pg.textAscent()+pg.textDescent()+4;
        if (textH > h) setHeight(textH);
    }
}

// Text box UI element
class UIText extends UIElement {
    String text;
    float fontSize = 10;
    color backgroundColour = #DDDDDD;
    
    // Basic constructor
    UIText(String text, float x, float y, float w, float h) {
        super(x,y,w,h);
        this.text = text;
    }
    
    // Contructor with corner points
    UIText(String text, Point p1, Point p2) {
        super(p1, p2);
        this.text = text;
    }
    
    // Contructor with no width and height, inferred from text size
    UIText(String text, float x, float y) {
        super(x,y,1,1);
        this.text = text;
    }
    
    // Contructor with no width and height, inferred from text size
    UIText(String text, Point p1) {
        super(p1.x, p1.y,1,1);
        this.text = text;
    }
    
    @Override
    void draw(float delta, PGraphics pg) {
        pg.noStroke();
        pg.strokeWeight(2);
        pg.fill(backgroundColour);
        
        pg.textSize(fontSize);
        
        // Resize to fit
        // Splits text at newlines
        String[] lines = text.split("\n");
        // Calculates max width of a line
        float maxLineWidth = 0;
        for (int i = 0; i < lines.length; i++) 
            maxLineWidth = max(maxLineWidth, pg.textWidth(lines[i]));
        
        // Calculates text size
        float textW = maxLineWidth + 6;
        float textH = (pg.textAscent()+pg.textDescent())*lines.length + 6;
        
        // If box won't fit text, resize box
        if (textW > w) w = textW;
        if (textH > h) h = textH;
        
        // Draw background
        pg.rectMode(CORNER);
        pg.rect(x,y,w,h);
        
        // Draw text
        pg.fill(#000000);
        pg.textAlign(CENTER, CENTER);
        pg.text(text, x+w/2, y+h/2-2);
    }
}

// Contains a collection of elements which are aligned horizontally, with a set separation between them
class UICollection extends UIElement {
    private UIElement[] elements;
    float separation = 3;
    
    // Constructor for top left position, and the contained elements
    public UICollection(float x, float y, UIElement... e) {
        super(x, y, 0, 0);
        elements = e;
        arrange(g);
    }
    
    // Constructor including the separation between each element
    public UICollection(float x, float y, float separation, UIElement... e) {
        this(x, y, e);
        this.separation = separation;
    }
    
    // Arranges the contents of elements, horizontally, with a distance of separation between them.
    private void arrange(PGraphics pg) {
        // Calculate total width and height
        float wi = separation, he = 0;
        for (UIElement uie : elements) {
            wi += uie.w + separation;
            he = max(uie.h, he);
        }
        // Set the collections size
        w = wi;
        h = he + separation*2;
        // Records the coordinates of the next element
        float elementX = x + separation;
        float elementY = y + separation;

        for (UIElement element : elements) {    // For each element, set it's position, and increase the X counter by it's width
            element.setX(elementX);
            element.setY(elementY);
            if (element instanceof UICollection)        // If the element is a collection, arrange it first, then continue here
                ((UICollection) element).arrange(pg);
            if (element instanceof UIButton)
                ((UIButton) element).checkSize(pg);
            elementX += element.w + separation;
        }
    }
    
    // Calls controls for all children
    void controls(float delta) {
        for (UIElement uie : elements) {
            if (uie.draw) uie.controls(delta);
        }
    }
    
    // Calls draw for all children
    @Override
    void draw(float delta, PGraphics pg) {
        for (UIElement uie : elements) {
            if (uie.draw) uie.draw(delta, pg);
        }
    }
}
