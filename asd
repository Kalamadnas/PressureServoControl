
#include <SD.h>
#include <Wire.h>
#include "SparkFunMPL3115A2.h"
#include <Servo.h>
#include "RunningMedian.h"

// ------------------------------- running median jutut

RunningMedian samples = RunningMedian(5); // kuinka monen arvon mediaani
long count = 0;

// ------------------------------- running median loppu

Servo myservoA;  // create servo object to control a servo
Servo myservoB;  // create servo object to control a servo

//Create an instance of the object
MPL3115A2 myPressure;

unsigned long previousMillis = 0;          

// servo variables will change:
int posA = 0;    // variable to store the servo position
int posB = 0;    // variable to store the servo position

// initialize the sensor:
const int chipSelect = 4;         // SPI chip select for SD card
const int cardDetect = 7;          // pin that detects whether the card is there
const int writeLed = 8;           // LED indicator for writing to card
const int errorLed = 13;          // LED indicator for error
long lastWriteTime = 0;           // timestamp for last write attempt
const int interval = 2000;            // time between readings
const int timer = 1000;            // aikaraja jonka jälkeen laskuvarjo voidaan vapauttaa
char fileName[] = "datalog.txt";  // filename to save on SD card

void setup() {

    Wire.begin();        // Join i2c bus
  Serial.begin(9600);  // Start serial for output

  //Configure the sensor
  myPressure.begin(); // Get sensor online
  myPressure.setModeAltimeter(); // Measure altitude above sea level in meters
  myPressure.setOversampleRate(7); // Set Oversample to the recommended 128
  myPressure.enableEventFlags(); // Enable all three pressure and temp event flags 

  myservoA.attach(12);  // attaches the servo on pin 9 to the servo object
  //myservoB.attach(9);  // attaches the servo on pin 10 to the servo object

    for (posA = 180; posA >= 0; posA -= 1) 
    { // goes from 180 degrees to 0 degree
      myservoA.write(posA);              // tell servo to go to position in variable 'pos'
      delay(15);                       // waits 15ms for the servo to reach the position
    }

  // initialize LED and cardDetect pins:
  pinMode(writeLed, OUTPUT);
  pinMode(errorLed, OUTPUT);
  pinMode(cardDetect, INPUT_PULLUP);
  
  // startSDCard() blocks everything until the card is present
  // and writable:
  if (startSDCard() == true) {
    Serial.println("card initialized.");
    delay(100);
    // open the log file:
    File logFile = SD.open(fileName, FILE_WRITE);
    // write header columns to file:
    if (logFile) {
      logFile.println("pressure:");
      logFile.close();
    }
  }
}


void loop() {

  // if the card's not there, don't do anything more:
  if (digitalRead(cardDetect) == LOW) {
    digitalWrite(errorLed, HIGH);
    return;
  }
  digitalWrite(errorLed, LOW);   // turn of the error LED

  unsigned long currentMillis = millis();

  // read sensors every 10 seconds
  if (millis()  - lastWriteTime >=  interval) 
   {
      File logFile = SD.open(fileName, FILE_WRITE);   // open the log file
        if (logFile) {                                  // if you can write to the log file,
        digitalWrite(writeLed, HIGH);                 // turn on the write LED
        // read sensor:
        float temperature_ulko = myPressure.readTemp();
        float altitude = myPressure.readAltitude();

        // print to the log file:
        logFile.print(altitude);
        logFile.print(",");
        logFile.println(temperature_ulko);
        logFile.close();                    // close the file

        // korkeusdebug alkaa tästä

        Serial.print("Altitude(m):");
        Serial.print(altitude, 2);
        Serial.print('\t');
  //    Serial.print(" Temp(c):");
  //    Serial.print(temperature_ulko, 2);

        // update the last attempted save time:
        lastWriteTime = millis(); 
        }

  //-------------------------median juttua

  //  if (count % 20 == 0) Serial.println(F("\nmsec \tAnR \tSize \tCnt \tLow \tAvg \tAvg(3) \tMed \tHigh"));
  //  count++;

  long x = myPressure.readAltitude();
  samples.add(x);

  //  float l = samples.getLowest();
  float m = samples.getMedian();
  //  float a = samples.getAverage();
  //  float a3 = samples.getAverage(3);
  //  float h = samples.getHighest();
  //  int s = samples.getSize();
  //  int c = samples.getCount();

  Serial.print(m);
  Serial.print('\t');
  delay(1000);

  /*  Serial.print(millis());
  Serial.print('\t');
  Serial.print(x);
  Serial.print('\t');
  Serial.print(s);
  Serial.print('\t');
  Serial.print(c);
  Serial.print('\t');
  Serial.print(l);
  Serial.print('\t');
  Serial.print(a, 2);
  Serial.print('\t');
  Serial.print(a3, 2);
  Serial.print('\t');
  Serial.print(m);
  Serial.print('\t');
  Serial.println(h);
  delay(100); */ 

  //-------------------------median juttua loppuu

  
     if (millis() >=  timer && m <= 200)
     { 
       for (posA = 0; posA <= 180; posA += 1) 
        { // goes from 0 degrees to 180 degrees
          // in steps of 1 degree
        myservoA.write(posA);              // tell servo to go to position in variable 'pos'
        delay(15);                       // waits 15ms for the servo to reach the position
        }
     }  
   
  digitalWrite(writeLed, LOW);      // turn off the write LED
  Serial.println();   
  }  
  
}


  
  

boolean startSDCard() {
  // Wait until the card is inserted:
  while (digitalRead(cardDetect) == LOW) {
    Serial.println("Waiting for card...");
    digitalWrite(errorLed, HIGH);
    delay(750);
  }

  // wait until the card initialized successfully:
  while (!SD.begin(chipSelect)) {
    digitalWrite(errorLed, HIGH);   // turn on error LED
    Serial.println("Card failed");
    delay(750);
  }
  return true;
}
