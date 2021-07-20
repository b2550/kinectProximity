// This will be converted to OpenFrameworks later for speed and flexability reasons
// SimpleOpenNI: https://github.com/totovr/SimpleOpenni
// SimpleOpenNI install instructions: https://github.com/totovr/SimpleOpenNI/blob/master/instructions.md
// DmxP512 instructions: http://motscousus.com/stuff/2011-01_dmxP512/

// Kinect broken? /libraries/libfreenect2/build and run `make install`
// Or on a new computer remove existing build directory and run `mkdir build; cd build; cmake; make; make install`

import SimpleOpenNI.*;
import oscP5.*;
import netP5.*;
import processing.serial.*;

//Generate a SimpleOpenNI object
SimpleOpenNI kinect;

OscP5 osc;
NetAddress remote;
OscMessage oscmsg;

Settings settings;
OSControl oscontrol;

boolean kinectOn = false;

String osc_address = "127.0.0.1";
int osc_recieve_port = 12001;
int osc_send_port = 12000;

boolean setupMode = true;
int setupPoint = 1;
ArrayList<Point> points = new ArrayList<Point>();

void settings() {
	size(640, 480);
}

void setup() {
	frameRate(25);

	String[] args = {"Settings"};
	settings = new Settings();
    settings.logger.log("Initializing...");
	PApplet.runSketch(args, settings);

	settings.drawGUI(this);

	oscontrol = new OSControl();

	settings.logger.log("Initializing OSC...");
	osc = new OscP5(this, osc_recieve_port);
	remote = new NetAddress(osc_address, osc_send_port);
	settings.logger.logf("OSC recieve started on %s:%d", osc_address, osc_recieve_port);
	settings.logger.logf("OSC send started on %s:%d", osc_address, osc_send_port);

	findKinect();
}

void draw() {
	background(0, 0, 0);
	if (kinectOn) {
		kinect.update();
		image(kinect.depthImage(), 0, 0);
		IntVector userList = new IntVector();
		kinect.getUsers(userList);

		if (userList.size() > 0) {
			int userId = userList.get(0);
			if (kinect.isTrackingSkeleton(userId)) {
				drawSkeleton(userId);

				PVector leftHandVec = new PVector();
				PVector leftHand = new PVector();
				kinect.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_HAND, leftHandVec);
				kinect.convertRealWorldToProjective(leftHandVec, leftHand);

				PVector rightHandVec = new PVector();
				PVector rightHand = new PVector();
				kinect.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_HAND, rightHandVec);
				kinect.convertRealWorldToProjective(rightHandVec, rightHand);

				oscontrol.send("/limb/lhand/x", int(leftHand.x));
				oscontrol.send("/limb/lhand/x", int(leftHand.y));
				oscontrol.send("/limb/lhand/x", int(leftHand.z));
				oscontrol.send("/limb/rhand/x", int(rightHand.x));
				oscontrol.send("/limb/rhand/x", int(rightHand.y));
				oscontrol.send("/limb/rhand/x", int(rightHand.z));

				if (setupMode) {
					fill(0, 255, 0);
					textAlign(RIGHT);
					text("SETUP MODE\nSetting up: " + setupPoint, 620, 40);
					textAlign(LEFT);
					ellipse(rightHand.x, rightHand.y, 20, 20);

					fill(255, 0, 0);
					textSize(32);
					text("R hand x: " + int(rightHand.x) +
					     "\nR hand y: " + int(rightHand.y) +
					     "\nR hand z:" + int(rightHand.z) +
					     "\nL hand x: " + int(leftHand.x) +
					     "\nL hand y: " + int(leftHand.y) +
					     "\nL hand z:" + int(leftHand.z), 20, 40);
          
          oscmsg = oscontrol.getMessage();
					if (oscmsg != null) {
						if (oscmsg.checkAddrPattern("/wii/1/button/A") && oscmsg.get(0).floatValue() == 1.0) {
              settings.logger.log("Point Added.");
							Point point = new Point((int)rightHand.x, (int)rightHand.y, (int)rightHand.z, setupPoint, 200);
							points.add(point);
							setupPoint += 1;
							delay(1000);
						} else if (oscmsg.checkAddrPattern("/wii/1/button/B") && oscmsg.get(0).floatValue() == 1.0) {
							setupMode = false;
							delay(1000);
						}
					}
					for (Point point : points) {
						point.draw();
					}
				} else {
					for (Point point : points) {
						point.update((int)rightHand.x, (int)rightHand.y, (int)rightHand.z, (int)leftHand.x, (int)leftHand.y, (int)leftHand.z);
						point.draw();
					}
				}
			}
		}
	}
}

public class Point {
	public int threshold;
	int x;
	int y;
	int z;
	int number;
	int value;

	public Point(int x, int y, int z, int number, int threshold) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.number = number;
		this.value = value;
	}

	public double distance2d(float x1, float y1, float x2, float y2) {
		return Math.sqrt(Math.pow(x2-x1, 2) + Math.pow(y2-y1, 2));
	}

	public double distance3d(float x1, float y1, float z1, float x2, float y2, float z2) {
		return Math.sqrt(Math.pow(x2-x1, 2) + Math.pow(y2-y1, 2) + Math.pow(z2-z1, 2));
	}

	public void update(int rightX, int rightY, int rightZ, int leftX, int leftY, int leftZ) {
		int distanceRight = (int)distance3d(x, y, z, rightX, rightY, rightZ);
		int distanceLeft = (int)distance3d(x, y, z, leftX, leftY, leftZ);

		if ((distanceRight > 0 && distanceRight < threshold) || (distanceLeft > 0 && distanceLeft < threshold)) {
			value = max(255-(int)((double)255*((double)distanceRight/(double)threshold)), 255-(int)((double)255*((double)distanceLeft/(double)threshold)));
		} else {
			value = 0;
		}

		oscontrol.send("/point/" + number + "/lhand/distance", distanceLeft);
		oscontrol.send("/point/" + number + "/rhand/distance", distanceRight);
	}

	public void draw() {
		fill(255, 0, 255);
		ellipse(this.x, this.y, 20, 20);
	}
}
