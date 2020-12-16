var term;
var socket = io(location.origin, {path: '/wetty/socket.io'})
var buf = '';

function Wetty(argv) {
    this.argv_ = argv;
    this.io = null;
    this.pid_ = -1;
}

Wetty.prototype.run = function() {
    this.io = this.argv_.io.push();

    this.io.onVTKeystroke = this.sendString_.bind(this);
    this.io.sendString = this.sendString_.bind(this);
    this.io.onTerminalResize = this.onTerminalResize.bind(this);
}

Wetty.prototype.sendString_ = function(str) {
    socket.emit('input', str);
};

Wetty.prototype.onTerminalResize = function(col, row) {
    socket.emit('resize', { col: col, row: row });
};

socket.on('connect', function() {
    lib.init(function() {
        hterm.defaultStorage = new lib.Storage.Local();
        term = new hterm.Terminal();
        window.term = term;
        term.decorate(document.getElementById('terminal'));

        term.setCursorPosition(0, 0);
        term.setCursorVisible(true);
        term.prefs_.set('ctrl-c-copy', true);
        term.prefs_.set('ctrl-v-paste', true);
        term.prefs_.set('use-default-window-copy', true);

        term.runCommandClass(Wetty, document.location.hash.substr(1));
        socket.emit('resize', {
            col: term.screenSize.width,
            row: term.screenSize.height
        });

        if (buf && buf != '')
        {
            term.io.writeUTF16(buf);
            buf = '';
        }
        
        // // QM modification - send parent window notification, that ternminal is loaded
        // if (window.parent) {
        //     // response to parent window message - if user credentials are provided, log user in
        //     window.addEventListener("message", function(event) {
        //         // check origin without port and protocol
        //         var origin = event.origin.split(':');
        //         if (origin[1].replace('//', '') != 'quickmage.io') {
        //             return;
        //         }
                // if (event.data && event.data.user && event.data.pass && window.term) {
                    
                    if (term.getRowText(0).toLowerCase().indexOf('password') != -1) {
                        // predefined user, just enter password
                        term.io.sendString(event.data.pass + "\n"); // enter password to terminal
                        
                    } else if (term.getRowText(0).toLowerCase().indexOf('login') != -1) {
                        // enter username, wait for password prompt, enter password
                        
                        term.io.sendString("term" + "\n"); // enter username to terminal
                        
                        var counter = 0;
                        var timer = setInterval(function() {
                            var cancelLoop = false;
                            if (term.getRowText(1).toLowerCase().indexOf('password') != -1) {
                                term.io.sendString("term" + "\n"); // enter password to terminal
                                cancelLoop = true;
                            }
                            if (counter > 10 || cancelLoop) {
                                clearTimeout(timer);
                                timer = false;
                            }
                            counter++;
                        }, 500);
                    }
            //     }
            // });
            
            window.parent.postMessage('terminal_loaded', '*');
        //}
    });
});

socket.on('output', function(data) {
    if (!term) {
        buf += data;
        return;
    }
    term.io.writeUTF16(data);
});

socket.on('disconnect', function() {
    console.log("Socket.io connection closed");
});
