class NameGenerator implements IGeneratorStep {
    boolean ended = false;
    
    public void run() {
        nameText.text = markovNameGen.generate();
        textSize(nameText.fontSize);
        nameText.setWidth(textWidth(nameText.text));
        println(nameText.text);
        popText.text = "Pop: " + int(random(settings.mainRandom, 2, 5) * buildings.size());
        
        textSize(popText.fontSize);
        popText.setWidth(textWidth(popText.text));
        
        ((UICollection) ui.get("nameText")).arrange(g);
        ended = true;
    }

    public void initGen() {
    }

    public boolean ended() {
        return ended;
    }

    public void endGen() {
    }
}

public class MarkovGenerator {
    private HashMap<String, WeightedPicker<String>> chains = new HashMap<String, WeightedPicker<String>>();
    private int order;
    private Random rand;
    private String start;

    public MarkovGenerator(int order, ArrayList<String> data, long seed) {
        this.order = order;
        start = String.join("", Collections.nCopies(order, "^")); // Constructs base string (^^^)
        rand = new Random(seed);
        train(data);
    }

    public MarkovGenerator(int order, String fileName, long seed) {
        this.order = order;
        start = String.join("", Collections.nCopies(order, "^")); // Constructs base string (^^^)
        rand = new Random(seed);
        train(readFile(fileName));
    }

    public ArrayList<String> readFile(String fileName) {
        try {
            BufferedReader reader = createReader(fileName);
            String line;                                                // Get file
            ArrayList<String> list = new ArrayList<String>();
            while ((line = reader.readLine()) != null) {        // For each line
                if (line.length() == 0 || line.charAt(0) == '#') continue;
                list.add(line);                 // Add if not comment
            }
            return list;
        } 
        catch (Exception e) {
            e.printStackTrace();
            return new ArrayList<String>();
        }
    }

    private void train(ArrayList<String> data) {
        for (String word : data) {
            word = start + word + "$";
            for (int i = order; i < word.length(); i++) { // For each set of letters
                String key = word.substring(i-order, i);
                String val = String.valueOf(word.charAt(i));
                if (!chains.containsKey(key)) chains.put(key, new WeightedPicker<String>(rand.nextLong()));
                chains.get(key).increment(val);                       // If picker doesn't exist, create a blank picker
                // Add val
            }
        }
    }

    public String generate() {
        StringBuilder wordBuilder = new StringBuilder(start);
        String c;
        do {
            c = pickNext(wordBuilder.toString());
            wordBuilder.append(c);
        } while (!c.equals("$"));

        String word = wordBuilder.toString();
        word = word.replaceAll("^\\^+|\\$+$", "");  // Remove leading ^'s and trailing $'s
        if (word.length() < 4 || 15 < word.length()) return generate();
        return capitalize(word);
    }

    public String pickNext(String word) {
        WeightedPicker<String> chain = chains.get(word.substring(word.length()-order));
        if (chain != null && !chain.isEmpty()) return chain.pick();
        return "";
    }
}
