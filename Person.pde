public class Person {
  int id;
  float x, y;
  float pixelX, pixelY;
  float smooth = 0.2;
  float threshold = 8;
  
  ArrayList<PVector> history = new ArrayList<PVector>();
  int maxTrail = 40;  
  
  Person(int id, float x, float y) {
    this.id = id;
    this.pixelX = x * width;
    this.pixelY = y * height;
    update(x, y);
  }
  
  void update(float x, float y) {
    this.x = x;
    this.y = y;
    
//    pixelX = x * width;
//    pixelY = y * height;
    
    float targetX = x * width;
    float targetY = y * height;
    
    if (abs(pixelX - targetX) < threshold && abs(pixelY - targetY) < threshold) {
      return;
    }
    
    pixelX = lerp(pixelX, targetX, smooth);
    pixelY = lerp(pixelY, targetY, smooth);
    
    history.add(new PVector(pixelX, pixelY));
    
    if (history.size() > maxTrail) {
      history.remove(0);  
    }
  }  
  
  void display() {  
    noFill();
    stroke(0, 255, 200);
    strokeWeight(3);
    
    beginShape();
    for (PVector p : history) vertex(p.x, p.y);
    endShape();
    
    noStroke();
    fill(0, 255, 200);
    ellipse(pixelX, pixelY, 20, 20);
    
//    fill(255);
//    textSize(12);
//    text(Integer.toString(id) + ": (" + Float.toString(pixelX) + ", " + Float.toString(pixelY) + ")", pixelX + 15, pixelY + 15); 
  }
}
