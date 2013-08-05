import java.applet.*;
import javax.swing.*;
import netscape.javascript.*;
import java.net.*;
import java.io.*;

public class JavaSocketBridge extends JApplet {

	JSObject browser = null;		// The browser
	Socket socket = null;			// The current socket
	OutputStream out = null;		// Output
	Listener listener = null;		// Listens for input
	boolean running = false;		// Am I still running?
	String address = null;			// Where you will connect to
	int port = -1;					// Port
	boolean connectionDone = false;	// Thread synchronization

	// Initialize
	public void init(){
		browser = JSObject.getWindow(this);
	}

	// Stop and destroy
	public void stop(){
		running = false;
		disconnect();
	}
	public void destroy(){
		running = false;
		disconnect();
	}

	// Main
	// Note: This method loops over and over to handle requests becuase only
	//       this thread gets the elevated security policy.  Java == stupid.
	public void start(){
		browser.call("java_socket_bridge_set_ready", null);
		running = true;
		while(running){
			// Wait
			try{
				Thread.sleep(100);
			}
			catch(Exception ex){
				running = false;
				return;
			}
			// Connect
			if(address != null && port != -1 && socket == null){
				do_connect(address, port);
			}
		}
	}

	// Connect
	public boolean connect(String url, int p){
		address = url;
		port = p;
		// Wait for the connection to happen in the main thread
		connectionDone = false;
        info("[java] connecting...");

		while(!connectionDone){
			try{ Thread.sleep(100); }
			catch(Exception ex){ return false; }
		}

		connectionDone = false;
        info("[java] connected");
		return socket != null;
	}

	private void do_connect(String url, int p){
		if(socket == null){
			try{
                socket = new Socket(url, p);
				out = socket.getOutputStream();
				listener = new Listener(socket, this);
				listener.start();
			}
			catch(Exception ex){
				error("[java] could not connect to " + url + " on port " + p + "\n" + ex.getMessage());
				connectionDone = true;
			}
		}
		else{
			error("[java] already connected");
		}
		connectionDone = true;
	}

	// Disconnect
	public boolean disconnect(){
		if(socket != null){
			try{
				info("[java] disconnecting...");
				listener.close();
				out.close();
				socket = null;
				address = null;
				port = -1;
                info("[java] disconnected");
				return true;
			}
			catch(Exception ex){
				error("[java] an error occured while closing the socket\n" + ex.getMessage());
				socket = null;
				return false;
			}
		}
		return false;
	}

	// Send a message
	public boolean send(String message){
		if(out != null){
			try{
				info("[java] sending '" + message + "'");
                out.write(unpack(message));
				out.flush();
			}
			catch(Exception ex){
				error("[java] could not write to socket\n" + ex.getMessage());
			}
			return true;
		}
		else{
			error("[java] not connected");
			return false;
		}
	}

	// Get input from the socket
	public void hear(String message){
        info("[java] received '" + message + "'");
		Object[] arguments = new Object[1];
		arguments[0] = message;
		browser.call("java_socket_bridge_on_receive", arguments);
	}

	// Report an error
	public void error(String message){
		Object[] arguments = new Object[1];
		arguments[0] = message;
		browser.call("java_socket_bridge_error", arguments);
	}

	// Log something
	public void info(String message){
		Object[] arguments = new Object[1];
		arguments[0] = message;
		browser.call("java_socket_bridge_info", arguments);
	}

	public String pack(byte[] buffer, int count){
        StringBuilder s = new StringBuilder();
        for(int i = 0; i != count; i++){
            if((i + 1) == count){
                s.append(String.format("%02x", buffer[i]));
            }
            else {
                s.append(String.format("%02x ", buffer[i]));
            }
        }
        return s.toString();
    }

    public byte[] unpack(String s){
        s = s.replaceAll("\\s","");

        int len = s.length();
        byte[] data = new byte[len / 2];

        for (int i = 0; i < len; i += 2) {
            data[i / 2] = (byte) ((Character.digit(s.charAt(i), 16) << 4)
                                 + Character.digit(s.charAt(i+1), 16));
        }
        return data;
    }
}
