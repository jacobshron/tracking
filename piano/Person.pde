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
    
    float targetX = (1-x) * width;
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
     noStroke();
     fill(255);
     ellipse(pixelX, pixelY-150, 240, 240);
   }
    
  float getPixelX() {
    return pixelX;
  }
    
//    fill(255);
//    textSize(12);
//    text(Integer.toString(id) + ": (" + Float.toString(pixelX) + ", " + Float.toString(pixelY) + ")", pixelX + 15, pixelY + 15); 
}
