var GLOBALS = {
    jsReady:false,
    flashReady:false
};

var MindWave = {
    mIcon:-1,
    mThinkingLevel:-1,
    mRelaxationLevel:-1,
    setIconValue:function(iconValue) {
	this.mIcon = iconValue;
	this.log("setIcon("+this.mIcon+")");
    },
    setThinkingLevel:function(thinkingLevel) {
	this.mThinkingLevel = thinkingLevel;
	this.log("setThinkingLevel("+this.mThinkingLevel+")");
    },
    setRelaxationLevel:function(relaxationLevel) {
	this.mRelaxationLevel = relaxationLevel;
	this.log("setRelaxationLevel("+this.mRelaxationLevel+")");
    },
    displayIcon:function() {
	this.log("getIcon("+this.mIcon+")");
	return this.mIcon >= 0 && this.mIcon < 200;
    },
    getThinkingLevel:function() {
	this.log("getThinkingLevel("+this.mThinkingLevel+")");
	var t = this.mThinkinLevel;
	if (t) return t;
	return 0;
    },
    getRelaxationLevel:function() {
	this.log("getRelaxationLevel("+this.mRelaxationLevel+")");
	var r = this.mRelaxationLevel;
	if (r) return r;
	return 0;
    },
    log:function(message) {
	console.log(message);
    }
};

function trace(text) {
    console.log(text);
}

function isReady() {
    return GLOBALS.jsReady;
}

$(document).ready(function() {
    GLOBALS.jsReady = true;
});
