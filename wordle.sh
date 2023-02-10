#! /usr/bin/bash

# TODO comment actual world

# GET PC IN-BUILT DICTIONARY
PC_DICT_WORD=($(grep -E '^[a-zA-Z]{5,8}$' /usr/share/dict/words | tr '[A-Z]' '[a-z]'))


# Saving console passed params
ARGC=$#
WORDSIZE=$1

# COLORS
RED="\e[38;2;255;255;255;1m\e[48;2;220;20;60;1m"
GREEN="\e[38;2;255;255;255;1m\e[48;2;106;170;100;1m"
YELLOW="\e[38;2;255;255;255;1m\e[48;2;201;180;88;1m"
BLUE="\e[38;2;255;255;255;1m\e[48;2;0;0;255;1m"
ORANGE="\e[38;2;255;255;255;1m\e[48;2;255;165;0;1m"
PINK="\e[38;2;255;255;255;1m\e[48;2;255;192;203;1m"
PURPLE="\e[38;2;255;255;255;1m\e[48;2;128;0;128;1m"
CYAN="\e[38;2;255;255;255;1m\e[48;2;0;255;255;1m"
MAGENTA="\e[38;2;255;255;255;1m\e[48;2;255;0;255;1m"
GREY="\e[38;2;255;255;255;1m\e[48;2;128;128;128;1m"
CREAM="\e[38;2;255;253;208;1m\e[48;2;240;240;240;1m"
RESET="\e[0;39m"

# Numbers of words in each file
LISTSIZE=1000 

EXACT=2
CLOSE=1
WRONG=0


# Get Input from User and check if it's valid or not
# The Guess value is stored in global variable GUESSIMP
getGuess(){
    local wordSize=$1
    GUESSINP=""
    until [[ $GUESSINP =~ ^[a-zA-Z]{$wordSize}+$ ]] && [[ " ${PC_DICT_WORD[*]} " =~ " $GUESSINP " ]]
    do
        read -p "Input a $wordSize-letter word: " GUESSINP

        # Converting Guess word to all lowercase
        GUESSINP="$(echo $GUESSINP | tr '[:upper:]' '[:lower:]')" 
    done
}


# Calculate total score for each guess
# Output is stored in global var SCORE
calculateScore(){
    local wordSize=$1
    local -n stat=$2

    SCORE=0
    local i=0
    for ((;i<$wordSize;i++)){
        SCORE=$((SCORE+stat[$i]))
    }
}


# Print word accordingly in green yellow and rew
# for user to intrepret warning etc
printWord() {
    local guess=$1
    local wordSize=$2
    local -n sta=$3

    local i=0
    for ((;i<$wordSize;i++))
    do
        local ch=${sta[$i]}
        if [[ $ch == *"2"* ]]
        then
            printf "${GREEN}${guess:$i:1}"
        elif [[ $ch == *"1"* ]]
        then
            printf "${YELLOW}${guess:$i:1}"
        else
            printf "${RED}${guess:$i:1}"
        fi
    done
    printf "${RESET}\n"
}


# Generate Random by reading 5/6/7/8.txt
# Stores output in global RANDOMWORD
generateWord() {
    local wordSize=$1
    if [ -e "${wordSize}.txt" ]
    then
        local -a words=()
        local line=""
        while IFS='' read -r line || [[ -n "$line" ]]; do
            words+=("$line")
        done < "${wordSize}.txt"

        local random=$(($RANDOM%$LISTSIZE))
        RANDOMWORD=${words[$random]}
    else
        echo "File doesn't exists!"
        echo "Random Word can't be generated!"
        echo "Quitting :-)"
        exit 2
    fi
}

getStatus() {
    local wordSize=$1
    local choice=$2
    STATUS=()
    # Getting input from user via another function call
    getGuess "$wordSize"
    local guess=$GUESSINP
    
    # Initialising status with all Wrong
    local j=0
    for ((;j<$wordSize;j++))
    do 
        STATUS[$j]=$WRONG
    done

    # Checking if something is correct
    local js=0
    for ((js=0;js<$wordSize;js++))
    do 
        local ks=0
        for ((ks=0;ks<$wordSize;ks++))
        do 
            if [ $ks == $js ] && [ "${guess:$js:1}" =  "${choice:$ks:1}" ]
            then
                STATUS[$js]=$EXACT
                break
            elif [ "${guess:$js:1}" =  "${choice:$ks:1}" ]
            then
                STATUS[$js]=$CLOSE
            fi
        done
    done

}

statusCheck() {
    local wordSize=$1
    local guesses=$(($wordSize+1))

    # Generating random word
    generateWord "$wordSize"
    choice=$RANDOMWORD

    local -a status
    local is=0
    local WON=0

    local maxScore=$(($EXACT * $wordSize))
    local maxTotScore=$(($maxScore*$guesses))
    local TotalScore=$maxTotScore

    for ((is=0;is<$guesses;is++))
    do 
        # Get status codes array for indexed guess
        getStatus $wordSize $choice
        local -a status=("${STATUS[@]}")

        # Calculate score
        calculateScore $wordSize status
        local score=$SCORE
        TotalScore=$(($TotalScore-$maxScore+$score))
        printf "Guess $(($is+1)): "
        printWord $GUESSINP $wordSize status

        if [ $score -eq $(($EXACT*$wordSize)) ]
        then
            WON=1
            break
        fi
    done

    TotalScore=$((($TotalScore*100)/$maxTotScore))
    printf "\n\n${GREEN}                      RESULT                          "
    printf "${RESET}\n\n"
    if [ $WON -eq 0 ]
    then
        printf "${YELLOW}You lost, but there is always an another attempt, isn't it?${RESET}"
        printf "\n${GREEN}Correct Word: $choice${RESET}\n"
        printf "${RED}Score : ${TotalScore}${RESET}"
        printf "\n${RED}Thanks for Playing!${RESET}\n"
    else
        printf "${GREEN}You Won! Congrats!${RESET}\n"
        printf "${GREEN}Wanna go for higher levels?${RESET}\n"
        printf "${GREEN}Score : ${TotalScore}"
        printf "${RESET}\n"
    fi
}


# Displays the Welcome Message
welcomeMessage() {
    clear

    local wordsize=$1
    local guess=$(($wordsize+1))
    printf "${GREEN}                   This is WORDLE                         "
    printf "${RESET}\nThe Word Guessing Game\n\n\n"
    printf "${PURPLE}Instructions${RESET}\n"
    printf "${ORANGE}\n"
    echo "1. User has to guess a word in a limited no of attempt(s)"
    echo "2. Guessed word has to be valid dictionary word"
    echo "3. On invalid inputs, user might be asked again to input"
    echo "4. Each guess shows the result to actual word"
    echo "   Green shows correct letter and position"
    echo "   Yellow shows correct letter"
    echo "   Red shows incorrect letter"
    echo ""
    echo "BEST OF LUCK"
    printf "${RESET}\n\n"
    printf "${BLUE}You have %d tries to guess the %d-letter word I'm thinking of${RESET}\n" $guess $wordsize
    printf "\n\n${GREY}                     Game Starts                     ${RESET}\n"
    printf "${GREY}3.."
    sleep 1
    printf "2.."
    sleep 1
    printf "1.."
    sleep 1
    printf "\rLet's Play"
    sleep 1
    printf "${RESET}\r                     "
    printf "${RESET}\n\n"
}


# Credits to dev
credits(){
    printf "\n\n\n${GREY}                   CREDITS                         "
    printf "${RESET}\n\n"
    # Display the credits
    echo -e "${GREEN}Project Name: WORDLE${RESET}"
    printf "${BLUE}\n"
    echo -e "Developed by: KAMP IV"
    echo -e "Team Members:"
    echo -e "- rootCircle"
    echo -e "- N. Karthik Akshaj"
    echo -e "Thanks for using our project!"
    printf "${RESET}\n"

    # Pause before returning to the prompt
    read -p "Press [Enter] key to continue..."
}

# Call the required function for game to start in order
step_run() {
    generateWord "$WORDSIZE"
    welcomeMessage "$WORDSIZE"
    statusCheck $WORDSIZE
    sleep 5
    credits
}


# Checks for args passed with when running on console
useChecks() {
    local argc=$1
    local wordSize=$2
    if [ $argc -eq 1 ]
    then
        if [[ $wordSize =~ ^[5-8]{1}+$ ]]
        then
            step_run
        else
            echo "Error: WordSize must be either 5, 6, 7 or 8"
        fi
    else
        echo "Usage: ./wordle.sh wordsize"
    fi
}


# To start the check
start() {
    useChecks $ARGC $WORDSIZE
}

# Run the program
start
