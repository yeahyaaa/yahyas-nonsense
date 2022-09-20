import random
secenekler = ["Rock", "Paper", "Scissors", "Lizard", "Spock"]
Welcome = print("What is this game? \n 'The game was originally created by Sam Kass with Karen Bryla.'\n The game is an expansion on the game Rock, Paper, Scissors. Each player picks a variable and reveals it at the same time. The winner is the one who defeats the others. In a tie, the process is repeated until a winner is found.\nScissors cuts Papers\nPaper covers Rock\nRock crushes Lizard\nLizard poisons Spock\nSpock smashes Scissors\nScissors decapitates Lizard\nLizard eats Paper\nPaper disproves Spock\nSpock vaporizes Rock\n(and as it always has) Rock crushes Scissors")
Kullanıcı_Adı = input("Nickname?")



game_on = True
pc_point = 0
player_point = 0
while game_on:
    pc_choice = random.choice(secenekler)
    player_choice = input(secenekler)
    if player_choice == "q":
        game_on = False 
        print("Dr. Sheldon Cooper wishes you a good day.")

    elif (player_choice == pc_choice):
        player_point == +0 
        pc_point == +0
        print("It is a tie!")
    
    elif (player_choice == "Rock" and pc_choice == "Scissors") or (player_choice == "Rock" and pc_choice == "Lizard"):
        player_point += 1
        pc_point += 0
        print("You chose this: {}\nComputer chose this: {}\nScore: YOU {} --- COMPUTER {}\n YOU WON !!".format(player_choice,pc_choice,player_point,pc_point))
    
    elif (player_choice == "Paper" and pc_choice == "Rock") or (player_choice == "Paper" and pc_choice == "Spock"):
        player_point += 1
        pc_point += 0
        print("You chose this: {}\nComputer chose this: {}\nScore: YOU {} --- COMPUTER {}\n YOU WON !!".format(player_choice,pc_choice,player_point,pc_point))
    
    elif (player_choice == "Scissors" and pc_choice == "Paper") or (player_choice == "Scissors" and pc_choice == "Lizard"):
        player_point += 1
        pc_point += 0
        print("You chose this: {}\nComputer chose this: {}\nScore: YOU {} --- COMPUTER {}\n YOU WON !!".format(player_choice,pc_choice,player_point,pc_point))

    elif (player_choice == "Lizard" and pc_choice == "Spock") or (player_choice == "Lizard" and pc_choice == "Paper"):
        player_point += 1
        pc_point += 0
        print("You chose this: {}\nComputer chose this: {}\nScore: YOU {} --- COMPUTER {}\n YOU WON !!".format(player_choice,pc_choice,player_point,pc_point))

    elif (player_choice == "Spock" and pc_choice == "Scissors") or (player_choice == "Spock" and pc_choice == "Rock"):
        player_point += 1
        pc_point += 0
        print("You chose this: {}\nComputer chose this: {}\nScore: YOU {} --- COMPUTER {}\n YOU WON !!".format(player_choice,pc_choice,player_point,pc_point))

    elif (pc_choice == "Rock" and player_choice == "Scissors") or (pc_choice == "Rock" and player_choice == "Lizard"):
        player_point += 0
        pc_point += 1
        print("You chose this: {}\nComputer chose this: {}\nScore: YOU {} --- COMPUTER {}\n YOU LOST !!".format(player_choice,pc_choice,player_point,pc_point))
    
    elif (pc_choice == "Paper" and player_choice == "Rock") or (pc_choice == "Paper" and player_choice == "Spock"):
        player_point += 0
        pc_point += 1
        print("You chose this: {}\nComputer chose this: {}\nScore: YOU {} --- COMPUTER {}\n YOU LOST !!".format(player_choice,pc_choice,player_point,pc_point))

    elif (pc_choice == "Scissors" and player_choice == "Paper") or (pc_choice == "Scissors" and player_choice == "Lizard"):
        player_point += 0
        pc_point += 1
        print("You chose this: {}\nComputer chose this: {}\nScore: YOU {} --- COMPUTER {}\n YOU LOST !!".format(player_choice,pc_choice,player_point,pc_point))

    elif (pc_choice == "Lizard" and player_choice == "Spock") or (pc_choice == "Lizard" and player_choice == "Paper"):
        player_point += 0
        pc_point += 1
        print("You chose this: {}\nComputer chose this: {}\nScore: YOU {} --- COMPUTER {}\n YOU LOST !!".format(player_choice,pc_choice,player_point,pc_point))

    elif (pc_choice == "Spock" and player_choice == "Scissors") or (pc_choice == "Spock" and player_choice == "Rock"):
        player_point += 0
        pc_point += 1
        print("You chose this: {}\nComputer chose this: {}\nScore: YOU {} --- COMPUTER {}\n YOU LOST !!".format(player_choice,pc_choice,player_point,pc_point))


    else: print("Incorrect, please correct and write again.")
