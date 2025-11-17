float r = 0; float g = 255; float b = 200;
int trailLen = 1000;
int currentShape = 0;
float[] shapeX = new float[trailLen];
float[] shapeY = new float[trailLen];
float[] shapeA = new float[trailLen];
float[] shapeSize = new float[trailLen];

void setup() {
  size(1280, 720);
  smooth();
  frameRate(480);
}

void draw() {
  background(50);
  fill(r, g, b);
  noStroke();
  noCursor();
  
  shapeX[currentShape] = mouseX;
  shapeY[currentShape] = mouseY;
  shapeA[currentShape] = 255;
  shapeSize[currentShape] = 20;

  // ellipse(mouseX, mouseY, shapeSize[currentShape], shapeSize[currentShape]);

  for (int i = 0; i<trailLen; i++) {
    fill(r, g, b, shapeA[i]);
    ellipse(shapeX[i], shapeY[i], shapeSize[i], shapeSize[i]);
    shapeA[i] -= 255/trailLen;
    shapeSize[i] -= .02;
  }

  currentShape++;
  currentShape %= trailLen;

  if (mouseX < 5 || mouseX > width || mouseY < 0 || mouseY > height) {
    r = random(255);
    g = random(255);
    b = random(255);
  }

}
