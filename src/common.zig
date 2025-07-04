pub const term = struct {
    pub const blue =  "\x1b[94m";
    pub const red =   "\x1b[31m";
    pub const green = "\x1b[32m";
    pub const grey =  "\x1b[90m";

    pub const red2 =  "\x1b[38;5;215m";
    pub const blue2 = "\x1b[38;5;117m";

    pub const reset = "\x1b[0m";
    pub const clear = "\x1b[3J\x1b[2J\x1b[H";
};
