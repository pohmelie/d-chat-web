import java.io.*;
import java.net.*;

// Thread that listens for input
public class Listener extends Thread{

	// Instance variables
	JavaSocketBridge parent;	// Report to this object
	Socket socket;				// Listen to this socket
	InputStream in; 			// Input
	boolean running = false;	// Am I still running?
    byte[] input_buffer = new byte[65536];

	// Constructor
	public Listener(Socket s, JavaSocketBridge b) throws IOException{
		parent = b;
		socket = s;
		in = s.getInputStream();
	}

	// Close
	public void close() throws IOException{
		if(running == false) return;
		running = false;
		socket.close();
		in.close();
	}

	// Main loop
	public void run(){
		running = true;
		int count;
		while(running){
			try{
				count = in.read(input_buffer);
                parent.hear(parent.pack(input_buffer, count));
			}
			catch(Exception ex){
				if(running){
					parent.error("An error occured while reading from the socket\n"+ex.getMessage());
					parent.disconnect();
					try{ close(); } catch(Exception ex2){}
				}
			}
		}
		try{ close(); } catch(Exception ex){}
	}
}
