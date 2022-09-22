import random
import time
import sys

def progres():
    """
        Prints the progress bar.
    """
    total = 100  # total number to reach
    bar_length = 30  # should be less than 100
    for i in range(total+1):
        percent = 100.0*i/total
        sys.stdout.write('\r')
        sys.stdout.write("Completed: [{:{}}] {:>3}%"
                         .format('='*int(percent/(100.0/bar_length)),
                                 bar_length, int(percent)))
        sys.stdout.flush()
        time.sleep(0.0005)
    print("\n")


def print_points(player_choice, pc_choice,player_name, player_points, pc_point,winner):
    print(30*"-"+"\n     Results    \nYou chose this: {}\nComputer chose this: {}\nScore: {} {} --- COMPUTER {}\n {} WON !!\n".format(
                    player_choice, pc_choice,player_name, player_points, pc_point,winner)+30*"-")

secenekler = ["Rock", "Paper", "Scissors", "Lizard", "Spock"]
app_on = True

while app_on == True:
    
    menu = int(input(
        "Rock-Paper-Scissors Game\n- Press 1 to start Game\n- Press 2 to read ınstructions\n- Press 3 to exit\n-->"))
    progres()
    if menu == 1:
        player_name = input("Write your name = ")
        game_on = True
        pc_point = 0
        player_points = 0
        while game_on:

            pc_choice = random.choice(secenekler)
            player_choice = input("Choose from (Rock Paper Scissors Lizard Spock) \n")
            
            if player_choice == "q":
                game_on = False
                print("Dr. Sheldon Cooper wishes you a good day.")

            elif (player_choice == pc_choice):
                player_points == +0
                print("It is a tie!")

            elif (player_choice == "Rock" and pc_choice == "Scissors") or (player_choice == "Rock" and pc_choice == "Lizard"):
                player_points += 1
                print_points(player_choice, pc_choice,player_name, player_points, pc_point,player_name)

            elif (player_choice == "Paper" and pc_choice == "Rock") or (player_choice == "Paper" and pc_choice == "Spock"):
                player_points += 1
                print_points(player_choice, pc_choice,player_name, player_points, pc_point,player_name)


            elif (player_choice == "Scissors" and pc_choice == "Paper") or (player_choice == "Scissors" and pc_choice == "Lizard"):
                player_points += 1
                print_points(player_choice, pc_choice,player_name, player_points, pc_point,player_name)


            elif (player_choice == "Lizard" and pc_choice == "Spock") or (player_choice == "Lizard" and pc_choice == "Paper"):
                player_points += 1
                print_points(player_choice, pc_choice,player_name, player_points, pc_point,player_name)


            elif (player_choice == "Spock" and pc_choice == "Scissors") or (player_choice == "Spock" and pc_choice == "Rock"):
                player_points += 1
                print_points(player_choice, pc_choice,player_name, player_points, pc_point,player_name)


            elif (pc_choice == "Rock" and player_choice == "Scissors") or (pc_choice == "Rock" and player_choice == "Lizard"):
                pc_point += 1
                print_points(player_choice, pc_choice,player_name, player_points, pc_point,"PC")


            elif (pc_choice == "Paper" and player_choice == "Rock") or (pc_choice == "Paper" and player_choice == "Spock"):
                pc_point += 1
                print_points(player_choice, pc_choice,player_name, player_points, pc_point,"PC")

            elif (pc_choice == "Scissors" and player_choice == "Paper") or (pc_choice == "Scissors" and player_choice == "Lizard"):
                pc_point += 1
                print_points(player_choice, pc_choice,player_name, player_points, pc_point,"PC")

            elif (pc_choice == "Lizard" and player_choice == "Spock") or (pc_choice == "Lizard" and player_choice == "Paper"):
                pc_point += 1
                print_points(player_choice, pc_choice,player_name, player_points, pc_point,"PC")

            elif (pc_choice == "Spock" and player_choice == "Scissors") or (pc_choice == "Spock" and player_choice == "Rock"):
                pc_point += 1
                print_points(player_choice, pc_choice,player_name, player_points, pc_point,"PC")

            else:
                print("Incorrect, please correct and write again.")

    elif menu == 2:
        print("What is this game? \n 'The game was originally created by Sam Kass with Karen Bryla.'\n The game is an expansion on the game Rock, Paper, Scissors. Each player picks a variable and reveals it at the same time. The winner is the one who defeats the others. In a tie, the process is repeated until a winner is found.\nScissors cuts Papers\nPaper covers Rock\nRock crushes Lizard\nLizard poisons Spock\nSpock smashes Scissors\nScissors decapitates Lizard\nLizard eats Paper\nPaper disproves Spock\nSpock vaporizes Rock\n(and as it always has) Rock crushes Scissors")

    elif menu == 3:
        app_on = False
    else:
        print("Wron command, try again.\n"+10*"-")
