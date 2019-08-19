
var radio_paper = {

    canvas_settings: {
        "name": "radiopaper",
        "size": [2048, 2048],
        "view": [2048, 2048],
        "mipmapping": 1
    },
    
    new: func(placement) {
        var m = {parents: [radio_paper]};
        m.paper = canvas.new(radio_paper.canvas_settings);
        m.paper.addPlacement(placement);

        m.paper.setColorBackground(0,0,0,0);

        m.fs = 65;
        m.dR = 0.1;
        m.dG = 0.1;
        m.dB = 0.1;

        m.start_x = 225;
        m.start_y = 150;
        m.x_delta = 230;
        m.y_delta = 93;

        m.notes = m.paper.createGroup();

        for (var i = 0; i < 20; i = i + 1) {
            m.notes.createChild("text")
                .setTranslation(65,m.start_y + (i * m.y_delta))
                .setAlignment("center-top")
                .setFont("helvetica_bold.txf")
                .setFontSize(m.fs)
                .setColor(m.dR,m.dG,m.dB)
                .setText(i+1);
        }

        m.vor_text = [];
        m.ils_text = [];
        m.comm_text = [];
        m.adf_text = [];

        for (var i = 0; i < 20; i = i + 1) {
            append(m.vor_text, m.notes.createChild("text")
                            .setTranslation(225,m.start_y + (i * m.y_delta))
                            .setAlignment("center-top")
                            .setFont("helvetica_bold.txf")
                            .setFontSize(m.fs)
                            .setColor(m.dR,m.dG,m.dB));
            append(m.ils_text, m.notes.createChild("text")
                            .setTranslation(225 + 230,m.start_y + (i * m.y_delta))
                            .setAlignment("center-top")
                            .setFont("helvetica_bold.txf")
                            .setFontSize(m.fs)
                            .setColor(m.dR,m.dG,m.dB));
            append(m.comm_text, m.notes.createChild("text")
                            .setTranslation(225 + 230 + 230,m.start_y + (i * m.y_delta))
                            .setAlignment("center-top")
                            .setFont("helvetica_bold.txf")
                            .setFontSize(m.fs)
                            .setColor(m.dR,m.dG,m.dB));
            if ( i > 8 )  { continue; }
            append(m.adf_text, m.notes.createChild("text")
                            .setTranslation(225 + 230 + 230 + 230,m.start_y + (i * m.y_delta))
                            .setAlignment("center-top")
                            .setFont("helvetica_bold.txf")
                            .setFontSize(m.fs)
                            .setColor(m.dR,m.dG,m.dB));
        }

        return m;
    },

    update_text: func() {

        for ( var i = 0; i < 20; i = i + 1 ) {
            me.vor_text[i].setText(getprop("/instrumentation/vor-radio/ident["~i~"]"));
            me.ils_text[i].setText(getprop("/instrumentation/ils-radio/ident["~i~"]"));
            me.comm_text[i].setText(getprop("/instrumentation/comm-radio/ident["~i~"]"));
            if ( i > 8 )  { continue; }
            me.adf_text[i].setText(getprop("/instrumentation/adf-radio/ident["~i~"]"));
        }
            #<path>/instrumentation/comm-radio/ident[15]</path>
            #<path>/instrumentation/adf-radio/ident[4]</path>
            #<path>/instrumentation/ils-radio/ident[11]</path>
            #<path>/instrumentation/vor-radio/ident[15]</path>
    }
};



var rp = 0;

var init = setlistener("/sim/signals/fdm-initialized", func() {
  removelistener(init); # only call once
  rp = radio_paper.new({"node": "paper_canvas"});
});