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
/* OTP ENCRYPTION */
const otpCharArr = Array.from({ length: 26 }, (_, i) => String.fromCharCode(97 + i));

// Function to generate a random OTP key of the same length as the message
const generateOtpKey = (length) => {
  const charset = otpCharArr.join("");
  let key = '';
  for (let i = 0; i < length; i++) {
    const randomIndex = Math.floor(Math.random() * charset.length);
    key += charset[randomIndex];
  }
  return key;
};

// Function to save OTP key to local storage
const saveOtpKeyToLocalStorage = (key) => {
  localStorage.setItem('otpKey', key);
};

// Function to retrieve OTP key from local storage
const getOtpKeyFromLocalStorage = () => {
  return localStorage.getItem('otpKey');
};

// Function to encrypt message using OTP
const encryptOtp = (message, key) => {
  let result = '';
  for (let i = 0; i < message.length; i++) {
    const char = message.charAt(i);
    if (otpCharArr.includes(char)) {
      const messageIndex = otpCharArr.indexOf(char);
      const keyIndex = otpCharArr.indexOf(key.charAt(i));
      const encryptedChar = otpCharArr[(messageIndex + keyIndex) % otpCharArr.length];
      result += encryptedChar;
    } else {
      result += char; // Non-alphabet characters remain unchanged
    }
  }
  return result;
};

// Function to decrypt message using OTP
const decryptOtp = (message, key) => {
  let result = '';
  for (let i = 0; i < message.length; i++) {
    const char = message.charAt(i);
    if (otpCharArr.includes(char)) {
      const messageIndex = otpCharArr.indexOf(char);
      const keyIndex = otpCharArr.indexOf(key.charAt(i));
      const decryptedChar = otpCharArr[(messageIndex - keyIndex + otpCharArr.length) % otpCharArr.length];
      result += decryptedChar;
    } else {
      result += char; // Non-alphabet characters remain unchanged
    }
  }
  return result;
};
/*-----------------------*/
/* RAIL FENCE ENCRYPTION */
// Encrypt using Rail Fence Cipher
function encryptRailFence(text, rails) {
  if (rails <= 1) return text;

  const fence = Array.from({ length: rails }, () => []);
  let rail = 0;
  let direction = 1; // 1 = down, -1 = up

  for (const element of text) {
    fence[rail].push(element);
    rail += direction;

    if (rail === 0 || rail === rails - 1) {
      direction *= -1;
    }
  }

  return fence.flat().join('');
}

// Decrypt using Rail Fence Cipher
function decryptRailFence(cipher, rails) {
  if (rails <= 1) return cipher;

  // Step 1: Create an empty matrix with placeholders
  const pattern = Array.from({ length: rails }, () => Array(cipher.length).fill(null));
  let rail = 0;
  let direction = 1;

  for (let col = 0; col < cipher.length; col++) {
    pattern[rail][col] = '*';
    rail += direction;

    if (rail === 0 || rail === rails - 1) {
      direction *= -1;
    }
  }

  // Step 2: Fill the pattern with actual characters
  let index = 0;
  for (let r = 0; r < rails; r++) {
    for (let c = 0; c < cipher.length; c++) {
      if (pattern[r][c] === '*' && index < cipher.length) {
        pattern[r][c] = cipher[index++];
      }
    }
  }

  // Step 3: Read the message by zigzag
  let result = '';
  rail = 0;
  direction = 1;

  for (let col = 0; col < cipher.length; col++) {
    result += pattern[rail][col];
    rail += direction;

    if (rail === 0 || rail === rails - 1) {
      direction *= -1;
    }
  }

  return result;
}
/*-----------------------*/
/* PlayFair ENCRYPTION */
const alphabetArr = Array.from({ length: 26 }, (_, i) => String.fromCharCode(65 + i))
  .filter(c => c !== 'J') // remove 'J'
  .join('');

// Generate random Playfair key (5x5 grid)
function generatePlayfairKey() {
  const shuffled = [...alphabetArr];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled.join('');
}

// Save key to localStorage
function savePlayfairKey(key) {
  localStorage.setItem('playfairKey', key);
}

// Get or generate key from localStorage
function getPlayfairKey() {
  let key = localStorage.getItem('playfairKey');
  if (!key) {
    key = generatePlayfairKey();
    savePlayfairKey(key);
  }
  return key;
}

// Create 5x5 key matrix from key
function createMatrix(key) {
  const matrix = [];
  for (let i = 0; i < 25; i += 5) {
    matrix.push(key.slice(i, i + 5).split(''));
  }
  return matrix;
}

// Find letter position in key matrix
function findPosition(matrix, letter) {
  for (let row = 0; row < 5; row++) {
    const col = matrix[row].indexOf(letter);
    if (col !== -1) return { row, col };
  }
  return null;
}

// Prepare text for Playfair cipher (remove non-letters, replace J with I, make pairs)
function prepareText(text) {
  text = text.toUpperCase().replace(/[^A-Z]/g, '').replace(/J/g, 'I');
  let result = '';
  for (let i = 0; i < text.length; i += 2) {
    let a = text[i];
    let b = text[i + 1] || 'X';
    if (a === b) {
      result += a + 'X';
      i--;
    } else {
      result += a + b;
    }
  }
  return result;
}

// Encrypt a pair of letters
function encryptPair(a, b, matrix) {
  const posA = findPosition(matrix, a);
  const posB = findPosition(matrix, b);
  if (posA.row === posB.row) {
    return matrix[posA.row][(posA.col + 1) % 5] + matrix[posB.row][(posB.col + 1) % 5];
  } else if (posA.col === posB.col) {
    return matrix[(posA.row + 1) % 5][posA.col] + matrix[(posB.row + 1) % 5][posB.col];
  } else {
    return matrix[posA.row][posB.col] + matrix[posB.row][posA.col];
  }
}

// Encrypt full message
function encryptPlayfair(message) {
  const key = getPlayfairKey();
  const matrix = createMatrix(key);
  const prepared = prepareText(message);
  let encrypted = '';
  for (let i = 0; i < prepared.length; i += 2) {
    encrypted += encryptPair(prepared[i], prepared[i + 1], matrix);
  }
  return encrypted;
}

// Decrypt a pair of letters
function decryptPair(a, b, matrix) {
  const posA = findPosition(matrix, a);
  const posB = findPosition(matrix, b);
  if (posA.row === posB.row) {
    return matrix[posA.row][(posA.col + 4) % 5] + matrix[posB.row][(posB.col + 4) % 5];
  } else if (posA.col === posB.col) {
    return matrix[(posA.row + 4) % 5][posA.col] + matrix[(posB.row + 4) % 5][posB.col];
  } else {
    return matrix[posA.row][posB.col] + matrix[posB.row][posA.col];
  }
}

// Decrypt full message
function decryptPlayfair(cipherText) {
  const key = getPlayfairKey();
  const matrix = createMatrix(key);
  let decrypted = '';
  for (let i = 0; i < cipherText.length; i += 2) {
    decrypted += decryptPair(cipherText[i], cipherText[i + 1], matrix);
  }
  return decrypted;
}
/*-----------------------*/
/* HILL ENCRYPTION */

// Define alphabet and modulus
const hillAlphabet = Array.from({ length: 26 }, (_, i) => String.fromCharCode(65 + i));
const hillMod = hillAlphabet.length; // for mod 26 arithmetic (A-Z)

// Convert a character to its index (A=0, B=1, ..., Z=25)
const hillCharToIndex = char => hillAlphabet.indexOf(char.toUpperCase());

// Convert an index to a character
const hillIndexToChar = index => {
  return hillAlphabet[(index + hillMod) % hillMod];
};

// Compute GCD (used for checking if determinant is invertible mod 26)
function hillGCD(a, b) {
  return b === 0 ? a : hillGCD(b, a % b);
}

// Compute modular inverse of a number mod m
function hillModInverse(a, m) {
  a = ((a % m) + m) % m;
  for (let x = 1; x < m; x++) {
    if ((a * x) % m === 1) return x;
  }
  return null;
}

// Generate a valid 2x2 key matrix and save to localStorage
function hillGenerateKeyMatrix() {
  let matrix, det;
  do {
    // Random 2x2 matrix
    matrix = [
      [Math.floor(Math.random() * 26), Math.floor(Math.random() * 26)],
      [Math.floor(Math.random() * 26), Math.floor(Math.random() * 26)]
    ];
    // Calculate determinant
    det = (matrix[0][0] * matrix[1][1] - matrix[0][1] * matrix[1][0]) % hillMod;
  } while (hillGCD(det, hillMod) !== 1); // Repeat if matrix not invertible

  // Save key to localStorage
  localStorage.setItem("hillKeyMatrix", JSON.stringify(matrix));
  return matrix;
}

// Get the key matrix from localStorage or generate one
function hillGetKeyMatrix() {
  return JSON.parse(localStorage.getItem("hillKeyMatrix")) || hillGenerateKeyMatrix();
}

// Invert a 2x2 matrix mod 26
function hillInvertMatrix(matrix) {
  const [[a, b], [c, d]] = matrix;
  const det = (a * d - b * c + hillMod) % hillMod;
  const invDet = hillModInverse(det, hillMod);
  if (invDet === null) throw new Error("Matrix not invertible");

  // Return inverse matrix mod 26
  return [
    [(d * invDet) % hillMod, (-b * invDet + hillMod) % hillMod],
    [(-c * invDet + hillMod) % hillMod, (a * invDet) % hillMod]
  ];
}

// Encrypt plaintext using Hill Cipher
function hillEncrypt(plaintext) {
  const matrix = hillGetKeyMatrix();
  plaintext = plaintext.replace(/[^A-Z]/g, ''); // Remove non-alphabetic characters

  // Ensure even length by padding with 'X'
  if (plaintext.length % 2 !== 0) plaintext += 'X';

  let result = "";
  for (let i = 0; i < plaintext.length; i += 2) {
    const p1 = hillCharToIndex(plaintext[i]);
    const p2 = hillCharToIndex(plaintext[i + 1]);
    // Matrix multiplication: C = K × P mod 26
    const c1 = (matrix[0][0] * p1 + matrix[0][1] * p2) % hillMod;
    const c2 = (matrix[1][0] * p1 + matrix[1][1] * p2) % hillMod;
    result += hillIndexToChar(c1) + hillIndexToChar(c2);
  }
  return result;
}

// Decrypt ciphertext using Hill Cipher
function hillDecrypt(ciphertext) {
  const matrix = hillGetKeyMatrix();
  const inverseMatrix = hillInvertMatrix(matrix);
  ciphertext = ciphertext.replace(/[^A-Z]/g, ''); // Remove non-alphabetic characters

  let result = "";
  for (let i = 0; i < ciphertext.length; i += 2) {
    const c1 = hillCharToIndex(ciphertext[i]);
    const c2 = hillCharToIndex(ciphertext[i + 1]);
    // Matrix multiplication: P = K⁻¹ × C mod 26
    const p1 = (inverseMatrix[0][0] * c1 + inverseMatrix[0][1] * c2) % hillMod;
    const p2 = (inverseMatrix[1][0] * c1 + inverseMatrix[1][1] * c2) % hillMod;
    result += hillIndexToChar(p1) + hillIndexToChar(p2);
  }

  // Remove padding 'X' if it's at the end
  return result.replace(/X$/, '');
}
/*-----------------------*/
/* TRANSPOSITION ENCRYPTION */
const TRANS_KEY_STORAGE = "transpositionKey"; // Key storage name in localStorage

// Generate a random key of given length (e.g., 6 unique A-Z characters)
function generateTranspositionKey(length = 6) {
  const chars = Array.from({ length: 26 }, (_, i) => String.fromCharCode(65 + i)).join('');
  let key = "";
  while (key.length < length) {
    const char = chars[Math.floor(Math.random() * chars.length)];
    if (!key.includes(char)) {
      key += char;
    }
  }
  return key;
}

// Save generated key to localStorage
function saveTranspositionKeyToLocalStorage(key) {
  localStorage.setItem(TRANS_KEY_STORAGE, key);
}

// Retrieve key from localStorage or generate one if not present
function getTranspositionKeyFromLocalStorage(length = 6) {
  let key = localStorage.getItem(TRANS_KEY_STORAGE);
  if (!key) {
    key = generateTranspositionKey(length);
    saveTranspositionKeyToLocalStorage(key);
  }
  return key;
}

// Get column order based on alphabetical sorting of key characters
function getTranspositionKeyOrder(key) {
  return key
    .split('')
    .map((char, index) => ({ char, index }))     // Keep original index
    .sort((a, b) => a.char.localeCompare(b.char)) // Sort alphabetically
    .map(obj => obj.index);                       // Extract sorted indexes
}

// === ENCRYPTION ===
function encryptTranspositionCipher(plaintext) {
  plaintext = plaintext.replace(/[^A-Z]/g, '');
  const key = getTranspositionKeyFromLocalStorage();
  const numCols = key.length;
  const keyOrder = getTranspositionKeyOrder(key);
  const numRows = Math.ceil(plaintext.length / numCols);

  // Fill matrix row by row
  const matrix = [];
  let index = 0;
  for (let r = 0; r < numRows; r++) {
    matrix[r] = [];
    for (let c = 0; c < numCols; c++) {
      matrix[r][c] = plaintext[index++] || 'X'; // Fill with 'X' if not enough chars
    }
  }

  // Read matrix column-wise in key order
  let ciphertext = '';
  for (const colIndex of keyOrder) {
    for (let r = 0; r < numRows; r++) {
      ciphertext += matrix[r][colIndex];
    }
  }

  return ciphertext;
}

// === DECRYPTION ===
function decryptTranspositionCipher(ciphertext) {
  ciphertext = ciphertext.replace(/[^A-Z]/g, '');
  const key = getTranspositionKeyFromLocalStorage();
  const numCols = key.length;
  const numRows = Math.ceil(ciphertext.length / numCols);
  const keyOrder = getTranspositionKeyOrder(key);

  // Determine how many full columns there are (some may be shorter)
  const totalChars = ciphertext.length;
  const shortCols = (numCols * numRows) - totalChars;

  // Determine how many characters in each column
  const colLengths = Array(numCols).fill(numRows);
  for (let i = numCols - shortCols; i < numCols; i++) {
    colLengths[keyOrder[i]] = numRows - 1;
  }

  // Fill the matrix column-wise
  const matrix = Array.from({ length: numRows }, () => []);
  let index = 0;
  for (let i = 0; i < numCols; i++) {
    const colIndex = keyOrder[i];
    const colLen = colLengths[colIndex];
    for (let r = 0; r < colLen; r++) {
      matrix[r][colIndex] = ciphertext[index++];
    }
  }

  // Read the matrix row-wise to reconstruct plaintext
  const plaintext = matrix.map(row => row.join('')).join('');
  return plaintext.replace(/X+$/g, ''); // Remove trailing 'X' padding
}
/*-----------------------*/

const encodeText = () => {
  let inputText = document.getElementById('inputText').value;
  let encodedText = '';
  let activeTabId = document.querySelector('.tab.active').id;
  if (activeTabId === 'otp') {
    const otpKey = generateOtpKey(inputText.length);
    saveOtpKeyToLocalStorage(otpKey);
    encodedText += encryptOtp(inputText.toLowerCase(), otpKey);
  } else if (activeTabId == 'railfence') {
    let rails = document.getElementById('rails').value;
    encodedText += encryptRailFence(inputText.toLowerCase(), rails);
  } else if (activeTabId == 'vigenere') {
    encodedText += encryptVigenereShifting(inputText.toLowerCase());
  } else if (activeTabId == 'playfair') {
    encodedText += encryptPlayfair(inputText.toUpperCase()).toLowerCase();
  } else if (activeTabId == 'hill') {
    encodedText += hillEncrypt(inputText.toUpperCase()).toLowerCase();
  } else if (activeTabId == 'transposition') {
    encodedText += encryptTranspositionCipher(inputText.toUpperCase()).toLowerCase();
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
  let decodedText = '';
  let activeTabId = document.querySelector('.tab.active').id;
  if (activeTabId === 'otp') {
    const otpKey = getOtpKeyFromLocalStorage();
    decodedText += decryptOtp(inputText.toLowerCase(), otpKey);
  } else if (activeTabId == 'railfence') {
    let rails = document.getElementById('rails').value;
    decodedText += decryptRailFence(inputText.toLowerCase(), rails);
  } else if (activeTabId == 'vigenere') {
    decodedText += decryptVigenereShifting(inputText.toLowerCase());
  } else if (activeTabId == 'playfair') {
    decodedText += decryptPlayfair(inputText.toUpperCase()).toLowerCase();
  } else if (activeTabId == 'hill') {
    decodedText += hillDecrypt(inputText.toUpperCase()).toLowerCase();
  } else if (activeTabId == 'transposition') {
    decodedText += decryptTranspositionCipher(inputText.toUpperCase()).toLowerCase();
  } else {
    for (let char of inputText) {
      if (activeTabId == 'simple') {
        decodedText += decodeCharSimple(char.toLowerCase());
      } else if (activeTabId == 'polyalphabetic') {
        decodedText += '';
      }
    }
  }
  document.getElementById('outputText').value = decodedText;
}

const switchTab = (e) => {
  let id = e.id;

  document.querySelectorAll('.hide').forEach(el => el.style.display = 'none');

  document.querySelectorAll('.tab.active').forEach(function (element) {
    element.classList.remove("active");
  });
  document.querySelectorAll('.tab#' + id).forEach(function (element) {
    element.classList.add("active");
  });

  let activeTabId = document.querySelector('.tab.active').id;
  document.querySelectorAll('.' + activeTabId).forEach(el => el.style.display = 'block');
}