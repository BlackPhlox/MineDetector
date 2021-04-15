// Copyright (c) 2019 by Mikkel Rasmussen. All Rights Reserved.
// Mine Dectectir Game 2017 - How fast can you get from the bottom to the top? 
// Take screenshots and post it on social media to compete!
// Press |ctrl + t| to see the sketch unfolded

//Requires Arduino Firmata Library and Firmata to be loaded unto the arduino.

//Loads liberary to communicate with the arduino
import org.firmata.*;
import processing.serial.*;
import cc.arduino.*;

//Assign arduino ports
Arduino arduino;int greenPin;int yellowPin;
int redPin;int soundPin;int count;int inputValue;
int pot1;int pot2;

//Declare the needed variables
int cols;int rows;PVector player;PVector selector;PVector[] fields;
PVector[] flags;ArrayList<PVector> bombs;ArrayList<PVector> playerPath;
StringList lvlName;int time;int i;int k;int X;int diff;int preDiff;
int lowDiff;int timer;int bombSize;int dectRadius;int bombsAmount;
int lvlIndex; int disableBombIndex;boolean disableBomb;boolean goodBomb;
boolean playerHitBomb;boolean winner;boolean showBombs;boolean lost;
boolean selectorTouch;String timerSub;String playerState;String lvl;
boolean arduinoConnected; int predefinedPort;boolean showBombLine;

void assignAll(){
//----Assign arduino ports/terminals-------|
greenPin = 7; // Green LED                 |
yellowPin = 6;// Yellow LED                |
redPin=5;     // Red LED                   |
soundPin = 4; // Buzzer                    |
pot1 = 0;     // Potentiometer 1 (x-axis)  |
pot2 = 1;     // Potentiometer 2 (y-axis)  |
//------------Sketch Settings--------------|
//Change Sketch Size(Quadratic) Goto setup |
cols = 20;        //Horizontal cells       |
rows = 20;        //Vertical cells         |
showBombLine = false;//SH Line to the bombs| 
//------------Arduino Settings-------------|
arduinoConnected = false; //Is the arduino |
predefinedPort = 0;       //connected?     |
//-----------------------------------------|

time = 0;lowDiff = round(sqrt((height*height)+(width*width)));
timer = 0;lvlIndex = 0;disableBomb = false;count = 0;
winner = false;showBombs = false;lost = false;
selectorTouch = false;timerSub = "";lvl = "";
}

//Reset the game
void reset(){
  //Assign Values
  assignAll();
  
  //Function that removes the windows-cursor from the program
  //Creates an array for the path of the player
  playerPath = new ArrayList<PVector>();
  
  //Spawns the player at predefined cordinates
  player = new PVector (width, height);
  
  //Checks if an arduino is connected
  if (arduinoConnected == true){arduinoLoad();}
  lvlName = new StringList();
  lvlName.append("verye");
  lvlName.append("easy");
  lvlName.append("intm");
  lvlName.append("veryh");
  lvlName.append("fubar");
  spawnBombs(lvlName.get(0)); //Selecting start Difficulty
}
void arduinoLoad(){
  //Assigns the arduino ports variable-names 
  //and defines if they are in- or outputs
   arduino = new Arduino(this, Arduino.list()[predefinedPort], 57600);
   arduino.pinMode(greenPin, Arduino.OUTPUT);
   arduino.pinMode(yellowPin, Arduino.OUTPUT);arduino.pinMode(redPin, Arduino.OUTPUT);
   arduino.pinMode(redPin, Arduino.OUTPUT);arduino.pinMode(soundPin, Arduino.OUTPUT);
   arduino.pinMode(pot1, Arduino.INPUT);arduino.pinMode(pot2, Arduino.INPUT);
}
void setup() {
  //Defines the canvas/window of the program
  size(400, 400);
  //Runs setup
  reset();
}
void spawnBombs(String difficulty) {
  /*Difficulty settings
   -Very Easy    ("verye")    | BombSize : 20, DectectionRadius : 40, BombAmount: 60,  Defusals: 10 |
   -Easy         ("easy")     | BombSize : 20, DectectionRadius : 20, BombAmount: 80,  Defusals: 5  |
   -Intermediate ("intm")     | BombSize : 10, DectectionRadius : 20, BombAmount: 80,  Defusals: 10 |
   -Very Hard    ("veryh")    | BombSize : 10, DectectionRadius : 20, BombAmount: 150, Defusals: 10 |
   -FUBAR        ("fubar")    | BombSize : 10, DectectionRadius : 10, BombAmount: 180, Defusals: 5  |
   */
  if (difficulty == "verye") {
    bombSize = 20;
    dectRadius = 40;
    bombsAmount = 60;
    lvl = "Very Easy";
    disableBombIndex = 10;
  }
  if (difficulty == "easy") {
    bombSize = 20;
    dectRadius = 20;
    bombsAmount = 80;
    lvl = "Easy";
    disableBombIndex = 5;
  }
  if (difficulty == "intm") {
    bombSize = 10;
    dectRadius = 20;
    bombsAmount = 80;
    lvl = "Intermediate";
    disableBombIndex = 10;
  }
  if (difficulty == "veryh") {
    bombSize = 10;
    dectRadius = 20;
    bombsAmount = 150;
    lvl = "Very Hard";
    disableBombIndex = 10;
  }
  if (difficulty == "fubar") {
    bombSize = 10;
    dectRadius = 10;
    bombsAmount = 180;
    lvl = "FUBAR";
    disableBombIndex = 5;
  }

  //Spawn bombs
  bombs = new ArrayList<PVector>(bombsAmount);
  for (int i = 0; i <bombsAmount; i++) {
    bombs.add(new PVector(random(width/5+bombSize/2, width-(2+bombSize/2)), random(20, height-20)));
  }
  //Spawns the bombs at random cords and checks if there
  //is already a bomb nearby to determine wether or not it shoud spawn there
  while (i < bombs.size()) {
    if (i<1) {
      bombs.add(new PVector(random(width/5+bombSize/2, width-(2+bombSize/2)), random(20, height-20)));
    } else if (i>0) {
      X=0;
      goodBomb = true;
      PVector fakeBomb = new PVector(random(width/5+bombSize/2, width-(2+bombSize/2)), random(20, height-20));
      while (X<i) {
        preDiff = round(PVector.dist(bombs.get(X), fakeBomb));
        if (preDiff < bombSize*1.5) {
          goodBomb = false;
        }
        X++;
      }
      if (goodBomb == true) {
        bombs.set(i, fakeBomb);
      } else {
        i--;
      }
    }
    i++;
  }
}
//Defuse bombs nearby by pressing LMB or |Button with Arduino (When Implemented)|
void mousePressed() {
  if (mousePressed && (mouseButton == LEFT)) {
    if (mouseX < width/5) {
      //Changes difficulty settings
      if (lvlName.size() == lvlIndex) {
        lvlIndex = 0;
      } else {
        bombs.clear();
        resetGame();
        spawnBombs(lvlName.get(lvlIndex));
        lvlIndex++;
      }
    } else {
      //Bomb defusal | On or off 
      if (disableBomb == false) {
        disableBomb = true;
      } else {
        disableBomb = false;
      }
    }
  }
  if (mousePressed && (mouseButton == RIGHT)) {
    if (mouseX < width/5) {
      if (lvlName.size() == lvlIndex) {
        lvlIndex = 0;
      } else {
        bombs.clear();
        resetGame();
        spawnBombs(lvlName.get(lvlIndex));
      }
    }
  }
}
void draw() {
  //Draws RadarBackground
  radarBG();
  //Update player location/movement by a vector
  //Checks if the arduino is connected to
  //To determine which controls shoud be used
  if (arduinoConnected == false){
  //PC-Only version
    player.x = constrain(mouseX, width/5, width);
    player.y = constrain(mouseY, 0, height);
  } else {
  //Arduino Version
    player.x = map(arduino.analogRead(pot1), 0, 1023, width/5, width);
    player.y = map(arduino.analogRead(pot2), 0, 1023, 0, height);
  }
  //Draws a line that displays the players heading
  selector = new PVector (dectRadius, dectRadius);
  //Grey playingfield background
  noStroke();
  fill(60, 60, 60);
  rect(width/5, 0, width-(width/5), height);
  
  //MAIN DRAW FOR-LOOP
  for (int k = 0; k < bombs.size(); k++) {
    // Sets the lowest difference to a high value
    lowDiff = 10000;
    // Runs as many times as there are bombs
    for (int k2 = 0; k2 < bombs.size(); k2++) {
      //Calcs the dist from the player to the nearest bomb
      diff = round(PVector.dist(player, bombs.get(k2)));
      // If the length between the player and a bomb is lower than the currently
      // lowest length, then set the lowest length to the new length.
      if (diff < lowDiff) {
        lowDiff = diff;
      }
    }
    //Calcs the dist from the player to the nearest bomb
    int diff2;
    diff2 = round(PVector.dist(player, bombs.get(k)));
    //This is when the player is near a bomb and the radar displays it
    if (diff2 < dectRadius*2) {
      strokeWeight(1);
      //Disables the removing of bombs when 
      //the player does not have any bombdisables left
      if (disableBomb == true){
        if (disableBombIndex > 0){
            disableBombIndex--;
            bombs.remove(k);
            disableBomb = false;
        }
      }
      if (showBombLine == true){
      line(bombs.get(k).x/5, bombs.get(k).y/5, player.x/5, player.y/5);}
      point(bombs.get(k).x/5, bombs.get(k).y/5);
      //Signals to the arduino the freq it needs to play
      //Relative to the distance between the player and the nearest bomb (int diff)
      if (lowDiff < bombSize+50) {
        createNoise();
      }
      //Signals to the arduino light indication of
      //how close the player is to the nearest bomb
      blink();
      //This is when the player hits the bomb (See top of MAIN DRAW FOR-LOOP)
      if (lowDiff < bombSize/2) {
        playerHitBomb = true;
      } else {
        playerHitBomb = false;
      }
    }
    //Reset color and size of the FOR-LOOP
    stroke(255);
    strokeWeight(4);
    //Show bombs [DEBUG]
    stroke(255, 0, 0);
    pushStyle();
    strokeWeight(bombSize);
    if (showBombs == true) {
      point(bombs.get(k).x, bombs.get(k).y);
    }
    stroke(255);
    popStyle();
  }
  //Display radar    (See function down below)
  radarCicle();
  //Draw RangeMeter  (See function down below)
  rangeMeter();
  //Draw RadarPlayer (See function down below)
  stroke(255, 0, 0);
  strokeWeight(1.5);
  point(player.x/5, player.y/5);
  //Draw player position as points
  pushMatrix();
  pushStyle();
  strokeWeight(4);
  stroke(0, 255, 0);
  translate(player.x, player.y);
  point(0, 0);
  popStyle();
  selector.rotate(radians(millis()/5));
  strokeWeight(1);
  stroke(255);
  line(0, 0, selector.x, selector.y);
  stroke(255, 0, 255);
  strokeWeight(3);
  popMatrix();
  //Draw the enviroment dots (See function down below)
  fieldGrid();
  //Calc the state of the player as string : playerState and timerSub
  // (See function down below)
  displayPlayerState();
  //Text display
  fill(255);
  textSize(12);
  textAlign(CENTER);
  text("Timer:", (width/5)/2, height/4);
  text(timer, (width/5)/2, height/3);
  text(timerSub, (width/5)/2, height/3+20);
  text(playerState, (width/5)/2, height/3+40);
  text("Difficulty:", (width/5)/2, height/3+100);
  text(lvl, (width/5)/2, height/3+120);
  text("Defusals left:", (width/5)/2, height/3+140);
  text(disableBombIndex, (width/5)/2, height/3+160);
  if (winner == true) {
    text("Winner", (width/5)/2, height/3+80);
  }
  //Draws a path of arrays on the players position
  if (playerState == "onField" && winner == false && lost == false) {
    playerPath.add(new PVector(player.x, player.y));
  }
  if (playerState == "startField") {
    playerPath.clear();
  }
  //Display the player path
  pushStyle();
  stroke(0, 255, 0);
  beginShape(LINES);
  for (PVector pos : playerPath) {
    vertex(pos.x, pos.y);
  }
  endShape();
  popStyle();
  //Checks to see if player has hit the bomb
  if (playerHitBomb == true && winner == false) {
    bombHit();
    showBombs = true;
  }
}
void resetGame() {
  playerPath.clear();
  timerSub = "";
  winner = false;
  lost = false;
  timer = 0;
  showBombs = false;
  
}
void displayPlayerState() {
  if (player.y > height-20) {
    timer = 0;
    playerState = "startField";
    timerSub = "";
    winner = false;
    lost = false;
    showBombs = false;
  } else if (player.y < 20) {
    playerState = "topField";
    showBombs = true;
    if (playerPath.size() < 20) {
      lost = true;
    } else if (timerSub != "DNF") {
      winner = true;
    }
  } else {
    if (winner == false) {
      showBombs = false;
      if (millis()%1 == 0)
        timer += 2;
    }
    playerState = "onField";
  }
  if (playerHitBomb == true && winner == false) {
    timerSub = "DNF";
    lost = true;
  }
  if (lost == true) {
    showBombs = true;
    timerSub = "DNF";
    timer = 99999;
  }
  if (winner == true) {
    showBombs = true;
  }
}
void radarCicle() {
  pushStyle();
  strokeWeight(0.5);
  fill(0);
  pushMatrix();
  translate(player.x/5, player.y/5);
  rotate(radians(millis()/5));
  noStroke();
  arc(0, 0, dectRadius, dectRadius, QUARTER_PI, PI, PIE);
  stroke(255);
  line(0, 0, dectRadius/4, dectRadius/4);
  popMatrix();
  popStyle();
}
void fieldGrid() {
  //Draw enviroment points
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      stroke(255);
      strokeWeight(1);
      point(map(i, 0, cols, width/5+10, width), map(j, 0, rows, 20, height));
    }
  }
}
void radarBG() {
  noStroke();
  fill(0);
  background(0);
  stroke(255);
}
void rangeMeter() {
  pushMatrix();
  fill(255);
  stroke(255, 0, 0);
  strokeWeight(1);
  textAlign(CENTER);
  textSize(10);
  text(constrain(lowDiff-bombSize/2, 0, dectRadius), 7, 10+height/5);
  noStroke();
  if (constrain(lowDiff-bombSize/2, 0, dectRadius) < 10) {
    fill(255, 0, 0);
  } else if (constrain(lowDiff-bombSize/2, 0, dectRadius) < 30) {
    fill(255, 255, 0);
  } else {
    fill(0, 255, 0);
  }
  rect(0, height/5, 15, map(constrain(lowDiff-bombSize/2, 0, dectRadius), 0, dectRadius, 0, -height/5));
  popMatrix();
  stroke(255);
}
//Dectect if the player hits a bomb
void bombHit() {
  textSize(15);
  textAlign(CENTER);
  fill(255);
  rect(90, 150, width-110, 90);
  fill(0);
  text("You stepped on a mine!", width/2+35, height/2);
}
void blink() {
 if (arduinoConnected == true){
  if (lowDiff < bombSize + 10) {
    arduino.digitalWrite(redPin, Arduino.HIGH);
  } else {
    arduino.digitalWrite(redPin, Arduino.LOW);
  }
  if (lowDiff < bombSize + 50 && bombSize + 20 < lowDiff ) {
    arduino.digitalWrite(yellowPin, Arduino.HIGH);
  } else {
    arduino.digitalWrite(yellowPin, Arduino.LOW);
  }
  if (bombSize + dectRadius < lowDiff ) {
    arduino.digitalWrite(greenPin, Arduino.HIGH);
  } else {
    arduino.digitalWrite(greenPin, Arduino.LOW);
  }
 }
}
void createNoise() {
 if (arduinoConnected == true){
  if (playerHitBomb == false || lowDiff < bombSize+50) {
    if (millis() > map(lowDiff, 0, bombSize+60, 0, 100) + time) {
      arduino.digitalWrite(soundPin, Arduino.HIGH);
      time = millis();
      arduino.digitalWrite(soundPin, Arduino.LOW);
    } else {
      return;
      }
    }
  }
}
