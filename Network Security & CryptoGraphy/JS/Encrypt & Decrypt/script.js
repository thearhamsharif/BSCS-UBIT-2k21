const simpleInc = 3;
const simpleCharArr = Array.from({ length: 26 }, (_, i) => String.fromCharCode(97 + i));
const simpleLenCharArr = simpleCharArr.length;

function encodeCharSimple(char) {
    let encodeChar = '';
    let index = -1;
    for (let i = 0; i < simpleLenCharArr; i++) {
        if (simpleCharArr[i] === char) {
            index = i + simpleInc;
            if (index >= simpleLenCharArr) {
                index %= simpleLenCharArr;
            }
            encodeChar = simpleCharArr[index];
            break;
        }
    }
    if (index !== -1) {
        return encodeChar;
    } else {
        return char;
    }
}

function decodeCharSimple(char) {
    let decodeChar = '';
    let index = -1;
    for (let i = 0; i < simpleLenCharArr; i++) {
        if (simpleCharArr[i] === char) {
            index = i - simpleInc;
            if (index < 0) {
                index += simpleLenCharArr;
            }
            decodeChar = simpleCharArr[index];
            break;
        }
    }
    if (index !== -1) {
        return decodeChar;
    } else {
        return char;
    }
}

function encodeText() {
    let inputText = document.getElementById('inputText').value;
    let encodedText = '';
    for (let char of inputText) {
        encodedText += encodeCharSimple(char.toLowerCase());
    }
    document.getElementById('outputText').value = encodedText;
}

function decodeText() {
    let inputText = document.getElementById('inputText').value;
    let decodeText = '';
    for (let char of inputText) {
        decodeText += decodeCharSimple(char.toLowerCase());
    }
    document.getElementById('outputText').value = decodeText;
}