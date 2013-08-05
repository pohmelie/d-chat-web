javac -cp D:\tools\jdk\jre\lib\plugin.jar *.java
jar cf JavaSocketBridge.jar *.class
jarsigner JavaSocketBridge.jar yoba
pause
