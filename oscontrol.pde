public class OSControl {
    boolean handshook = false;

    public void route(OscMessage message) {
        String address = message.addrPattern();
        switch(address) {
            case "/handshake":
                handshakeSubtask();
        }
    }

    public void handshakeSend() {
        OscMessage message = new OscMessage("/handshake");
        osc.send(message, remote);
        message.add(1);
        settings.logger.log(" [handshake] Handshake sent...");
    }

    public void handshakeSubtask() {
        settings.logger.log(" [handshake] Success");
        handshook = true;
        delay(1000*5);
        handshook = false;
        settings.logger.log(" [handshake] Auto-checking Connection...");
        handshakeSend();
    }

    public void send(String address, int ... values) {
        settings.logger.log(" [osc] send: " + address);
        OscMessage message = new OscMessage(address);
        for(int value : values) {
            message.add(value);
        }
        osc.send(message, remote);
    }
}

void oscEvent(OscMessage message) {
	oscontrol.route(message);
}
