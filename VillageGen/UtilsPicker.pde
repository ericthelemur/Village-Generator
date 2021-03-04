
// Class that randomly picks from a list of Ts with weighting
class WeightedPicker<T> implements Iterable<T> {
    HashMap<T, Float> entries;    // List of values and their weights
    float weightSum = 0;    // Sum of all weights, for efficiency
    Random r;
    
    // Constructor with empty picker
    public WeightedPicker(Long seed) {
        entries = new HashMap<T, Float>();
        r = new Random(seed);
    }
    
    // Add a value to the list
    public void add(T item, Float weight) {
        entries.put(item, weight);
        weightSum += weight;
    }
    
    // Remove a value from the list
    public boolean remove(T item) {
        Float w = entries.remove(item);
        if (w != null)                // Then remove it
            weightSum -= w;
        return true;
    }
    
    // Picks a random value in entries, based on weightings
    public T pick() {
        float v = r.nextFloat() * weightSum;    // Get threshold: when the sum of weights pass this value, that value is picked
        float s = 0;
        
        for (Map.Entry<T, Float> p : entries.entrySet()) {
            s += p.getValue();
            if (v <= s) return p.getKey();
        }
        return null;
    }
    
    // Picks a random entry, and removes it once picked
    public T pickRemove() {
        T v = pick();
        remove(v);
        return v;
    }
    
    public void increment(T item) {
        entries.put(item, entries.getOrDefault(item, 0.0f) + 1);
        weightSum += 1;
    }
    
    // Returns an iterator over all the values in the picker
    public Iterator<T> iterator() {
        return entries.keySet().iterator();
    }
    
    public boolean isEmpty() {
        return entries.isEmpty();
    }
    
    public void clear() {
        entries = new HashMap<T, Float>();
    }
    
    public String toString() {
        String s = "WeightedPicker {";
        for (Map.Entry<T, Float> p : entries.entrySet()) {
            print(p.getKey(), p.getValue());
            s += String.format("%s: %.2f, ", p.getKey(), p.getValue());
        }
        return s + "}";
    }
}

// Iterator for WeightedPicker, same as list iterator, but strips off weighting
class PairKeyIterator<K> implements Iterator<K> {
        private Iterator<Pair<K, ?>> pairIt;
        
        public PairKeyIterator(Iterator<Pair<K, ?>> it) {
            pairIt = it;
        }
        
        public boolean hasNext() {
            return pairIt.hasNext();
        }
        
        public K next() {
            Pair<K, ?> p = pairIt.next();
            return p.first();
        }
    }
