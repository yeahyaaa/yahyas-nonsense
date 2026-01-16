# Fantasy Survivors

A 2.5D Vampire Survivors-like game set in a fantasy medieval world, built with Godot 4 for Android and iOS.

## Game Features

### Core Gameplay
- **Twin-stick controls**: Left joystick for movement, right joystick for aiming
- **Auto-attack weapons**: Weapons fire automatically toward aim direction
- **Level-up system**: Choose 1 of 3 upgrades when leveling up
- **Linear stages**: Designed levels with enemy waves leading to boss fights

### Character System
- **6 Hero Classes**: Knight, Mage, Archer, Cleric, Necromancer, Barbarian
- **Full Character Builder**: Customize race, body type, hair, armor, and colors
- **Cosmetic customization**: Appearance doesn't affect gameplay - class determines abilities

### Progression
- **Run-based gold**: Earn gold each run for permanent upgrades
- **Meta shop**: Purchase permanent stat bonuses with gold
- **Unlockable content**: New classes, cosmetics, and stages

### Chest System
- **Elite monsters**: Stronger enemies with golden glow
- **Chest drops**: Elites have chance to drop treasure chests
- **Luck stat**: Affects chest rewards (1-3 powerups based on luck)

## Stages

1. **Haunted Graveyard** (Undead) → Boss: Lich King
2. **Goblin Forest** (Monsters) → Boss: Troll Warlord
3. **Demon Rift** (Demons) → Boss: Arch Demon

## Weapons

| Weapon | Class | Type |
|--------|-------|------|
| Sword Slash | Knight | Melee arc |
| Magic Missile | Mage | Homing projectiles |
| Arrow Volley | Archer | Piercing arrows |
| Holy Smite | Cleric | AoE damage |
| Soul Drain | Necromancer | Lifesteal |
| Axe Throw | Barbarian | Boomerang |

## Project Structure

```
fantasy_survivors/
├── scenes/
│   ├── characters/     # Player scene
│   ├── enemies/        # Enemy scenes
│   ├── weapons/        # Weapon scenes
│   ├── pickups/        # XP, gold, chests
│   ├── ui/             # UI components
│   └── levels/         # Stage scenes
├── scripts/
│   ├── core/           # Game manager, stats, saving
│   ├── player/         # Player controller
│   ├── enemies/        # Enemy AI
│   ├── weapons/        # Weapon logic
│   ├── systems/        # Spawner, etc.
│   └── ui/             # UI controllers
├── assets/
│   ├── sprites/
│   ├── audio/
│   └── fonts/
└── resources/          # Data files
```

## Building for Mobile

### Android
1. Install Android export templates in Godot
2. Configure signing keys
3. Export via Project → Export → Android

### iOS
1. Install iOS export templates
2. Set up Xcode and provisioning profiles
3. Export via Project → Export → iOS

## License

This project is for educational purposes.
