float r = 0; float g = 255; float b = 200;
int effectId = 1;

HashMap<Integer, Person> peopleMap = new HashMap<Integer, Person>();
int pplCount = 0;

JSONObject json;

void setup() {  
  size(1280, 720);
  smooth();
  frameRate(30);
}

void draw() {
  background(0);
  fill(r, g, b);
  noStroke();
  
  stroke(255);
  strokeWeight(8);
  noFill();
  rect(10, 10, width-20, height-20);
  
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
  }

  if (mouseX < 5 || mouseX > width || mouseY < 0 || mouseY > height) {
    r = random(255);
    g = random(255);
    b = random(255);
  }

}

void keyTyped() {
  if ((int)key >= 48 && (int)key <= 57) {
    effectId = Integer.valueOf(key) - 48;
    println(effectId);
  }
}
