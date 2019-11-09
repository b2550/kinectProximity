// This will be converted to OpenFrameworks later for speed and flexability reasons
// SimpleOpenNI: https://github.com/totovr/SimpleOpenni
// SimpleOpenNI install instructions: https://github.com/totovr/SimpleOpenNI/blob/master/instructions.md
// DmxP512 instructions: http://motscousus.com/stuff/2011-01_dmxP512/

// Kinect broken? /libraries/libfreenect2/build and run `make install`
// Or on a new computer remove existing build directory and run `mkdir build; cd build; cmake; make; make install`

import SimpleOpenNI.*;
import dmxP512.*;
import oscP5.*;
import netP5.*;
import processing.serial.*;

//Generate a SimpleOpenNI object
SimpleOpenNI kinect;

DmxP512 dmxOutput;
int universeSize=128;

String DMXPRO_PORT="/dev/cu.usbserial-6A301V80"; // From `ls /dev`
int DMXPRO_BAUDRATE=115000;

OscP5 osc;
NetAddress remote;

OscMessage oscmsg;

void setup() {
        frameRate(25);
        size(640, 480);
        kinect = new SimpleOpenNI(this);

        int trys = 1;
        while(kinect.deviceCount() < 1) {
                System.out.format("Error: Kinect not found! Trying again in 3 seconds... (Try %d)\n", trys);
                delay(3000);
                kinect = new SimpleOpenNI(this);
                trys++;
        }
        System.out.println("Kinect device found!");
        kinect.enableDepth();
        kinect.enableUser();
        kinect.setMirror(true);

        dmxOutput=new DmxP512(this,universeSize,false);
        boolean dmxConnected = false;
        trys = 1;
        while(dmxConnected == false) {
                String[] ports = Serial.list();
                for(String port : ports) {
                        if(DMXPRO_PORT.equals(port)) {
                                dmxConnected = true;
                        }
                }
                if(dmxConnected == false) {
                        System.out.format("Error: DMX interface not found! Trying again in 3 seconds... (Try %d)\n", trys);
                }
                delay(3000);
        }
        System.out.println("DMX interface found!");
        dmxOutput.setupDmxPro(DMXPRO_PORT,DMXPRO_BAUDRATE);

        osc = new OscP5(this, "127.0.0.1", 12000);
}

boolean setupMode = true;
int setupFixture = 1;
ArrayList<Fixture> fixtures = new ArrayList<Fixture>();

void draw() {
        background(0,0,0);
        kinect.update();
        image(kinect.depthImage(), 0, 0);
        IntVector userList = new IntVector();
        kinect.getUsers(userList);

        if (userList.size() > 0) {
                int userId = userList.get(0);
                if ( kinect.isTrackingSkeleton(userId)) {
                    drawSkeleton(userId);

                    PVector leftHandVec = new PVector();
                    PVector leftHand = new PVector();
                    kinect.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_RIGHT_HAND,leftHandVec);
                    kinect.convertRealWorldToProjective(leftHandVec, leftHand);

                    PVector rightHandVec = new PVector();
                    PVector rightHand = new PVector();
                    kinect.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_LEFT_HAND,rightHandVec);
                    kinect.convertRealWorldToProjective(rightHandVec, rightHand);

                    fill(255,0,0);
                    textSize(32);
                    text("R hand x: " + int(rightHand.x) +
                         "\nR hand y: " + int(rightHand.y) +
                         "\nR hand z:" + int(rightHand.z) +
                         "\nL hand x: " + int(leftHand.x) +
                         "\nL hand y: " + int(leftHand.y) +
                         "\nL hand z:" + int(leftHand.z), 20, 40);

                    if(setupMode){
                        fill(0,255,0);
                        textAlign(RIGHT);
                        text("SETUP MODE\nSetting up: " + setupFixture, 620, 40);
                        textAlign(LEFT);
                        ellipse(rightHand.x, rightHand.y, 20, 20);
                        if(oscmsg != null) {
                            if(oscmsg.checkAddrPattern("/wii/1/button/A") && oscmsg.get(0).floatValue() == 1.0) {
                                Fixture fixture = new Fixture((int)rightHand.x, (int)rightHand.y, (int)rightHand.z, setupFixture, 3, 200);
                                fixtures.add(fixture);
                                setupFixture += 3;
                                delay(1000);
                            }
                            else if(oscmsg.checkAddrPattern("/wii/1/button/B") && oscmsg.get(0).floatValue() == 1.0) {
                                setupMode = false;
                                delay(1000);
                            }
                        }
                        for(Fixture fixture : fixtures){
                            fixture.draw();
                        }
                    }
                    else {
                        for(Fixture fixture : fixtures){
                            fixture.update((int)rightHand.x, (int)rightHand.y, (int)rightHand.z, (int)leftHand.x, (int)leftHand.y, (int)leftHand.z);
                            fixture.draw();
                        }
                    }
                }
        }
}

void drawSkeleton(int userId) {
        stroke(0);
        strokeWeight(5);
        kinect.drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);
        kinect.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
        kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
        kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);
        kinect.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
        kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
        kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);
        kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
        kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
        kinect.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
        kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
        kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);
        kinect.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
        kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
        kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);
        kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_LEFT_HIP);
        noStroke();
        fill(255,0,0);
        drawJoint(userId, SimpleOpenNI.SKEL_HEAD);
        drawJoint(userId, SimpleOpenNI.SKEL_NECK);
        drawJoint(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER);
        drawJoint(userId, SimpleOpenNI.SKEL_LEFT_ELBOW);
        drawJoint(userId, SimpleOpenNI.SKEL_NECK);
        drawJoint(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
        drawJoint(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW);
        drawJoint(userId, SimpleOpenNI.SKEL_TORSO);
        drawJoint(userId, SimpleOpenNI.SKEL_LEFT_HIP);
        drawJoint(userId, SimpleOpenNI.SKEL_LEFT_KNEE);
        drawJoint(userId, SimpleOpenNI.SKEL_RIGHT_HIP);
        drawJoint(userId, SimpleOpenNI.SKEL_LEFT_FOOT);
        drawJoint(userId, SimpleOpenNI.SKEL_RIGHT_KNEE);
        drawJoint(userId, SimpleOpenNI.SKEL_LEFT_HIP);
        drawJoint(userId, SimpleOpenNI.SKEL_RIGHT_FOOT);
        drawJoint(userId, SimpleOpenNI.SKEL_RIGHT_HAND);
        drawJoint(userId, SimpleOpenNI.SKEL_LEFT_HAND);
}

void drawJoint(int userId, int jointId) {
        fill(0, 0, 255);
        PVector joint = new PVector();
        float confidence = kinect.getJointPositionSkeleton(userId, jointId, joint);
        if(confidence < 0.9) {
                return;
        }
        PVector convertedJoint = new PVector();
        kinect.convertRealWorldToProjective(joint, convertedJoint);
        ellipse(convertedJoint.x, convertedJoint.y, 5, 5);
}
//Generate the angle
float angleOf(PVector one, PVector two, PVector axis) {
        PVector limb = PVector.sub(two, one);
        return degrees(PVector.angleBetween(limb, axis));
}

//Calibration not required
void onNewUser(SimpleOpenNI kinect, int userId) {
        println("Start skeleton tracking");
        kinect.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI kinect, int userId) {
        println("Lost user");
        for(int i = 1; i <= 128; i++) {
            dmxOutput.set(i, 0);
        }
}

public class Fixture {
    public int threshold;
    int x;
    int y;
    int z;
    int channel;
    int range;
    int intensity;

    public Fixture(int x, int y, int z, int channel, int range, int threshold) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.channel = channel;
        this.range = range;
        this.threshold = threshold;
    }

    public double distance2d(float x1, float y1, float x2, float y2){
        return Math.sqrt(Math.pow(x2-x1, 2) + Math.pow(y2-y1, 2));
    }

    public double distance3d(float x1, float y1, float z1, float x2, float y2, float z2){
        return Math.sqrt(Math.pow(x2-x1, 2) + Math.pow(y2-y1, 2) + Math.pow(z2-z1, 2));
    }

    public void update(int rightX, int rightY, int rightZ, int leftX, int leftY, int leftZ) {
        int distanceRight = (int)distance3d(x, y, z, rightX, rightY, rightZ);
        int distanceLeft = (int)distance3d(x, y, z, leftX, leftY, leftZ);

        if((distanceRight > 0 && distanceRight < threshold) || (distanceLeft > 0 && distanceLeft < threshold)) {
            intensity = max(255-(int)((double)255*((double)distanceRight/(double)threshold)), 255-(int)((double)255*((double)distanceLeft/(double)threshold)));
        } else {
            intensity = 0;
        }

        for(int i = channel; i < channel + range; i++){
            dmxOutput.set(i, intensity);
        }
    }

    public void draw() {
        fill(255,0,255);
        ellipse(this.x, this.y, 20, 20);
    }
}

void oscEvent(OscMessage oscevent) {
    oscmsg = oscevent;
    oscevent.print();
}
// public class RGBWlight extends Fixture {
//
// }
//
// public class CWlight extends Fixture {
//
// }
