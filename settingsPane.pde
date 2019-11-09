import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import g4p_controls.*;

class Settings extends PApplet {
    public SettingsLogger logger = new SettingsLogger();

    public void drawGUI(PApplet target) {
        // GButton btn_update = new GButton(this, 450, 300, 100, 30, "Update");
        // btn_update.addEventHandler(target, "updateSettings");
        GButton btn_setup = new GButton(this, 800, 100, 100, 30, "Toggle Setup Mode");
        btn_setup.addEventHandler(target, "toggleSetup");
        GButton btn_handshake = new GButton(this, 800, 130, 100, 30, "Send handshake to Max");
        btn_handshake.addEventHandler(target, "handshakeSend");
        // GTextField txt_osc_send = new GTextField(this, 600, 100, 100, 24);
        // txt_osc_send.setText(Integer.toString(osc_send_port));
        // GTextField txt_osc_recieve = new GTextField(this, 600, 124, 100, 24);
        // txt_osc_recieve.setText(Integer.toString(osc_recieve_port));
    }

    private void updateGUI() {
        // Setup Mode Indicator
        if(setupMode) {
            fill(0,255,0);
        } else {
            fill(255,0,0);
        }
        circle(780, 115, 20);
        fill(0);
    }

	public void settings() {
		size(900, 600, JAVA2D);
	}

	public void draw() {
		background(255);
        updateGUI();
        String log = logger.getLog();
        fill(240);
        rect(0,0,450,300);
        fill(0);
        textAlign(LEFT,TOP);
        text(log, 0, 0, 450, 300);

        if(!kinectOn){
            fill(255,0,0);
            textAlign(RIGHT,TOP);
            text("KINECT NOT FOUND", 900, 0);
        }
	}

    private class SettingsLogger {
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        PrintStream log = new PrintStream(stream);

        public void log(String message) {
            System.out.println(message);
            log.append(formatLog(message));
        }

        public void logf(String message, Object ... values) {
            String output = String.format(message, values);
            log.append(formatLog(output));
            System.out.println(output);
        }

        public String getLog(){
            String output = "";
            String s = stream.toString();
            String lines[] = s.split("\n");
            int lineCount = lines.length - 1;
            if(lineCount < 0){
                lineCount = 0;
            }
            int startLine;
            if(lineCount > Integer.MAX_VALUE - 100){ // This protects against integer overflow in the unlikely case that many log messages are made
                log.flush();
            }
            if(lineCount >= 20){
                startLine = lineCount - 20;
            } else {
                startLine = 0;
            }
            for(int i = startLine; i <= lineCount; i++) {
                output = output + lines[i] + "\n";
            }
            return output;
        }

        private String formatLog(String message){
            DateFormat dateFormat = new SimpleDateFormat("HH:mm:ss S");
	        Date date = new Date();
            return String.format("[%s] %s\n", dateFormat.format(date), message);
        }
    }
}
