"""-----------------ENCODE------------------"""


# Function Can Encode Char
def encodeChar(char):
    encode_char = ''
    index = -1
    for i in range(len_char_arr):
        if char_arr[i] == char:
            index = i + inc
            if index >= len_char_arr:
                index %= len_char_arr
            encode_char = char_arr[index]
            break
    if index != -1:
        return encode_char
    else:
        return char


if __name__ == "__main__":
    # Initialize Variables
    inc = 3
    char_arr = [chr(i) for i in range(256)]
    len_char_arr = len(char_arr)
    encoded_arr = []

    # Input
    decoded_text = input("Enter Text To Encode: ")

    for char in decoded_text:
        # Call Function -> Encode Char
        encoded_arr.append(encodeChar(char))

    # Print Encoded Text
    print(f'Encode Text: {"".join(encoded_arr)}')