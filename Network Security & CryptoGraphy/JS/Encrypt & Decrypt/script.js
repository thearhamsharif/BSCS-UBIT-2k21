/*SIMPLE SHIFTING*/
const simpleInc = 3;
const simpleCharArr = Array.from({ length: 26 }, (_, i) => String.fromCharCode(97 + i));
const simpleLenCharArr = simpleCharArr.length;

const encodeCharSimple = (char) => {
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

const decodeCharSimple = (char) => {
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
/*-----------------------*/
/*VIGENERE SHIFTING*/
// Function to generate a random Vigenère key of given length
const vigenereCharArr = Array.from({ length: 26 }, (_, i) => String.fromCharCode(97 + i));
function generateVigenereRandomKey(length) {
    const charset = vigenereCharArr.join("");
    let key = '';
    for (let i = 0; i < length; i++) {
        const randomIndex = Math.floor(Math.random() * charset.length);
        key += charset[randomIndex];
    }
    return key;
}

// Function to generate the Vigenère character array based on the key
// Function to generate the Vigenère character array based on the key
function generateVigenereCharArr(key) {
    const charArr = [];
    for (let i = 0; i < key.length; i++) {
        const shift = key.charCodeAt(i) - 97; // Get the shift amount for each character in the key
        const shiftedChars = vigenereCharArr.slice(shift).concat(vigenereCharArr.slice(0, shift));
        charArr.push(shiftedChars);
    }
    return charArr;
}

// Function to save Vigenère key and character array to local storage
function saveVigenereToLocalStorage(key, charArr) {
    localStorage.setItem('vigenereKey', key);
    localStorage.setItem('vigenereCharArr', JSON.stringify(charArr));
}

// Function to retrieve Vigenère key and character array from local storage
function getVigenereFromLocalStorage() {
    const key = localStorage.getItem('vigenereKey');
    const charArr = JSON.parse(localStorage.getItem('vigenereCharArr'));
    return { key, charArr };
}

// Generate random key and character array
const randomKey = generateVigenereRandomKey(6); // Change the length as needed
const randomCharArr = generateVigenereCharArr(randomKey);

// Save them to local storage
saveVigenereToLocalStorage(randomKey, randomCharArr);

// Function to encrypt message using Vigenère shifting
function encryptVigenereShifting(message) {
    const { key, charArr } = getVigenereFromLocalStorage();

    let result = '';

    for (let i = 0, j = 0; i < message.length; i++) {
        const c = message.charAt(i);
        const index = vigenereCharArr.indexOf(c);
        if (index !== -1) {
            result += charArr[j % key.length][index];
            j++;
        } else {
            result += c;
        }
    }
    return result;
}

// Function to decrypt message using Vigenère shifting
function decryptVigenereShifting(message) {
    const { key, charArr } = getVigenereFromLocalStorage();

    let result = '';

    for (let i = 0, j = 0; i < message.length; i++) {
        const c = message.charAt(i);
        const rowIndex = j % key.length;
        const charIndex = charArr[rowIndex].indexOf(c);
        if (charIndex !== -1) {
            result += vigenereCharArr[charIndex];
            j++;
        } else {
            result += c;
        }
    }
    return result;
}
/*-----------------------*/

const encodeText = () => {
    let inputText = document.getElementById('inputText').value;
    let encodedText = '';
    let activeTabId = document.querySelector('.tab.active').id;
    if (activeTabId == 'vigenere') {
        encodedText += encryptVigenereShifting(inputText.toLowerCase());
    } else {
        for (let char of inputText) {
            if (activeTabId == 'simple') {
                encodedText += encodeCharSimple(char.toLowerCase());
            } else if (activeTabId == 'polyalphabetic') {
                encodedText += '';
            }
        }
    }
    document.getElementById('outputText').value = encodedText;
}

const decodeText = () => {
    let inputText = document.getElementById('inputText').value;
    let decodeText = '';
    let activeTabId = document.querySelector('.tab.active').id;
    if (activeTabId == 'vigenere') {
        decodeText += decryptVigenereShifting(inputText.toLowerCase());
    } else {
        for (let char of inputText) {
            if (activeTabId == 'simple') {
                decodeText += decodeCharSimple(char.toLowerCase());
            } else if (activeTabId == 'polyalphabetic') {
                decodeText += '';
            }
        }
    }
    document.getElementById('outputText').value = decodeText;
}

const switchTab = (e) => {
    let id = e.id;
    document.querySelectorAll('.tab.active').forEach(function (element) {
        element.classList.remove("active");
    });
    document.querySelectorAll('.tab#' + id).forEach(function (element) {
        element.classList.add("active");
    });
}