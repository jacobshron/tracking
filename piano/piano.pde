import processing.sound.*;
import java.io.*;

String[] solfegeNames = {"Do", "Re", "Mi", "Fa", "Sol", "La", "Si", "Do'"};
float[]  frequencies  = {261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88, 523.25};

int[][] colors = {
  {80,  78, 180},
  {30, 140, 120},
  {160, 130,  10},
  {160,  40,  90},
  {30,  90, 160},
  {100,  40, 160},
  {35, 130,  55},
  {160,  40,  40},
};

int MAX_PEOPLE = 10;
SinOsc[] oscillator;
SinOsc[]  oscillators  = new SinOsc[MAX_PEOPLE];
int[]     activeLane   = new int[MAX_PEOPLE];
float[]   currentAmp   = new float[MAX_PEOPLE];
float[]   targetAmp    = new float[MAX_PEOPLE];
int[]     lastLaneTime = new int[MAX_PEOPLE];  // millis() when we last entered a lane

// --- Tracked people from JSON ---
HashMap<Integer, Person> people = new HashMap<Integer, Person>();
// Map from track ID -> oscillator slot index
HashMap<Integer, Integer> idToSlot = new HashMap<Integer, Integer>();
boolean[] slotInUse = new boolean[MAX_PEOPLE];

// Tuning
float MAX_AMP      = 0.3;
float FADE_IN_SPD  = 0.08;  // lerp speed for attack
float FADE_OUT_SPD = 0.02;  // lerp speed for release
int   SUSTAIN_MS   = 1500;  // ms before fade-out begins

int laneWidth;
String JSON_PATH = "people.json";

void setup() {
  size(800, 500);
  surface.setResizable(true);
  laneWidth  = width / 8;
  
  for (int i = 0; i < MAX_PEOPLE; i++) {
    oscillators[i] = new SinOsc(this);
    oscillators[i].play();
    oscillators[i].amp(0);
    activeLane[i]   = -1;
    currentAmp[i]   = 0;
    targetAmp[i]    = 0;
    lastLaneTime[i] = 0;
    slotInUse[i]    = false;
  }
  
  textAlign(CENTER, CENTER);
  smooth();
  
}

void draw() {
  background(18, 18, 22);
  laneWidth  = width / 8;
  
  loadPeopleFromJSON();
  
  for (int slot = 0; slot < MAX_PEOPLE; slot++) {
     
    if (!slotInUse[slot]) continue;
    
    // Find the person assigned to this slot
    int assignedId = -1;
    for (int id : idToSlot.keySet()) {
      if (idToSlot.get(id) == slot) { assignedId = id; break; }
    }
    if (assignedId == -1 || !people.containsKey(assignedId)) continue;

    Person p = people.get(assignedId);
    int hoveredLane = constrain((int)(p.pixelX / laneWidth), 0, 7);

    if (hoveredLane != activeLane[slot]) {
      activeLane[slot]   = hoveredLane;
      lastLaneTime[slot] = millis();
      targetAmp[slot]    = MAX_AMP;
      oscillators[slot].freq(frequencies[activeLane[slot]]);
    }

    if (millis() - lastLaneTime[slot] > SUSTAIN_MS) {
      targetAmp[slot] = 0.0;
    }
    
    float lerpSpd = (targetAmp[slot] > currentAmp[slot]) ? FADE_IN_SPD : FADE_OUT_SPD;
    currentAmp[slot] = lerp(currentAmp[slot], targetAmp[slot], lerpSpd);
    oscillators[slot].amp(currentAmp[slot]);
    
  }

  // --- Draw lanes ---
  for (int i = 0; i < 8; i++) {
    int   x        = i * laneWidth;
    int[] c        = colors[i];
    
    float maxEnv = 0;
    for (int slot = 0; slot < MAX_PEOPLE; slot++) {
      if (slotInUse[slot] && activeLane[slot] == i) {
        maxEnv = max(maxEnv, currentAmp[slot] / MAX_AMP);
      }
    }

    float bgAlpha = 55 + 145 * maxEnv;
    fill(c[0], c[1], c[2], bgAlpha);
    noStroke();
    rect(x, 0, laneWidth, height);

    stroke(255, 25);
    strokeWeight(0.5);
    line(x, 0, x, height);
    noStroke();

    if (maxEnv > 0.01) {
      fill(c[0], c[1], c[2], 230 * maxEnv);
      rect(x, 0, laneWidth, 5);
    }

    // Solfège label
    //float labelBright = isActive ? (160 + 95 * envRatio) : 160;
    //fill(labelBright);
    //textSize(isActive ? 52 : 42);
    //text(solfegeNames[i], x + laneWidth / 2.0, height * 0.48);

    //// Frequency label
    //textSize(14);
    //fill(labelBright, labelBright, labelBright, isActive ? (140 + 115 * envRatio) : 140);
    //text(nf(frequencies[i], 0, 2) + " Hz", x + laneWidth / 2.0, height * 0.68);

      // --- Draw people trails/dots on top ---
  }

  for (Person p : people.values()) {
    p.display();
  }

  // Bottom hint
  //fill(200, 200, 200, 100);
  //textSize(13);
  //textAlign(CENTER);
  //text("Move mouse across sections to play notes", width / 2.0, height - 22);
}

// --- JSON loading + person slot management ---
void loadPeopleFromJSON() {
  File f = new File(sketchPath(JSON_PATH));
  if (!f.exists()) return;

  JSONObject json;
  try {
    json = loadJSONObject(JSON_PATH);
  } catch (Exception e) {
    return; // file mid-write, skip frame
  }

  JSONArray arr = json.getJSONArray("people");

  // Collect current IDs from JSON
  ArrayList<Integer> currentIds = new ArrayList<Integer>();
  for (int i = 0; i < arr.size(); i++) {
    JSONObject obj = arr.getJSONObject(i);
    int id    = obj.getInt("id");
    float x   = obj.getFloat("x");
    float y   = obj.getFloat("y");
    currentIds.add(id);

    if (people.containsKey(id)) {
      people.get(id).update(x, y);
    } else {
      // New person: assign a free slot
      int slot = getFreeSlot();
      if (slot != -1) {
        people.put(id, new Person(id, x, y));
        idToSlot.put(id, slot);
        slotInUse[slot] = true;
        activeLane[slot] = -1;
      }
    }
  }

  // Remove people no longer in frame
  ArrayList<Integer> toRemove = new ArrayList<Integer>();
  for (int id : people.keySet()) {
    if (!currentIds.contains(id)) toRemove.add(id);
  }
  for (int id : toRemove) {
    int slot = idToSlot.get(id);
    slotInUse[slot]  = false;
    targetAmp[slot]  = 0.0;
    activeLane[slot] = -1;
    idToSlot.remove(id);
    people.remove(id);
  }
}

int getFreeSlot() {
  for (int i = 0; i < MAX_PEOPLE; i++) {
    if (!slotInUse[i]) return i;
  }
  return -1; // no room
}
