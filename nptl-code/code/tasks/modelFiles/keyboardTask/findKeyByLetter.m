function whichkey = findKeyByLetter(keys,letter)
    whichkey = uint16(0);
    for nkey = 1:keys.numKeys(1)
        if uint8(keys.text(nkey)) == uint8(letter)
            whichkey = uint16(keys.ID(nkey));
            break;
        end
    end
    