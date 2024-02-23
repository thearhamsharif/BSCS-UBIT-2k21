"""-----------------DECODE------------------"""


# Function to Decode Char
def decodeChar(char):
    decode_char = ''
    index = -1
    for i in range(len_char_arr):
        if char_arr[i] == char:
            index = i - inc
            if index < 0:
                index += len_char_arr
            decode_char = char_arr[index]
            break
    if index != -1:
        return decode_char
    else:
        return char


if __name__ == "__main__":
    # Initialize Variables
    inc = 3
    char_arr = [chr(i) for i in range(256)]
    len_char_arr = len(char_arr)
    decoded_arr = []

    # Input
    encoded_text = input("Enter Text To Decode: ")

    for char in encoded_text:
        # Call Function -> Decode Char
        decoded_arr.append(decodeChar(char))

    # Print Decoded Text
    print(f'Decoded Text: {"".join(decoded_arr)}')