void findKinect() {
	settings.logger.log("Looking for Kinect...");
	kinect = new SimpleOpenNI(this);

	int trys = 1;
	while (kinect.deviceCount() < 1 && trys <= 5) {
		settings.logger.logf("Error: Kinect not found! Waiting 3 seconds... (Try %d of 5)", trys);
		delay(3000);
		kinect = new SimpleOpenNI(this);
		trys++;
	}
	if (kinect.deviceCount() < 1) {
		kinectOn = false;
		settings.logger.log("Error: Kinect device discovery failed! Continuing without Kinect...");
	} else {
		kinectOn = true;
		settings.logger.log("Kinect device found");
		kinect.enableDepth();
		kinect.enableUser();
		kinect.setMirror(true);
	}
}

public void toggleSetup(GButton button, GEvent event) {
	if(setupMode) {
		setupMode = false;
		settings.logger.log("Setup Mode Off");
	} else {
		setupMode = true;
		settings.logger.log("Setup Mode On");
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
	fill(255, 0, 0);
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
	if (confidence < 0.9) {
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
	settings.logger.log("Found user: started tracking");
	kinect.startTrackingSkeleton(userId);
    oscontrol.send("/status/istracking", 1);
}

void onLostUser(SimpleOpenNI kinect, int userId) {
	settings.logger.log("Lost user: stopped tracking");
    oscontrol.send("/status/istracking", 0);
}

public void handshakeSend(GButton button, GEvent event) {
    oscontrol.handshakeSend();
}
