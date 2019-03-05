var (width,height) = (420,160);
var title = 'My new Window';

# create a new window, dimensions are WIDTH x HEIGHT, using the dialog decoration (i.e. titlebar)
var window = canvas.Window.new([width,height],"dialog")
 .set('title',title);


##
# the del() function is the destructor of the Window
# which will be called upon termination (dialog closing)
# you can use this to do resource management (clean up timers, listeners or background threads)
#window.del = func()
#{
#  print("Cleaning up window:",title,"\n");
# explanation for the call() technique at: http://wiki.flightgear.org/Object_oriented_programming_in_Nasal#Making_safer_base-class_calls
#  call(canvas.Window.del, [], me);
#};

# adding a canvas to the new window and setting up background colors/transparency
var windowcanvas = window.createCanvas().set("background", canvas.style.getColor("bg_color"));

# Using specific css colors would also be possible:
# myCanvas.set("background", "#ffaac0");

# creating the top-level/root group which will contain all other elements/group
var root = windowcanvas.createGroup();
var layout = canvas.VBoxLayout.new();

var label_autostart = canvas.gui.widgets.Label.new(root, canvas.style, {wordWrap: 0})
	.setText("Autostart the aircraft")
	.move(10,20);
var button_autostart = canvas.gui.widgets.Button.new(root, canvas.style, {})
	.setText("Autostart")
	.setSize(150,25)
	.move(250,7)
	.listen("clicked", func() {
			mig21.autostart(1);
		});

var label_autoshutdown = canvas.gui.widgets.Label.new(root, canvas.style, {wordWrap: 0})
	.setText("Shutdown the aircraft")
	.move(10,45);
var button_autoshutdown = canvas.gui.widgets.Button.new(root, canvas.style, {})
	.setText("Shutdown")
	.setSize(150,25)
	.move(250,32)
	.listen("clicked", func() {
			mig21.autostart(0);
		});


layout.addItem(label_autostart);
layout.addItem(button_autostart);

layout.addItem(label_autoshutdown);


# .setEEnabled(0|1)
# .move(x,y)
# .setSize(w,h)
