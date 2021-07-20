public class OSControl {
    boolean handshook = false;
    OscMessage message;

    public void route(OscMessage message) {
        this.message = message;
        String address = message.addrPattern();
        settings.logger.logf("[osc recieve] %s", address);
        switch(address) {
            case "/handshake":
                handshakeSubtask();
                break;
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
        this.handshook = true;
        delay(1000*5);
        this.handshook = false;
        settings.logger.log(" [handshake] Auto-checking Connection...");
        handshakeSend();
    }

    public void send(String address, int ... values) {
        //settings.logger.log(" [osc] send: " + address);
        OscMessage message = new OscMessage(address);
        for(int value : values) {
            message.add(value);
        }
        osc.send(message, remote);
    }
    
    public OscMessage getMessage() {
      return this.message;
    }
}

void oscEvent(OscMessage message) {
	oscontrol.route(message);
}
