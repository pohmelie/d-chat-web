import java.applet.*;
import javax.swing.*;
import javax.xml.bind.*;
import netscape.javascript.*;
import java.net.*;
import java.io.*;
import java.util.concurrent.*;
import java.util.*;
import java.nio.channels.*;
import java.nio.*;


public class JavaSocketBridge extends JApplet {

	JSObject browser = null;
	SocketChannel socket = null;

    boolean running = false;
    String address = null;
	int port = -1;
	boolean connectionDone = false;
    Queue<String> iqueue = null;

	public void init(){
		browser = JSObject.getWindow(this);
        iqueue = new ConcurrentLinkedQueue<String>();
	}

	public void stop(){
		running = false;
		disconnect();
	}
	public void destroy(){
		running = false;
		disconnect();
	}

	public void start(){
		browser.call("java_socket_bridge_set_ready", null);
		running = true;

		while(running){
			try{
				Thread.sleep(100);
			}
			catch(Exception ex){
				running = false;
				return;
			}

            // connect
			if(address != null && port != -1 && socket == null){
				do_connect(address, port);
			}

            else if(socket != null){
                // receive
                try{
                    ByteBuffer bb = ByteBuffer.allocate(65536);
                    int count = socket.read(bb);
                    if(count > 0){
                        info("[java] received some bytes");
                        Object[] arguments = new Object[1];
                        arguments[0] = pack(bb, count);
                        browser.call("java_socket_bridge_on_receive", arguments);
                    }
                }
                catch(Exception ex){
                    error("[java] could not read from socket\n"+ex.getMessage());
                }

                // send
                try{
                    while(!iqueue.isEmpty()){
                        info("[java] writing to socket");
                        socket.write(unpack(iqueue.poll()));
                    }
                }
                catch(Exception ex){
                    error("[java] could not write to socket\n"+ex.getMessage());
                }
            }
        }
    }

	public boolean connect(String url, int p){
		address = url;
		port = p;

		connectionDone = false;
		while(!connectionDone){
			try{ Thread.sleep(100); }
			catch(Exception ex){ return false; }
		}
		connectionDone = false;

		return socket != null;
	}

	private void do_connect(String url, int p){
		if(socket == null){
			try{
                info("[java] connecting...");
                socket = SocketChannel.open(new InetSocketAddress(url, p));
                socket.configureBlocking(false);
                while(!socket.isConnected()){
                    Thread.sleep(100);
                }
                info("[java] connected");
			}
			catch(Exception ex){
				error("[java] could not connect to " + url + " on port " + p + "\n" + ex.getMessage());
				connectionDone = true;
			}
		}
		else{
			info("[java] already connected");
		}
		connectionDone = true;
	}

	public boolean disconnect(){
		if(socket != null){
			try{
                info("[java] disconnecting...");
                socket.close();
                socket = null;
				address = null;
				port = -1;
                info("[java] disconnected");
				return true;
			}
			catch(Exception ex){
				error("[java] an error occured while closing the socket\n"+ex.getMessage());
				socket = null;
				return false;
			}
		}
		return false;
	}

	public void send(String s){
        //info("[java] adding '" + s + "' to queue");
        //iqueue.add(s);
        try{
            info("[java] writing to socket");
            socket.write(unpack(s));
        }
        catch(Exception ex){
            error("[java] could not write to socket\n"+ex.getMessage());
        }
	}

	public void info(String message){
		Object[] arguments = new Object[1];
		arguments[0] = message;
		browser.call("java_socket_bridge_info", arguments);
	}

    public void error(String message){
		Object[] arguments = new Object[1];
		arguments[0] = message;
		browser.call("java_socket_bridge_error", arguments);
	}

    private String pack(ByteBuffer buffer, int count){
        StringBuilder s = new StringBuilder();
        for(int i = 0; i != count; i++){
            if((i + 1) == count){
                s.append(String.format("%02x", buffer.get(i)));
            }
            else {
                s.append(String.format("%02x ", buffer.get(i)));
            }
        }
        return s.toString();
    }

    private ByteBuffer unpack(String s){
        s = s.replaceAll("\\s","");

        int len = s.length();
        byte[] data = new byte[len / 2];

        for (int i = 0; i < len; i += 2) {
            data[i / 2] = (byte) ((Character.digit(s.charAt(i), 16) << 4)
                                 + Character.digit(s.charAt(i+1), 16));
        }
        return ByteBuffer.wrap(data);
    }

}
