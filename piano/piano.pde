import processing.sound.*;

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

SinOsc oscillator;
int    activeLane    = -1;
float  currentAmp   = 0.0;
float  targetAmp    = 0.0;
int    lastLaneTime = 0;   // millis() when we last entered a lane

// Tuning
float MAX_AMP      = 0.3;
float FADE_IN_SPD  = 0.08;  // lerp speed for attack
float FADE_OUT_SPD = 0.02;  // lerp speed for release
int   SUSTAIN_MS   = 1500;  // ms before fade-out begins

int laneWidth;

HashMap<Integer, Person> peopleMap = new HashMap<Integer, Person>();
int pplCount = 0;

JSONObject json;

void setup() {
  size(800, 500);
  laneWidth  = width / 8;
  oscillator = new SinOsc(this);
  oscillator.play();
  oscillator.amp(0);
  textAlign(CENTER, CENTER);
  smooth();
  frameRate(30);
}

void draw() {
  background(18, 18, 22);
  
  try {
    json = loadJSONObject("people.json");
  } catch (Exception e) {
    // println("Skipping frame: JSON not ready");
    return;
  }
  JSONArray arr = json.getJSONArray("people");
  
  HashMap<Integer, Person> newMap = new HashMap<Integer, Person>();
  
  for (int i = 0; i < arr.size(); i++) {
      JSONObject person = arr.getJSONObject(i);
      
      int id = person.getInt("id");
      float x = person.getFloat("x");
      float y = person.getFloat("y");
      
      x = 1 - x;
      
      if (peopleMap.containsKey(id)) {
        Person pers = peopleMap.get(id);
        pers.update(x, y);
        newMap.put(id, pers);
      } else {
        // Create new person
        Person pers = new Person(id, x, y);
        newMap.put(id, pers);
      }
  }
  
  peopleMap = newMap;
  
  for (Person p : peopleMap.values()) {
    p.display();
    
    int hoveredLane = constrain(p.x / laneWidth, 0, 7);

    // --- Detect lane change ---
    if (hoveredLane != activeLane) {
      activeLane    = hoveredLane;
      lastLaneTime  = millis();
      targetAmp     = MAX_AMP;
      oscillator.freq(frequencies[activeLane]);
    }
  
    // --- Start fading out after SUSTAIN_MS ---
    if (millis() - lastLaneTime > SUSTAIN_MS) {
      targetAmp = 0.0;
    }
  
    // --- Smooth amplitude envelope ---
    float lerpSpd = (targetAmp > currentAmp) ? FADE_IN_SPD : FADE_OUT_SPD;
    currentAmp = lerp(currentAmp, targetAmp, lerpSpd);
    oscillator.amp(currentAmp);
  }



  // --- Draw lanes ---
  for (int i = 0; i < 8; i++) {
    int   x        = i * laneWidth;
    int[] c        = colors[i];
    boolean isActive = (i == activeLane);

    // Visual brightness follows the audio amplitude
    float envRatio  = isActive ? (currentAmp / MAX_AMP) : 0.0;
    float bgAlpha   = 55 + 145 * envRatio;
    fill(c[0], c[1], c[2], bgAlpha);
    noStroke();
    rect(x, 0, laneWidth, height);

    // Separator
    stroke(255, 25);
    strokeWeight(0.5);
    line(x, 0, x, height);
    noStroke();

    // Solfège label
    float labelBright = isActive ? (160 + 95 * envRatio) : 160;
    fill(labelBright);
    textSize(isActive ? 52 : 42);
    text(solfegeNames[i], x + laneWidth / 2.0, height * 0.48);

    // Frequency label
    textSize(14);
    fill(labelBright, labelBright, labelBright, isActive ? (140 + 115 * envRatio) : 140);
    text(nf(frequencies[i], 0, 2) + " Hz", x + laneWidth / 2.0, height * 0.68);

    // Top indicator bar fades with envelope
    if (isActive && envRatio > 0.01) {
      fill(c[0], c[1], c[2], 230 * envRatio);
      rect(x, 0, laneWidth, 5);
    }
  }

  // Bottom hint
  fill(200, 200, 200, 100);
  textSize(13);
  textAlign(CENTER);
  text("Move mouse across sections to play notes", width / 2.0, height - 22);
}

void mouseExited() {
  targetAmp    = 0.0;
  activeLane   = -1;
}
