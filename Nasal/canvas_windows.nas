
var stores_dialog = "";

var showStoresDialog = func
{
  stores_dialog = canvas.Window.new ([790,480],"dialog");
  stores_dialog.setPosition(40,40);
  stores_dialog.set("title","Payloads");
  stores_dialog.setCanvas(stores.new().get_canvas());

  #grabButton.addEventListener("drag", func(e) stores_dialog.move(e.deltaX, e.deltaY));
  #updateStationsDisplay();
}

var stores = {
    canvas_settings: {"name": "Stores Dialog",
                      "size": [790, 480],
                      "view": [790, 480],
                      "mipmapping": 0,
                    },
    new: func() {
        var m = {
            parents: [stores],
            stores_canvas: canvas.new(stores.canvas_settings),
        };
        m.root = m.stores_canvas.createGroup();

        m.p3opt = [
                    ["None",     
                                ["none"]],
                    ["Bomb",     
                                ["FAB-100",
                                "FAB-250",
                                "P-100"]],
                    ["A/A Missile", 
                                ["R-3S",
                                "R-3R",
                                "R-60",
                                "R-60x2",]],
                    ["A/G Missile",
                                ["Kh-66",]],
                    ["Rocket", 
                                ["UB-16",
                                "S-24",]],
                    ["Droptank",
                                ["PTB-490 Droptank",]],
        ];
        m.p1opt = [
                    ["None",     
                                ["none"]],
                    ["Bomb",     
                                ["FAB-100",
                                "FAB-100x4",
                                "FAB-250",
                                "FAB-500",
                                "BETAB-500ShP",
                                "P-100",
                                "P-100x4"]],
                    ["A/A Missile", 
                                ["R-3S",
                                "R-3R",
                                "R-60",
                                "R-27T1",
                                "R-27R1",]],
                    ["A/G Missile",
                                ["Kh-66",
                                "Kh-25MP",]],
                    ["Rocket", 
                                ["UB-16",
                                "UB-32",
                                "S-24",]],
        ];
        m.copt = [
                    ["None",     
                                ["none"]],
                    ["Droptank", 
                                ["PTB-490 Droptank",
                                "PTB-800 Droptank",]],
                    ["Misc",
                                ["Smokepod",
                                "RN-28"]],
        ];
        m.p2opt = m.p1opt;
        m.p4opt = m.p3opt;
        m.oblopt = [
                    ["None",     
                                ["none"]],
                    ["Countermeasure",
                                ["Conformal CM"]],
        ];
        m.obropt = m.oblopt;
        m.cconopt = [
                    ["None",     
                                ["none"]],
        ];

        # do the line splits manually
        # limit 20 characters per line
        # first line is the store name
        # 21 lines for info
        m.store_info = {
            "none"  :   [
                        #12345678901234567890 
                        "There is nothing",
                        "selected on this",
                        "pylon.",
                        ],
            "FAB-100" : [
                        #12345678901234567890
                        "A 100 kilogram free-",
                        "fall bomb.",
                        ],
            "FAB-100x4" : [
                        #12345678901234567890
                        "Four FAB-100's on a",
                        "specially designed",
                        "launcher rail.",
                        ],
            "P-100"     : [
                        #12345678901234567890
                        "A practice bomb",
                        "which emits a white",
                        "smoke upon impact.",
                        "Has the same",
                        "characteristics as",
                        "a FAB-100.",
                        ],
            "P-100x4" : [
                        #12345678901234567890
                        "Four P-100's on a",
                        "specially designed",
                        "launcher rail.",
                        ],
            "FAB-250"   : [
                        #12345678901234567890
                        "A 250 kilogram free-",
                        "fall bomb.",
                        ],
            "FAB-500"   : [
                        #12345678901234567890
                        "A 500 kilogram free-",
                        "fall bomb.",
                        ],
            "BETAB-500ShP" : [
                        #12345678901234567890
                        "A 500 kilogram high",
                        "drag bunker buster",
                        "designed for runway",
                        "denial and",
                        "destroying hardened",
                        "targets.",
                        ],
            "R-3S"   : [
                        #12345678901234567890
                        "A short range, heat-",
                        "seeking missile that",
                        "entered service in  ",
                        "1961. Manufactured  ",
                        "by Vympel."
                        ],
            "R-3R"   : [
                        #12345678901234567890
                        "A short range, radar",
                        "guided missile that",
                        "entered service in",
                        "1966. Manufactured",
                        "by Vympel."
                        ],
            "R-60"   : [
                        #12345678901234567890
                        "A short range, heat-",
                        "seeking missile that",
                        "entered service in  ",
                        "1974. Manufactured  ",
                        "by Vympel."
                        ],
            "R-60x2"   : [
                        #12345678901234567890
                        "Two R-60's mounted",
                        "on a specially",
                        "designed launcher.",
                        ],
            "R-27R1"   : [
                        #12345678901234567890
                        "A long range, radar",
                        "guided missile, that",
                        "entered service in",
                        "1983. Manufactured",
                        "by Vympel.",
                        ],
            "R-27T1"   : [
                        #12345678901234567890
                        "A long range, heat",
                        "seeking missile that",
                        "entered service in",
                        "1983. Manufactured",
                        "by Vympel.",
                        ],
            "Kh-66"   : [
                        #12345678901234567890
                        "A short range beam-",
                        "riding missile,",
                        "used to attack",
                        "both ground and slow",
                        "moving air targets.",
                        "Entered service in",
                        "1968. Manufactured",
                        "by Zvezda-Strela.",
                        ],
            "Kh-25MP"   : [
                        #12345678901234567890
                        "A medium range anti-",
                        "radiation missile",
                        "used to attack",
                        "ground targets, such",
                        "as SAMs. Entered",
                        "service in 1975.",
                        "Manufactured by ",
                        "Zvezda-Strela.",
                        ],
            "UB-16"   : [
                        #12345678901234567890
                        "A rocket pod which",
                        "contains 16 S-5",
                        "rockets.",
                        ],
            "UB-32"   : [
                        #12345678901234567890
                        "A rocket pod which",
                        "contains 32 S-5",
                        "rockets.",
                        ],
            "S-24"   : [
                        #12345678901234567890
                        "A large diameter",
                        "rocket.",
                        ],
            "PTB-490 Droptank"   : [
                        #12345678901234567890
                        "A 490 liter drop",
                        "tank.",
                        ],
            "PTB-800 Droptank"   : [
                        #12345678901234567890
                        "A 800 liter drop",
                        "tank.",
                        ],
            "Smokepod"   : [
                        #12345678901234567890
                        "A missile-shaped",
                        "smokepod for use in",
                        "training and aerial",
                        "demonstrations.",
                        ],
            "RN-28"   : [
                        #12345678901234567890
                        "An inert, static",
                        "nuclear device for",
                        "training and display",
                        ],
            "Conformal CM"   : [
                        #12345678901234567890
                        "A conformal counter-",
                        "measure pod.",
                        "Contains 9 chaff and",
                        "20 flares. Works in",
                        "sync with a CM pod",
                        "on the opposing side",
                        "of the fuselage.",
                        ],

        };

        m.pylon_selected = 0;
        m.outer_group_selected = 0;
        m.inner_group_selected = 0;

        m.font_size = 18;
        m.font_color = [1,1,1];
        m.selected_color = [0,1,0];

        m.p3 = m.root.createChild("text", "p3label")
                    .setTranslation(10, 20)
                    .setAlignment("left-center")
                    .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                    .setFontSize(m.font_size, 1.0)
                    .setColor(m.selected_color)
                    .setText("Pylon 3");
                    
        m.p3store = m.root.createChild("text", "p3store")
                    .setTranslation(10,40)
                    .setAlignment("left-center")
                    .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                    .setFontSize(m.font_size, 1.0)
                    .setColor(m.selected_color)
                    .setText(getprop("/payload/weight[0]/selected"));

        m.p3click = m.root.createChild("path")
                    .setTranslation(10,5)
                    .horiz(180)
                    .vert(50)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.pylon_click(0)});
                    
        m.p1 = m.root.createChild("text", "p1label")
                    .setTranslation(10, 80)
                    .setAlignment("left-center")
                    .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                    .setFontSize(m.font_size, 1.0)
                    .setColor(m.font_color)
                    .setText("Pylon 1");
                    
        m.p1store = m.root.createChild("text", "p1store")
                    .setTranslation(10,100)
                    .setAlignment("left-center")
                    .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                    .setFontSize(m.font_size, 1.0)
                    .setColor(m.font_color)
                    .setText(getprop("/payload/weight[1]/selected"));

        m.p1click = m.root.createChild("path")
                    .setTranslation(10,65)
                    .horiz(180)
                    .vert(50)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.pylon_click(1)});
                    
        m.pc = m.root.createChild("text", "pclabel")
                    .setTranslation(10, 140)
                    .setAlignment("left-center")
                    .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                    .setFontSize(m.font_size, 1.0)
                    .setColor(m.font_color)
                    .setText("Pylon Center");
                    
        m.pcstore = m.root.createChild("text", "pcstore")
                    .setTranslation(10,160)
                    .setAlignment("left-center")
                    .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                    .setFontSize(m.font_size, 1.0)
                    .setColor(m.font_color)
                    .setText(getprop("/payload/weight[2]/selected"));

        m.pcclick = m.root.createChild("path")
                    .setTranslation(10,125)
                    .horiz(180)
                    .vert(50)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.pylon_click(2)});
                    
        m.p2 = m.root.createChild("text", "p2label")
                    .setTranslation(10, 200)
                    .setAlignment("left-center")
                    .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                    .setFontSize(m.font_size, 1.0)
                    .setColor(m.font_color)
                    .setText("Pylon 2");
                    
        m.p2store = m.root.createChild("text", "p2store")
                    .setTranslation(10,220)
                    .setAlignment("left-center")
                    .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                    .setFontSize(m.font_size, 1.0)
                    .setColor(m.font_color)
                    .setText(getprop("/payload/weight[3]/selected"));

        m.p2click = m.root.createChild("path")
                    .setTranslation(10,185)
                    .horiz(180)
                    .vert(50)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.pylon_click(3)});
                    
        m.p4 = m.root.createChild("text", "p4label")
                    .setTranslation(10, 260)
                    .setAlignment("left-center")
                    .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                    .setFontSize(m.font_size, 1.0)
                    .setColor(m.font_color)
                    .setText("Pylon 4");
                    
        m.p4store = m.root.createChild("text", "p4store")
                    .setTranslation(10,280)
                    .setAlignment("left-center")
                    .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                    .setFontSize(m.font_size, 1.0)
                    .setColor(m.font_color)
                    .setText(getprop("/payload/weight[4]/selected"));

        m.p4click = m.root.createChild("path")
                    .setTranslation(10,245)
                    .horiz(180)
                    .vert(50)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.pylon_click(4)});
                    
        m.obl = m.root.createChild("text", "obllabel")
                    .setTranslation(10, 320)
                    .setAlignment("left-center")
                    .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                    .setFontSize(m.font_size, 1.0)
                    .setColor(m.font_color)
                    .setText("Outboard Left");
                    
        m.oblstore = m.root.createChild("text", "oblstore")
                    .setTranslation(10,340)
                    .setAlignment("left-center")
                    .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                    .setFontSize(m.font_size, 1.0)
                    .setColor(m.font_color)
                    .setText(getprop("/payload/weight[5]/selected"));

        m.oblclick = m.root.createChild("path")
                    .setTranslation(10,305)
                    .horiz(180)
                    .vert(50)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.pylon_click(5)});
                    
        m.obr = m.root.createChild("text", "obrlabel")
                    .setTranslation(10, 380)
                    .setAlignment("left-center")
                    .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                    .setFontSize(m.font_size, 1.0)
                    .setColor(m.font_color)
                    .setText("Outboard Right");
                    
        m.obrstore = m.root.createChild("text", "obrstore")
                    .setTranslation(10,400)
                    .setAlignment("left-center")
                    .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                    .setFontSize(m.font_size, 1.0)
                    .setColor(m.font_color)
                    .setText(getprop("/payload/weight[6]/selected"));

        m.obrclick = m.root.createChild("path")
                    .setTranslation(10,365)
                    .horiz(180)
                    .vert(50)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.pylon_click(6)});
                    
        m.ccon = m.root.createChild("text", "cconlabel")
                    .setTranslation(10, 440)
                    .setAlignment("left-center")
                    .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                    .setFontSize(m.font_size, 1.0)
                    .setColor(m.font_color)
                    .setText("Center Console");
                    
        m.cconstore = m.root.createChild("text", "cconstore")
                    .setTranslation(10,460)
                    .setAlignment("left-center")
                    .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                    .setFontSize(m.font_size, 1.0)
                    .setColor(m.font_color)
                    .setText("none");

        m.cconclick = m.root.createChild("path")
                    .setTranslation(10,425)
                    .horiz(180)
                    .vert(50)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1);

        m.outerselectiongroup = [];
        m.innerselectiongroup = [];
        m.infobox = [];
        for ( var i = 0; i < 23; i = i + 1 ) {
            append(m.outerselectiongroup, m.root.createChild("text")
                    .setTranslation(200,20 + (20 * i))
                    .setAlignment("left-center")
                    .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                    .setFontSize(m.font_size, 1.0)
                    .setColor(m.font_color));
            append(m.innerselectiongroup, m.root.createChild("text")
                    .setTranslation(400,20 + (20 * i))
                    .setAlignment("left-center")
                    .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                    .setFontSize(m.font_size, 1.0)
                    .setColor(m.font_color));
            append(m.infobox, m.root.createChild("text")
                    .setTranslation(600,20 + (20 * i))
                    .setAlignment("left-center")
                    .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                    .setFontSize(m.font_size * 0.8, 1.0)
                    .setColor(m.font_color));
        }

        m.infobox[0].setColor(m.selected_color);

        m.infobox_outline = m.root.createChild("path")
                    .setTranslation(600,7)
                    .horiz(180)
                    .vert(460)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1);

        m.outerselectionclick = [
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 0))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(0);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 1))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(1);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 2))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(2);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 3))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(3);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 4))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(4);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 5))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(5);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 6))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(6);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 7))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(7);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 8))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(8);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 9))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(9);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 10))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(10);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 11))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(11);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 12))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(12);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 13))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(13);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 14))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(14);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 15))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(15);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 16))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(16);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 17))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(17);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 18))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(18);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 19))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(19);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 20))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(20);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 21))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(21);}),
            m.root.createChild("path")
                    .setTranslation(200,7 + (20 * 22))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.outer_click(22);}),
        ];

        m.innerselectionclick = [
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 0))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(0);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 1))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(1);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 2))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(2);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 3))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(3);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 4))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(4);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 5))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(5);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 6))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(6);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 7))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(7);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 8))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(8);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 9))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(9);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 10))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(10);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 11))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(11);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 12))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(12);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 13))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(13);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 14))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(14);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 15))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(15);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 16))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(16);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 17))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(17);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 18))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(18);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 19))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(19);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 20))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(20);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 21))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(21);}),
            m.root.createChild("path")
                    .setTranslation(400,7 + (20 * 22))
                    .horiz(180)
                    .vert(20)
                    .horiz(-180)
                    .close()
                    .setColor(1,1,1,1)
                    .addEventListener("click",func(){m.inner_click(22);}),
        ];

        m.selection_map = [m.p3opt, m.p1opt, m.copt, m.p2opt, m.p4opt, m.oblopt, m.obropt, m.cconopt];
        m.pylon_map = [   [m.p3,m.p3store],
                          [m.p1,m.p1store],
                          [m.pc,m.pcstore],
                          [m.p2,m.p2store],
                          [m.p4,m.p4store],
                          [m.obl,m.oblstore],
                          [m.obr,m.obrstore],
                          [m.ccon,m.cconstore],
                        ];
        m.pylon_click(0);
        return m;
    },
    get_canvas: func() {
        return me.stores_canvas;
    },
    # if you click on a new pylon (or this is the first runthrough):
    # run this with opt being the internal pylon number
    # if a new outer group is selected, update with both opt and out being the outer group name
    selections_update: func(opt = 0, out = -1) {
        me.selected = getprop("/payload/weight["~opt~"]/selected");
        if (out == -1) {
            me.outer_selected = me.find_payload_og(opt, me.selected);
        } else {
            me.outer_selected = out;
        }
        me.i = -1;
        foreach(var og; me.selection_map[opt]) {
            me.i = me.i + 1;
            me.outerselectiongroup[me.i].setText(og[0]);
            if(og[0] == me.selection_map[opt][me.outer_selected][0]) {
                me.outerselectiongroup[me.i].setColor(me.selected_color);
                me.j = -1;
                foreach(var ig; og[1]) {
                    me.j = me.j + 1;
                    me.innerselectiongroup[me.j].setText(ig);
                    if (ig == me.selected) {
                        me.innerselectiongroup[me.j].setColor(me.selected_color);
                    } else {
                        me.innerselectiongroup[me.j].setColor(me.font_color);
                    }
                }
            } else {
                me.outerselectiongroup[me.i].setColor(me.font_color);
            }
        }
        for (var i = me.i + 1; i < 23; i = i + 1) {
            me.outerselectiongroup[i].setText("");
        }
        for (var i = me.j + 1; i < 23; i = i + 1) {
            me.innerselectiongroup[i].setText("");
        }
    },

    pylon_click: func(pyl) {
        for(var i = 0; i < size(me.pylon_map); i = i + 1) {
            if (i == pyl) {
                me.pylon_map[i][0].setColor(me.selected_color);
                me.pylon_map[i][1].setColor(me.selected_color);
            } else {
                me.pylon_map[i][0].setColor(me.font_color);
                me.pylon_map[i][1].setColor(me.font_color);
            }
        }
        me.pylon_selected = pyl;
        me.selections_update(pyl);
        me.write_info(me.selected);
    },

    outer_click: func(out) {
        me.selected = getprop("/payload/weight["~me.pylon_selected~"]/selected");
        if (out >= size(me.selection_map[me.pylon_selected])) {
            return;
        }
        me.outer_selected = out;
        for (var i = 0; i < size(me.selection_map[me.pylon_selected]); i = i + 1 ) {
            if (i == out) {
                me.outerselectiongroup[i].setColor(me.selected_color);
            } else {
                me.outerselectiongroup[i].setColor(me.font_color);
            }
        }
        for (var i = 0; i < 23; i = i + 1) {
            me.innerselectiongroup[i].setText("");
        }
        for (var i = 0; i < size(me.selection_map[me.pylon_selected][out][1]); i = i + 1) {
            me.innerselectiongroup[i].setText(me.selection_map[me.pylon_selected][out][1][i]);
            if (me.selection_map[me.pylon_selected][out][1][i] == me.selected) {
                me.innerselectiongroup[i].setColor(me.selected_color);
            } else {
                me.innerselectiongroup[i].setColor(me.font_color);
            }
        }
        me.write_info(me.selected);
    },

    inner_click: func(ig) {
        if (ig >= size(me.selection_map[me.pylon_selected][me.outer_selected][1])) {
            return;
        }
        me.sel = me.selection_map[me.pylon_selected][me.outer_selected][1][ig];
        me.weight = payloads.payloads[me.sel].weight;
        setprop("/payload/weight["~me.pylon_selected~"]/selected",me.sel);
        setprop("/payload/weight["~me.pylon_selected~"]/weight-lb",me.weight);
        me.pylon_map[me.pylon_selected][1].setText(me.sel);
        me.write_info(me.sel);
        me.outer_click(me.outer_selected);
    },

    find_payload_og: func(opt, search) {
        for (var i = 0; i < size(me.selection_map[opt]);i = i + 1){
            for (var j = 0; j < size(me.selection_map[opt][i][1]); j = j + 1){
                if ( me.selection_map[opt][i][1][j] == search ) {
                    return i;
                }
            }
        }
    },

    write_info: func(name) {
        me.write_array = [];
        # clear out old info
        foreach(var info; keys(me.store_info)) {
            if (info == name) {
                me.write_array = me.store_info[info];
            }
        }
        me.infobox[0].setText(name);
        for(me.i = 0; me.i < size(me.write_array); me.i = me.i + 1){
            me.infobox[me.i+1].setText(me.write_array[me.i]);
        }
        for(me.i = me.i; me.i < size(me.infobox)-1; me.i = me.i + 1){
            me.infobox[me.i+1].setText("");
        }

    },
};
