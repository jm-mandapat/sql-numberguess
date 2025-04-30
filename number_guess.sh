#!/bin/bash
# Script to run number guessing game

PSQL="psql -X --username=freecodecamp --dbname=number_guess -t --no-align -c"

# generate a random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))



GUESS_NUMBER()
{
  NUMBER_OF_GUESSES=0
  echo "Guess the secret number between 1 and 1000:"

  while true
  do
    read NUMBER

    # check if number
    if [[ ! $NUMBER =~ ^[0-9]+$ ]]
    then
      echo "That is not an integer, guess again:"
    else
      ((NUMBER_OF_GUESSES++))
      if [[ $NUMBER > $SECRET_NUMBER ]]
      then
        echo "It's lower than that, guess again:"
      elif [[ $NUMBER < $SECRET_NUMBER ]]
      then
        echo "It's higher than that, guess again:"
      else
        # guessed the number
        echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
        return 0
      fi
    fi
  done
}

RUN_GAME()
{
  # enter username
  echo "Enter your username:"
  read USERNAME

  # trim leading & trailing spaces from service name
  USERNAME=$(echo $USERNAME | sed -r 's/^ *| *$//g')

  while [[ -z $USERNAME ]]
  do
    echo "Enter your username:"
    read USERNAME
  done

  # search user id
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")

  if [[ -z $USER_ID ]]
  then
    # user not found
    echo "Welcome, $USERNAME! It looks like this is your first time here."

    GUESS_NUMBER
    if [[ $? == 0 ]]
    then
      # add user and get user id (extract only the first line from return query)
      USER_ID=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME') RETURNING user_id" | sed -n '1p')

      # add game for user
      INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES)")
    fi
  else
    # user found
    USER_INFO=$($PSQL "SELECT COUNT(*) AS games_played, MIN(number_of_guesses) AS best_game FROM users JOIN games USING(user_id) WHERE username='$USERNAME' GROUP BY user_id")
    IFS='|' read GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."

    GUESS_NUMBER
    if [[ $? == 0 ]]
    then
      # add game for user
      INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES)")
    fi
  fi
}



RUN_GAME
