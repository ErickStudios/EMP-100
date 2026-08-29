function tokenize(code) {
    const tokens = [];
    let i = 0;
    const isLetter = (c) => /[a-zA-Z_]/.test(c);
    const isNumber = (c) => /[0-9]/.test(c);
    while (i < code.length) {
        let c = code[i];
        if (/\s/.test(c)) {
            i++;
            continue;
        }
        if (c === "/" && code[i + 1] === "/") {
            while (i < code.length && code[i] !== "\n") {
                i++;
            }
            continue;
        }
        if (c === "'") {
            let quoteType = c;
            let value = "";
            i++;
            while (i < code.length && code[i] !== quoteType) {
                value += code[i++];
            }
            i++;
            for (let a = 0; a < value.length; a++) {
                tokens.push({ type: "number", value: value.charCodeAt(a) });
                if (a !== (value.length - 1)) {
                    tokens.push({ type: "symbol", value: ',' });
                }
            }
            continue;
        }
        if (isLetter(c)) {
            let value = "";
            while (i < code.length && (isLetter(code[i]) || isNumber(code[i]))) {
                value += code[i++];
            }
            tokens.push({ type: "identifier", value });
            continue;
        }
        if (isNumber(c)) {
            let value = "";

            while (
                i < code.length &&
                (
                    isNumber(code[i]) ||
                    "ABCDEFabcdef".includes(code[i])
                )
            ) {
                value += code[i++];
            }

            if (
                i < code.length &&
                code[i].toLowerCase() === "h"
            ) {
                i++;
                value = parseInt(value, 16);
            }
            else if (value === "0" && code[i] === "x") {
                i++;
                let value2 = "";
                while (i < code.length && (isNumber(code[i]) || ['A', 'B', 'C', 'D', 'E', 'F'].includes(code[i].toUpperCase()))) {
                    value2 += code[i++];
                }
                value = parseInt(value2, 16);
            }
            else {
                value = Number(value);
            }

            tokens.push({
                type: "number",
                value
            });

            continue;
        }
        tokens.push({ type: "symbol", value: c });
        i++;
    }
    return tokens;
}
export class Context {
    constructor() {
        this.symbs = new Map();
        this.equals = new Map();
        this.codeLen = 0;
        this.currentIp = 0;
        this.currentLabel = 'start';
        this.result = [];
        this.list = {};
        this.org = 0;
    }
}
export function LineAsm(line, context) {
    let toks = tokenize(line);
    let i = 0;
    function peek() {
        return toks[i];
    }
    function consume() {
        return toks[i++];
    }
    function expect(x, msg) {
        let a = consume();
        if (a.value != x) {
            throw new Error(msg);
        }
        return a;
    }
    function getRegOf(name) {
        return ({
            A: 0,
            B: 1,
            C: 2,
            P: 3,
            X: 4,
            Y: 5
        })[name.toUpperCase()];
    }
    function getFlagOf(name) {
        return ({
            C: 0,
        })[name.toUpperCase()];
    }
    function getOpcodeOf(name) {
        let nam = name.toUpperCase();
        if (nam.startsWith('CP') && nam.length == 3) {
            return [0x01, [0x00 | getRegOf(nam[2])]];
        }
        if (nam == 'TSA') {
            return [0x00, [0x0, 'r']];
        }
        if (nam == 'MVA') {
            return [0x00, [0x1, 'r']];
        }
        if (nam == 'ADC') {
            return [0x03, [0x0, 'r']];
        }
        if (nam == 'SBB') {
            return [0x03, [0x1, 'r']];
        }
        if (nam == 'PAG') {
            return [0x04, 'n'];
        }
        if (nam == 'STA') {
            return [0x05, [0x00, 'r']];
        }
        if (nam == 'CTA') {
            return [0x0a, 'n'];
        }
        if (nam.startsWith('ZR') && nam.length == 3) {
            return [0x02, 0x00 | getFlagOf(nam[2])];
        }
        if (nam.startsWith('ST') && nam.length == 3) {
            return [0x02, 0x10 | getFlagOf(nam[2])];
        }
        if (nam == 'CHA') {
            return [0x06, 'n'];
        }
        if (nam == 'CHB') {
            return [0x09, 'n'];
        }
        if (nam == 'CHC') {
            return [0x0D, 'n'];
        }
        if (nam == 'LDA') {
            return [0x05, [0x1, 'r']];
        }
        if (nam == 'CDA') {
            return [0x0c, 'n'];
        }
        if (nam == 'LDC') {
            return [0x07, 'n'];
        }
        if (nam == 'BCC') {
            return [0x0b, 'n'];
        }
        if (nam == 'BRC') {
            return [0x08, [0x0, 'r']];
        }
        return null;
    }
    function toBigEndianBytes(n, x) {
        let bytes = [];
        while (n > 0) {
            bytes.push(n & 0xFF);
            n = n >>> 8;
        }
        bytes.reverse();
        while (bytes.length < x) {
            bytes.unshift(0);
        }
        return bytes;
    }
    function parseStructured(str, bd=8) {
        return str.map(v => {
            if (Array.isArray(v)) {
                let bs = parseStructured(v,bd/2);
                let ata = 0;
                bs.forEach(c => {
                    ata = (ata << (bd/2)) | Number(c);
                })
                return ata;
            }
            else if (v == 'n') {
                expect("$", 'expected number');
                if (peek().type != 'number') {
                    let inf = {};
                    let na = parseSyntx(inf);
                    if (inf.label) na += context.org;
                    if (peek() && peek().value == '.') {
                        consume();
                        let pat = consume().value.toUpperCase();
                        if (pat == 'H') {
                            return (na >> 8) & 0xFF;
                        }
                        else if (pat == 'L') {
                            return na & 0xFF;
                        }
                    }
                    return na;
                }
                return Number(consume().value);
            }
            else if (v == 'r') {
                expect("%", 'expected register');
                return Number(getRegOf(consume().value));
            }
            return Number(v);
        })
    }
    function parseSize(name) {
        switch (name) {
        case 'db': return 1;
        case 'dw': return 2;
        case 'dd': return 4;
        case 'dq': return 8;
        case 'byte': return 1;
        case 'word': return 2;

        }
    }
    function parseSyntx(info={}) {
        info.label = false;
        if (peek().value == '(') {
            consume();
            let result = parseSyntx();
            while (peek() && peek().value != ')') {
                if (peek().value !== ')') {
                    let xc = consume().value;
                    if (xc == '+') result = result + parseSyntx();
                    else if (xc == '-') result = result - parseSyntx();
                    else if (xc == '*') result = result * parseSyntx();
                    else if (xc == '/') result = result / parseSyntx();
                }
            }
            consume();
            return result;
        }
        if (peek().value == '.') {
            consume();
            info.label = true;
            return context.symbs.get(context.currentLabel + '.' + consume().value);
        }
        if (context.equals.has(peek().value)) {
            return context.equals.get(consume().value);
        }
        if (peek().value == '$') {
            consume();
            info.label = true;
            return context.currentIp;
        }
        if (peek().value == 'offs8') {
            consume();
            let syn = parseSyntx();
            syn = syn - context.currentIp;
            if (syn < 0) {
                syn = 0x80 | (-syn);
            }
            return syn & 0xFF;
        }
        if (context.symbs.has(peek().value)) {
            info.label = true;
            return context.symbs.get(consume().value);
        }
        if (peek().type !== 'number') {
            consume();
            return 0;
        }
        return consume().value;
    }
    let result = [];
    while (i < toks.length) {
        if (getOpcodeOf(peek().value) !== null) {
            let opr = getOpcodeOf(consume().value);
            let pr = parseStructured(opr);
            result.push(...pr);
        }
        else if (peek().value == ';') return result;
        else if (parseSize(peek().value) !== undefined) {
            let sizeof = parseSize(consume().value);
            let primarys = toBigEndianBytes(parseSyntx(), sizeof);
            while (peek() && peek().value === ",") {
            consume();
            primarys.push(...toBigEndianBytes(
                parseSyntx(), sizeof
            ));
            }
            result.push(...primarys);
        }
        else if (peek().value.toUpperCase() === 'LOCAL') {
            consume();
            context.org = parseSyntx();
        }
        else if (peek().value.toUpperCase() == 'RESERVE') {
            consume();
            let sx = parseSyntx();
            result.push(...(new Array(sx).fill(0)));
        }
        else if (peek().type == 'identifier') {
            let ident = consume().value;
            if (peek().value.toUpperCase() == 'EQU') {
                consume();
                context.equals.set(ident, parseSyntx())
            }
            else {
                expect(":");
                context.currentLabel = ident
                context.symbs.set(ident, context.currentIp)
            }
        }
        else {
            consume();
        }
    }
    return result;
}
export function parseAsm(code) {
    let ctx = new Context();
    let lines = code.split("\n");
    lines.forEach(line => {
        let instr = LineAsm(line, ctx);
        ctx.currentIp += instr.length;
    });
    ctx.currentIp = 0;
    lines.forEach(line => {
        let instr = LineAsm(line, ctx);
        ctx.result.push(...instr);
        if (!ctx.list[ctx.currentIp]) ctx.list[ctx.currentIp] = [];
        ctx.list[ctx.currentIp].push({instr, line});
        ctx.currentIp += instr.length;
    })
    return ctx;
}