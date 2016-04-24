/* Magic Mirror UI
 * Daniel Strawn
 */

import java.util.Date;

PFont woodWarriorLight;
PFont woodWarriorBold;
PFont woodWarriorRegular;
PFont Modulo;


float[] animationCurve = new float[60];
int clockX = 384;
int clockY = 40;
int[] currentTime = new int[3];
int c = 0;
String[] months = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};
String[] weekDays = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
int day = new Date().getDay() + 7;
float yRatio;

//Set US city for Weather API
String city = "Boulder";

//Set API key for Weather API
String apiKey = "82e1fdd5ea81c1e7a6d1164e0022ae2c";

int curTemp;
int curHigh;
int curLow;
int numFetches = 0;

//true = Celsius
//false = Fahrenheit
boolean tU = false;

//invert image
boolean invert = false;

void setup() {
  noCursor();
  size(900, 1440);
  yRatio = (240.0/1440.0)*height;
  frameRate(60);
  fill(255);
  woodWarriorLight = createFont("Woodwarrior-Light.otf", 32);
  woodWarriorBold = createFont("Woodwarrior-Bold.otf", 32);
  woodWarriorRegular = createFont("Woodwarrior-Regular.otf", 32);
  Modulo = createFont("Modulo.otf", 32);

  currentTime[0] = hour();
  currentTime[1] = getMinuteTen();
  currentTime[2] = getMinuteOne();

  for (int i = 0; i < 60; i++) {
    animationCurve[i] = ((-15*(1-i)*(1+i))+1)*0.000287356;
    println(animationCurve[i]);
  }
  thread("fetchWeather");
}

void draw() {
  background(0);
  textFont(woodWarriorLight, 32);
  
  text(city, 8, height-8);
  
  //update day every midnight
  if (hour() == 0) day = new Date().getDay() + 7;
  
  //automatically refresh weather data every 15 minutes.
  if ((minute())%15 == 0) thread("fetchWeather");

  if (currentTime[1] != getMinuteTen()) {
    newMinuteTen();
  } else {
    if (minute() < 10) {
      text("0", clockX+40, clockY);
    } else {
      text(getMinuteTen(), clockX+40, clockY);
    }
  }

  if (currentTime[2] != getMinuteOne()) {
    newMinuteOne();
  } else {
    text(getMinuteOne(), clockX+64, clockY);
  }

  if (currentTime[0] != hour()) {
    newHour();
  } else {
    if (hour() < 10) {
      text("0", clockX-24, clockY);
      text(hour(), clockX, clockY);
    } else {
      text(hour(), clockX-24, clockY);
    }
  }

  text(second(), clockX+104, clockY);
  text(".", clockX+88, clockY);
  text(".", clockX+88, clockY-16);
  text(".", clockX+24, clockY);
  text(".", clockX+24, clockY-16);

  if (second()%2 == 1 || c == 0)
  {
    c = 59;
    //println("resetting c");
  } else {
    c -= 60/int(frameRate);
    c = constrain(c, 0, 59);
  }

  switch(month()) {
  case 2:
    drawDays(28);
    break;
  case 4:
    drawDays(30);
    break;
  case 6:
    drawDays(30);
    break;
  case 9:
    drawDays(30);
    break;
  case 11:
    drawDays(30);
    break;
  default:
    drawDays(31);
    break;
  }

  drawMonth();
  drawTemp();
  if(invert) filter(INVERT);
}

void fetchWeather() {
  JSONObject currentWeather = loadJSONObject("http://api.openweathermap.org/data/2.5/weather?q="+city+"us&appid="+apiKey);
  curTemp = tConv(currentWeather.getJSONObject("main").getFloat("temp"));
  curHigh = tConv(currentWeather.getJSONObject("main").getFloat("temp_max"));
  curLow  = tConv(currentWeather.getJSONObject("main").getFloat("temp_min"));
  numFetches++;
}

void drawTemp() {
  scale(0.75, 0.75);
  translate(width/6, height/3);
  fill(255);
  stroke(255);
  strokeWeight(4);
  textFont(woodWarriorLight, 72);
  textAlign(RIGHT);
  if (curTemp < 0) {
    rect(width/2 - 136, height-48, 18, 4);
  }
  if (abs(curTemp) < 10) {
    text("0"+abs(curTemp), width/2, height-12);
  } else {
    text(abs(curTemp), width/2, height-12);
  }
  textSize(36);
  textAlign(LEFT);

  if (tU == false) {
    text("f", width/2, height-12);
  } else {    
    text("c", width/2, height-12);
  }
  noFill();
  ellipse(width/2+8, height-76, 12, 12);
  rect(width/2 + 64, height-48, 32, 0);
  textSize(24);
  if (curHigh < 0) {
    rect(width/2+36, height-70, 3, 0);
  }
  if (curLow < 0) {
    rect(width/2+36, height-24, 3, 0);
  }
  text(abs(curHigh), width/2+44, height-58);
  text(abs(curLow), width/2+44, height-12);
  
  translate(-width/6, -height/3);
  scale(4/3, 4/3);
  textAlign(BASELINE);
}

void keyPressed(){
  if (key == 't'){
    tU = !tU;
    fetchWeather();
  }
  
  if (key == 'i'){
    invert = !invert;
  }
}

//helper function convert tempurate delivered from weather API from kelvin to *
int tConv(float kelvin) {
  if (tU == false) {
    return round(((9.0/5.0)*(kelvin-273.0))+32.0);
  } else {
    return round(kelvin - 273.15);
  }
}

void drawMonth() {
  textFont(Modulo, 32);
  //text(months[month()-1], 8, 28);
  for (int i = 0; i < months[month() - 1].length(); i++) {
    text(stringArray(months[month() - 1], i), width - 32, (height/2 - 32*months[month() - 1].length()/2)+i*32);
  }
}

//helper function that treats strings as arrays of characters.
char stringArray(String toChar, int arrInd) {
  char[] arr = toChar.toCharArray();
  return arr[arrInd];
}

void drawDays(int numDays) {
  textFont(woodWarriorRegular, 14);
  rectMode(RADIUS);
  for (int i = 0; i < numDays; i++) {
    if (i+1 == day()) {
      fill(128, 255);
      text(weekDays[day - 1], 40, yRatio+(i-1)*32);
      text(weekDays[day + 1], 40, yRatio+(i+1)*32);
      fill(96, 255);
      text(weekDays[day - 2], 40, yRatio+(i-2)*32);
      text(weekDays[day + 2], 40, yRatio+(i+2)*32);
      fill(64, 255);
      text(weekDays[day - 3], 40, yRatio+(i-3)*32);
      text(weekDays[day + 3], 40, yRatio+(i+3)*32);
      fill(48, 255);
      text(weekDays[day - 4], 40, yRatio+(i-4)*32);
      text(weekDays[day + 4], 40, yRatio+(i+4)*32);
      fill(32, 255);
      text(weekDays[day - 5], 40, yRatio+(i-5)*32);
      text(weekDays[day + 5], 40, yRatio+(i+5)*32);      
      fill(255);
      rect(20, yRatio-(height*8.0/1440)+i*32, 15, 15, 6);
      text(weekDays[day], 40, yRatio+i*32);
      fill(0);
      text(i+1, 10, yRatio+i*32);
    } else {
      fill(255);
      text(i+1, 10, yRatio+i*32);
    }
  }
}

void newHour() {
  translate(0, -4*animationCurve[c]);
  fill(c*4);
  if (hour() < 10) {
    text("0", clockX-24, clockY+60);
    text(currentTime[0], clockX, clockY+60);
  } else {
    text(currentTime[0], clockX-24, clockY+60);
  } 

  fill(255);
  if (hour() < 10) {
    text("0", clockX-24, clockY);
    text(hour(), clockX, clockY);
  } else {
    text(hour(), clockX-24, clockY);
  }
  translate(0, 4*animationCurve[c]);
  if (c == 0) {
    currentTime[0] = hour();
  }
}

void newMinuteOne() {
  translate(0, -4*animationCurve[c]);
  fill(c*4);
  text(currentTime[2], clockX+64, clockY+60); 

  fill(255);
  text(getMinuteOne(), clockX+64, clockY);
  translate(0, 4*animationCurve[c]);
  if (c == 0) {
    currentTime[2] = getMinuteOne();
  }
}

void newMinuteTen() {
  translate(0, -4*animationCurve[c]);
  fill(c*4);
  text(currentTime[1], clockX+40, clockY+60);

  fill(255);  
  text(minute(), clockX+40, clockY);
  translate(0, 4*animationCurve[c]);
  if (c == 0) {
    currentTime[1] = getMinuteTen();
  }
}

//helper functions to split minutes
int getMinuteOne() {
  int[] minArr = new int[2];
  int curMin = minute();
  minArr[0] = curMin % 10;
  curMin /= 10;
  minArr[1] = curMin % 10;
  return minArr[0];
}

int getMinuteTen() {
  int[] minArr = new int[2];
  int curMin = minute();
  minArr[0] = curMin % 10;
  curMin /= 10;
  minArr[1] = curMin % 10;
  return minArr[1];
}